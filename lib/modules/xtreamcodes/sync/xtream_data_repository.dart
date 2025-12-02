// XtreamDataRepository
// Repository providing unified access to Xtream Codes data.
// Implements "local first" strategy with automatic sync when needed.

import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../epg/epg_models.dart';
import '../epg/epg_service.dart';
import '../storage/xtream_hive_models.dart';
import '../storage/xtream_local_storage.dart';
import '../sync/xtream_sync_service.dart';
import '../xtream_codes_client.dart';

/// Xtream data repository providing unified access to all content.
///
/// This repository implements a "local first" strategy:
/// 1. Always return data from local storage first for fast UI
/// 2. Check if data needs refresh based on TTL
/// 3. Fetch from API in background if needed and update local storage
/// 4. Return cached data on API failure (graceful degradation)
class XtreamDataRepository {
  final XtreamCodesClient _client;
  final XtreamLocalStorage _storage;
  final XtreamSyncService _syncService;

  XtreamDataRepository({
    required XtreamCodesClient client,
    required XtreamLocalStorage storage,
    required XtreamSyncService syncService,
  })  : _client = client,
        _storage = storage,
        _syncService = syncService;

  /// Get sync service for progress tracking
  XtreamSyncService get syncService => _syncService;

  /// Get storage for direct access
  XtreamLocalStorage get storage => _storage;

  // ============ Initialization ============

  /// Initialize the repository
  Future<void> initialize() async {
    await _storage.initialize();
  }

  /// Check if initial sync is needed
  bool needsInitialSync(String profileId) {
    return _syncService.needsInitialSync(profileId);
  }

  /// Perform initial sync if needed
  Future<SyncStats?> ensureInitialSync(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    if (needsInitialSync(profileId)) {
      return await _syncService.performInitialSync(profileId, credentials);
    }
    return null;
  }

  // ============ Live TV ============

  /// Get live TV categories (local first)
  Future<ApiResult<List<DomainCategory>>> getLiveCategories(
    String profileId,
    XtreamCredentialsModel credentials, {
    bool forceRefresh = false,
  }) async {
    try {
      // Get from local storage first
      var categories = _storage.getLiveCategories(profileId);

      // Check if we need to refresh
      final syncStatus = _storage.getSyncStatus(profileId);
      final needsRefresh = forceRefresh ||
          syncStatus == null ||
          syncStatus.needsChannelRefresh(const Duration(hours: 1));

      if (categories.isNotEmpty && !forceRefresh) {
        // Return cached data immediately
        if (needsRefresh) {
          // Trigger background refresh
          _refreshLiveCategoriesInBackground(profileId, credentials);
        }
        return ApiResult.success(categories);
      }

      // If no cached data or force refresh, fetch from API
      if (categories.isEmpty || forceRefresh) {
        final result = await _client.getLiveTvCategories(credentials);
        if (result.isSuccess) {
          await _storage.saveLiveCategories(profileId, result.data);
          return result;
        } else if (categories.isNotEmpty) {
          // Return cached on failure
          moduleLogger.warning(
            'API failed, returning cached categories',
            tag: 'DataRepo',
          );
          return ApiResult.success(categories);
        }
        return result;
      }

      return ApiResult.success(categories);
    } catch (e) {
      // Return cached data on error
      final categories = _storage.getLiveCategories(profileId);
      if (categories.isNotEmpty) {
        return ApiResult.success(categories);
      }
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get live TV channels (local first)
  Future<ApiResult<List<DomainChannel>>> getLiveChannels(
    String profileId,
    XtreamCredentialsModel credentials, {
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    try {
      // Get from local storage first
      var channels = _storage.getChannels(profileId, categoryId: categoryId);

      // Check if we need to refresh
      final syncStatus = _storage.getSyncStatus(profileId);
      final needsRefresh = forceRefresh ||
          syncStatus == null ||
          syncStatus.needsChannelRefresh(const Duration(hours: 1));

      if (channels.isNotEmpty && !forceRefresh) {
        if (needsRefresh) {
          // Trigger background refresh
          _refreshChannelsInBackground(profileId, credentials);
        }
        return ApiResult.success(channels);
      }

      // If no cached data or force refresh, fetch from API
      if (channels.isEmpty || forceRefresh) {
        final result = await _client.getLiveTvChannels(
          credentials,
          categoryId: categoryId,
        );
        if (result.isSuccess) {
          // Only save all channels, not filtered results
          if (categoryId == null) {
            await _storage.saveChannels(profileId, result.data);
            final status = _storage.getOrCreateSyncStatus(profileId);
            status.updateChannelSync(result.data.length);
            await _storage.saveSyncStatus(status);
          }
          return result;
        } else if (channels.isNotEmpty) {
          moduleLogger.warning(
            'API failed, returning cached channels',
            tag: 'DataRepo',
          );
          return ApiResult.success(channels);
        }
        return result;
      }

      return ApiResult.success(channels);
    } catch (e) {
      final channels = _storage.getChannels(profileId, categoryId: categoryId);
      if (channels.isNotEmpty) {
        return ApiResult.success(channels);
      }
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get live stream URL
  String getLiveStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String format = 'm3u8',
  }) {
    return _client.getLiveStreamUrl(credentials, streamId, format: format);
  }

  // ============ Movies ============

  /// Get movie categories (local first)
  Future<ApiResult<List<DomainCategory>>> getMovieCategories(
    String profileId,
    XtreamCredentialsModel credentials, {
    bool forceRefresh = false,
  }) async {
    try {
      var categories = _storage.getMovieCategories(profileId);

      final syncStatus = _storage.getSyncStatus(profileId);
      final needsRefresh = forceRefresh ||
          syncStatus == null ||
          syncStatus.needsMovieRefresh(const Duration(hours: 4));

      if (categories.isNotEmpty && !forceRefresh) {
        if (needsRefresh) {
          _refreshMovieCategoriesInBackground(profileId, credentials);
        }
        return ApiResult.success(categories);
      }

      if (categories.isEmpty || forceRefresh) {
        final result = await _client.getMovieCategories(credentials);
        if (result.isSuccess) {
          await _storage.saveMovieCategories(profileId, result.data);
          return result;
        } else if (categories.isNotEmpty) {
          return ApiResult.success(categories);
        }
        return result;
      }

      return ApiResult.success(categories);
    } catch (e) {
      final categories = _storage.getMovieCategories(profileId);
      if (categories.isNotEmpty) {
        return ApiResult.success(categories);
      }
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get movies (local first)
  Future<ApiResult<List<VodItem>>> getMovies(
    String profileId,
    XtreamCredentialsModel credentials, {
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    try {
      var movies = _storage.getMovies(profileId, categoryId: categoryId);

      final syncStatus = _storage.getSyncStatus(profileId);
      final needsRefresh = forceRefresh ||
          syncStatus == null ||
          syncStatus.needsMovieRefresh(const Duration(hours: 4));

      if (movies.isNotEmpty && !forceRefresh) {
        if (needsRefresh) {
          _refreshMoviesInBackground(profileId, credentials);
        }
        return ApiResult.success(movies);
      }

      if (movies.isEmpty || forceRefresh) {
        final result = await _client.getMovies(
          credentials,
          categoryId: categoryId,
        );
        if (result.isSuccess) {
          if (categoryId == null) {
            await _storage.saveMovies(profileId, result.data);
            final status = _storage.getOrCreateSyncStatus(profileId);
            status.updateMovieSync(result.data.length);
            await _storage.saveSyncStatus(status);
          }
          return result;
        } else if (movies.isNotEmpty) {
          return ApiResult.success(movies);
        }
        return result;
      }

      return ApiResult.success(movies);
    } catch (e) {
      final movies = _storage.getMovies(profileId, categoryId: categoryId);
      if (movies.isNotEmpty) {
        return ApiResult.success(movies);
      }
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get movie details
  Future<ApiResult<VodItem>> getMovieDetails(
    String profileId,
    XtreamCredentialsModel credentials,
    String movieId,
  ) async {
    try {
      // Check local first
      final localMovie = _storage.getMovieById(profileId, movieId);
      if (localMovie != null && localMovie.description != null) {
        return ApiResult.success(localMovie);
      }

      // Fetch from API
      final result = await _client.getMovieDetails(credentials, movieId);
      return result;
    } catch (e) {
      final localMovie = _storage.getMovieById(profileId, movieId);
      if (localMovie != null) {
        return ApiResult.success(localMovie);
      }
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get movie stream URL
  String getMovieStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String extension = 'mp4',
  }) {
    return _client.getMovieStreamUrl(credentials, streamId, extension: extension);
  }

  // ============ Series ============

  /// Get series categories (local first)
  Future<ApiResult<List<DomainCategory>>> getSeriesCategories(
    String profileId,
    XtreamCredentialsModel credentials, {
    bool forceRefresh = false,
  }) async {
    try {
      var categories = _storage.getSeriesCategories(profileId);

      final syncStatus = _storage.getSyncStatus(profileId);
      final needsRefresh = forceRefresh ||
          syncStatus == null ||
          syncStatus.needsSeriesRefresh(const Duration(hours: 4));

      if (categories.isNotEmpty && !forceRefresh) {
        if (needsRefresh) {
          _refreshSeriesCategoriesInBackground(profileId, credentials);
        }
        return ApiResult.success(categories);
      }

      if (categories.isEmpty || forceRefresh) {
        final result = await _client.getSeriesCategories(credentials);
        if (result.isSuccess) {
          await _storage.saveSeriesCategories(profileId, result.data);
          return result;
        } else if (categories.isNotEmpty) {
          return ApiResult.success(categories);
        }
        return result;
      }

      return ApiResult.success(categories);
    } catch (e) {
      final categories = _storage.getSeriesCategories(profileId);
      if (categories.isNotEmpty) {
        return ApiResult.success(categories);
      }
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get series (local first)
  Future<ApiResult<List<DomainSeries>>> getSeries(
    String profileId,
    XtreamCredentialsModel credentials, {
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    try {
      var series = _storage.getSeries(profileId, categoryId: categoryId);

      final syncStatus = _storage.getSyncStatus(profileId);
      final needsRefresh = forceRefresh ||
          syncStatus == null ||
          syncStatus.needsSeriesRefresh(const Duration(hours: 4));

      if (series.isNotEmpty && !forceRefresh) {
        if (needsRefresh) {
          _refreshSeriesInBackground(profileId, credentials);
        }
        return ApiResult.success(series);
      }

      if (series.isEmpty || forceRefresh) {
        final result = await _client.getSeries(
          credentials,
          categoryId: categoryId,
        );
        if (result.isSuccess) {
          if (categoryId == null) {
            await _storage.saveSeries(profileId, result.data);
            final status = _storage.getOrCreateSyncStatus(profileId);
            status.updateSeriesSync(result.data.length);
            await _storage.saveSyncStatus(status);
          }
          return result;
        } else if (series.isNotEmpty) {
          return ApiResult.success(series);
        }
        return result;
      }

      return ApiResult.success(series);
    } catch (e) {
      final series = _storage.getSeries(profileId, categoryId: categoryId);
      if (series.isNotEmpty) {
        return ApiResult.success(series);
      }
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get series details with episodes
  Future<ApiResult<DomainSeries>> getSeriesDetails(
    String profileId,
    XtreamCredentialsModel credentials,
    String seriesId,
  ) async {
    try {
      // Check local first - if we have episodes cached, use that
      final localSeries = _storage.getSeriesById(profileId, seriesId);
      if (localSeries != null && localSeries.seasons.isNotEmpty) {
        return ApiResult.success(localSeries);
      }

      // Fetch from API
      final result = await _client.getSeriesDetails(credentials, seriesId);
      if (result.isSuccess) {
        // Cache the detailed series
        await _storage.updateSeriesWithDetails(profileId, result.data);
      }
      return result;
    } catch (e) {
      final localSeries = _storage.getSeriesById(profileId, seriesId);
      if (localSeries != null) {
        return ApiResult.success(localSeries);
      }
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get series stream URL
  String getSeriesStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String extension = 'mp4',
  }) {
    return _client.getSeriesStreamUrl(credentials, streamId, extension: extension);
  }

  // ============ EPG ============

  /// Get EPG for a channel (local first)
  Future<ApiResult<List<EpgProgram>>> getChannelEpg(
    String profileId,
    XtreamCredentialsModel credentials,
    String channelId,
  ) async {
    try {
      // Get from local storage first
      var programs = _storage.getEpgForChannel(profileId, channelId);

      // Filter to current and upcoming programs
      final now = DateTime.now();
      programs = programs.where((p) => p.endTime.isAfter(now)).toList();

      if (programs.isNotEmpty) {
        return ApiResult.success(programs);
      }

      // If no local data, try to fetch
      final result = await _client.getChannelEpg(credentials, channelId);
      if (result.isSuccess) {
        // Convert EpgEntry to EpgProgram
        final epgPrograms = result.data.map((e) => EpgProgram(
          channelId: e.channelId,
          title: e.title,
          description: e.description,
          startTime: e.startTime,
          endTime: e.endTime,
          language: e.language,
        )).toList();
        return ApiResult.success(epgPrograms);
      }

      return ApiResult.success(programs);
    } catch (e) {
      final programs = _storage.getEpgForChannel(profileId, channelId);
      return ApiResult.success(programs);
    }
  }

  /// Get current program for a channel
  EpgProgram? getCurrentProgram(String profileId, String channelId) {
    final programs = _storage.getEpgForChannel(profileId, channelId);
    final now = DateTime.now();
    for (final program in programs) {
      if (program.startTime.isBefore(now) && program.endTime.isAfter(now)) {
        return program;
      }
    }
    return null;
  }

  /// Get next program for a channel
  EpgProgram? getNextProgram(String profileId, String channelId) {
    final programs = _storage.getEpgForChannel(profileId, channelId);
    final now = DateTime.now();
    for (final program in programs) {
      if (program.startTime.isAfter(now)) {
        return program;
      }
    }
    return null;
  }

  // ============ Refresh Operations ============

  /// Force refresh all content
  Future<SyncStats> forceRefreshAll(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    return _syncService.performIncrementalSync(
      profileId,
      credentials,
      forceChannels: true,
      forceMovies: true,
      forceSeries: true,
      forceEpg: true,
    );
  }

  /// Refresh live content only
  Future<SyncStats> refreshLiveContent(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    return _syncService.refreshLiveContent(profileId, credentials);
  }

  /// Refresh VOD content only
  Future<SyncStats> refreshVodContent(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    return _syncService.refreshVodContent(profileId, credentials);
  }

  // ============ Background Refresh Helpers ============

  Future<void> _refreshLiveCategoriesInBackground(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    try {
      final result = await _client.getLiveTvCategories(credentials);
      if (result.isSuccess) {
        await _storage.saveLiveCategories(profileId, result.data);
      }
    } catch (e) {
      moduleLogger.debug('Background live categories refresh failed: $e', tag: 'DataRepo');
    }
  }

  Future<void> _refreshChannelsInBackground(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    try {
      final result = await _client.getLiveTvChannels(credentials);
      if (result.isSuccess) {
        await _storage.saveChannels(profileId, result.data);
        final status = _storage.getOrCreateSyncStatus(profileId);
        status.updateChannelSync(result.data.length);
        await _storage.saveSyncStatus(status);
      }
    } catch (e) {
      moduleLogger.debug('Background channels refresh failed: $e', tag: 'DataRepo');
    }
  }

  Future<void> _refreshMovieCategoriesInBackground(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    try {
      final result = await _client.getMovieCategories(credentials);
      if (result.isSuccess) {
        await _storage.saveMovieCategories(profileId, result.data);
      }
    } catch (e) {
      moduleLogger.debug('Background movie categories refresh failed: $e', tag: 'DataRepo');
    }
  }

  Future<void> _refreshMoviesInBackground(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    try {
      final result = await _client.getMovies(credentials);
      if (result.isSuccess) {
        await _storage.saveMovies(profileId, result.data);
        final status = _storage.getOrCreateSyncStatus(profileId);
        status.updateMovieSync(result.data.length);
        await _storage.saveSyncStatus(status);
      }
    } catch (e) {
      moduleLogger.debug('Background movies refresh failed: $e', tag: 'DataRepo');
    }
  }

  Future<void> _refreshSeriesCategoriesInBackground(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    try {
      final result = await _client.getSeriesCategories(credentials);
      if (result.isSuccess) {
        await _storage.saveSeriesCategories(profileId, result.data);
      }
    } catch (e) {
      moduleLogger.debug('Background series categories refresh failed: $e', tag: 'DataRepo');
    }
  }

  Future<void> _refreshSeriesInBackground(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    try {
      final result = await _client.getSeries(credentials);
      if (result.isSuccess) {
        await _storage.saveSeries(profileId, result.data);
        final status = _storage.getOrCreateSyncStatus(profileId);
        status.updateSeriesSync(result.data.length);
        await _storage.saveSyncStatus(status);
      }
    } catch (e) {
      moduleLogger.debug('Background series refresh failed: $e', tag: 'DataRepo');
    }
  }

  // ============ Data Management ============

  /// Clear all cached data for a profile
  Future<void> clearProfileData(String profileId) async {
    await _storage.clearProfileData(profileId);
  }

  /// Get storage statistics
  Map<String, int> getStorageStats(String profileId) {
    return _storage.getStorageStats(profileId);
  }

  /// Get sync status summary
  Map<String, dynamic> getSyncStatusSummary(String profileId) {
    return _syncService.getSyncStatusSummary(profileId);
  }
}

import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/local/local_storage.dart';
import '../../data/models/category_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/series_model.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/playlist_source.dart';
import 'xtream_api_client.dart';

/// Xtream Codes service for managing data with caching and auto-refresh
class XtreamService {
  XtreamService({
    required XtreamApiClient apiClient,
    required LocalStorage localStorage,
  })  : _apiClient = apiClient,
        _localStorage = localStorage;
  final XtreamApiClient _apiClient;
  final LocalStorage _localStorage;

  // In-memory cache
  final Map<String, _CacheEntry<List<ChannelModel>>> _channelCache = {};
  final Map<String, _CacheEntry<List<CategoryModel>>> _categoryCache = {};
  final Map<String, _CacheEntry<List<CategoryModel>>> _movieCategoryCache = {};
  final Map<String, _CacheEntry<List<CategoryModel>>> _seriesCategoryCache = {};
  final Map<String, _CacheEntry<List<MovieModel>>> _movieCache = {};
  final Map<String, _CacheEntry<List<SeriesModel>>> _seriesCache = {};
  final Map<String, _CacheEntry<Map<String, List<EpgEntry>>>> _epgCache = {};

  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  Duration _refreshInterval = const Duration(hours: 24);

  // Last refresh timestamp per playlist
  final Map<String, DateTime> _lastRefreshTimes = {};

  /// Get or set refresh interval (default 24 hours)
  Duration get refreshInterval => _refreshInterval;
  set refreshInterval(Duration duration) {
    _refreshInterval = duration;
    _restartAutoRefresh();
  }

  /// Start auto-refresh for a playlist
  void startAutoRefresh(XtreamCredentials credentials, {Duration? interval}) {
    _autoRefreshTimer?.cancel();
    final duration = interval ?? _refreshInterval;
    _autoRefreshTimer = Timer.periodic(duration, (_) {
      _performAutoRefresh(credentials);
    });
    AppLogger.info('Auto-refresh started with interval: $duration');
  }

  /// Stop auto-refresh
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    AppLogger.info('Auto-refresh stopped');
  }

  /// Dispose of resources
  void dispose() {
    stopAutoRefresh();
    _channelCache.clear();
    _categoryCache.clear();
    _movieCategoryCache.clear();
    _seriesCategoryCache.clear();
    _movieCache.clear();
    _seriesCache.clear();
    _epgCache.clear();
  }

  void _restartAutoRefresh() {
    // Note: Auto-refresh requires credentials to be stored
    // This is a placeholder - actual implementation would need
    // to store and retrieve the credentials from persistent storage
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    // Timer restart is handled by startAutoRefresh with credentials
  }

  Future<void> _performAutoRefresh(XtreamCredentials credentials) async {
    AppLogger.info('Performing auto-refresh for ${credentials.username}');
    try {
      // Refresh live channels and categories
      await refreshLiveData(credentials);
      // Refresh movies
      await refreshMovies(credentials);
      // Refresh series
      await refreshSeries(credentials);
      // Refresh EPG
      await refreshEpg(credentials);
      AppLogger.info('Auto-refresh completed successfully');
    } catch (e) {
      AppLogger.error('Auto-refresh failed', e);
    }
  }

  /// Get last refresh time for a playlist
  DateTime? getLastRefreshTime(String playlistId) {
    return _lastRefreshTimes[playlistId];
  }

  /// Check if data needs refresh (older than cache expiration)
  bool needsRefresh(String playlistId) {
    final lastRefresh = _lastRefreshTimes[playlistId];
    if (lastRefresh == null) return true;
    return DateTime.now().difference(lastRefresh) >
        AppConstants.cacheExpiration;
  }

  /// Refresh all live data (channels and categories)
  Future<void> refreshLiveData(XtreamCredentials credentials) async {
    final cacheKey = _getCacheKey(credentials);

    final categories = await _apiClient.fetchLiveCategories(credentials);
    final channels = await _apiClient.fetchLiveChannels(credentials);

    _categoryCache[cacheKey] = _CacheEntry(categories);
    _channelCache[cacheKey] = _CacheEntry(channels);
    _lastRefreshTimes[credentials.baseUrl] = DateTime.now();

    // Cache to local storage
    await _localStorage.cacheChannels(
      credentials.baseUrl,
      channels,
    );

    AppLogger.info(
        'Refreshed live data: ${channels.length} channels, ${categories.length} categories');
  }

  /// Refresh movie data
  Future<void> refreshMovies(XtreamCredentials credentials) async {
    final cacheKey = _getCacheKey(credentials);
    final movies = await _apiClient.fetchMovies(credentials);
    _movieCache[cacheKey] = _CacheEntry(movies);
    AppLogger.info('Refreshed movies: ${movies.length}');
  }

  /// Refresh series data
  Future<void> refreshSeries(XtreamCredentials credentials) async {
    final cacheKey = _getCacheKey(credentials);
    final series = await _apiClient.fetchSeries(credentials);
    _seriesCache[cacheKey] = _CacheEntry(series);
    AppLogger.info('Refreshed series: ${series.length}');
  }

  /// Refresh EPG data
  Future<void> refreshEpg(XtreamCredentials credentials) async {
    final cacheKey = _getCacheKey(credentials);

    // Try to use cached channel IDs to avoid fetching channels again
    List<String>? channelIds;
    final cachedChannels = _channelCache[cacheKey];
    if (cachedChannels != null && !cachedChannels.isExpired) {
      channelIds = cachedChannels.data.map((c) => c.id).toList();
    }

    final epg = await _apiClient.fetchAllEpg(
      credentials,
      channelIds: channelIds,
    );
    _epgCache[cacheKey] = _CacheEntry(epg);
    AppLogger.info('Refreshed EPG: ${epg.length} channels');
  }

  /// Get EPG data (from cache or fetch)
  Future<Map<String, List<EpgEntry>>> getEpg(
    XtreamCredentials credentials, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(credentials);
    final cached = _epgCache[cacheKey];

    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    // Try to use cached channel IDs to avoid fetching channels again
    List<String>? channelIds;
    final cachedChannels = _channelCache[cacheKey];
    if (cachedChannels != null && !cachedChannels.isExpired) {
      channelIds = cachedChannels.data.map((c) => c.id).toList();
    }

    final epg = await _apiClient.fetchAllEpg(
      credentials,
      channelIds: channelIds,
    );
    _epgCache[cacheKey] = _CacheEntry(epg);
    return epg;
  }

  /// Full refresh of all data
  Future<void> fullRefresh(XtreamCredentials credentials) async {
    AppLogger.info('Starting full refresh for ${credentials.username}');
    await refreshLiveData(credentials);
    await refreshMovies(credentials);
    await refreshSeries(credentials);
    await refreshEpg(credentials);
    AppLogger.info('Full refresh completed');
  }

  /// Get live categories (from cache or fetch)
  Future<List<CategoryModel>> getLiveCategories(
    XtreamCredentials credentials, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(credentials);
    final cached = _categoryCache[cacheKey];

    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    final categories = await _apiClient.fetchLiveCategories(credentials);
    _categoryCache[cacheKey] = _CacheEntry(categories);
    return categories;
  }

  /// Get movie categories (from cache or fetch)
  Future<List<CategoryModel>> getMovieCategories(
    XtreamCredentials credentials, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(credentials);
    final cached = _movieCategoryCache[cacheKey];

    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    final categories = await _apiClient.fetchMovieCategories(credentials);
    _movieCategoryCache[cacheKey] = _CacheEntry(categories);
    return categories;
  }

  /// Get series categories (from cache or fetch)
  Future<List<CategoryModel>> getSeriesCategories(
    XtreamCredentials credentials, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(credentials);
    final cached = _seriesCategoryCache[cacheKey];

    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    final categories = await _apiClient.fetchSeriesCategories(credentials);
    _seriesCategoryCache[cacheKey] = _CacheEntry(categories);
    return categories;
  }

  /// Get live channels (from cache or fetch)
  Future<List<ChannelModel>> getLiveChannels(
    XtreamCredentials credentials, {
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(credentials);
    final cached = _channelCache[cacheKey];

    List<ChannelModel> channels;
    if (!forceRefresh && cached != null && !cached.isExpired) {
      channels = cached.data;
    } else {
      channels = await _apiClient.fetchLiveChannels(credentials);
      _channelCache[cacheKey] = _CacheEntry(channels);
    }

    if (categoryId != null) {
      return channels.where((c) => c.categoryId == categoryId).toList();
    }
    return channels;
  }

  /// Get live channels with EPG info attached
  Future<List<ChannelModel>> getLiveChannelsWithEpg(
    XtreamCredentials credentials, {
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final channels = await getLiveChannels(
      credentials,
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    );

    final cacheKey = _getCacheKey(credentials);
    Map<String, List<EpgEntry>> epgData;

    final cachedEpg = _epgCache[cacheKey];
    if (cachedEpg != null && !cachedEpg.isExpired) {
      epgData = cachedEpg.data;
    } else {
      // Pass channel IDs to avoid fetching channels again in fetchAllEpg
      final channelIds = channels.map((c) => c.id).toList();
      epgData = await _apiClient.fetchAllEpg(
        credentials,
        channelIds: channelIds,
      );
      _epgCache[cacheKey] = _CacheEntry(epgData);
    }

    // Attach EPG info to channels
    return channels.map((channel) {
      final epgList = epgData[channel.id] ?? [];
      EpgEntry? currentProgram;
      EpgEntry? nextProgram;

      for (final epg in epgList) {
        if (epg.isCurrentlyAiring) {
          currentProgram = epg;
        }
      }

      if (currentProgram != null) {
        for (final epg in epgList) {
          if (epg.startTime.isAfter(currentProgram.endTime)) {
            nextProgram = epg;
            break;
          }
        }
      }

      if (currentProgram != null) {
        return ChannelModel(
          id: channel.id,
          name: channel.name,
          streamUrl: channel.streamUrl,
          logoUrl: channel.logoUrl,
          groupTitle: channel.groupTitle,
          categoryId: channel.categoryId,
          type: channel.type,
          metadata: channel.metadata,
          epgInfo: EpgInfoModel(
            currentProgram: currentProgram.title,
            nextProgram: nextProgram?.title,
            startTime: currentProgram.startTime,
            endTime: currentProgram.endTime,
            description: currentProgram.description,
          ),
        );
      }
      return channel;
    }).toList();
  }

  /// Get movies (from cache or fetch)
  Future<List<MovieModel>> getMovies(
    XtreamCredentials credentials, {
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(credentials);
    final cached = _movieCache[cacheKey];

    List<MovieModel> movies;
    if (!forceRefresh && cached != null && !cached.isExpired) {
      movies = cached.data;
    } else {
      movies = await _apiClient.fetchMovies(credentials);
      _movieCache[cacheKey] = _CacheEntry(movies);
    }

    if (categoryId != null) {
      return movies.where((m) => m.categoryId == categoryId).toList();
    }
    return movies;
  }

  /// Get series (from cache or fetch)
  Future<List<SeriesModel>> getSeries(
    XtreamCredentials credentials, {
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(credentials);
    final cached = _seriesCache[cacheKey];

    List<SeriesModel> series;
    if (!forceRefresh && cached != null && !cached.isExpired) {
      series = cached.data;
    } else {
      series = await _apiClient.fetchSeries(credentials);
      _seriesCache[cacheKey] = _CacheEntry(series);
    }

    if (categoryId != null) {
      return series.where((s) => s.categoryId == categoryId).toList();
    }
    return series;
  }

  /// Get EPG for specific stream
  Future<List<EpgEntry>> getEpgForStream(
    XtreamCredentials credentials,
    String streamId,
  ) async {
    return _apiClient.fetchShortEpg(credentials, streamId);
  }

  /// Clear all caches
  void clearCache() {
    _channelCache.clear();
    _categoryCache.clear();
    _movieCategoryCache.clear();
    _seriesCategoryCache.clear();
    _movieCache.clear();
    _seriesCache.clear();
    _epgCache.clear();
    _lastRefreshTimes.clear();
    AppLogger.info('All caches cleared');
  }

  /// Clear cache for specific playlist
  void clearCacheForPlaylist(XtreamCredentials credentials) {
    final cacheKey = _getCacheKey(credentials);
    _channelCache.remove(cacheKey);
    _categoryCache.remove(cacheKey);
    _movieCategoryCache.remove(cacheKey);
    _seriesCategoryCache.remove(cacheKey);
    _movieCache.remove(cacheKey);
    _seriesCache.remove(cacheKey);
    _epgCache.remove(cacheKey);
    _lastRefreshTimes.remove(credentials.baseUrl);
    AppLogger.info('Cache cleared for ${credentials.username}');
  }

  String _getCacheKey(XtreamCredentials credentials) {
    return '${credentials.baseUrl}_${credentials.username}';
  }
}

/// Cache entry with expiration
class _CacheEntry<T> {
  _CacheEntry(
    this.data, {
    Duration? expiration,
  })  : createdAt = DateTime.now(),
        expiration = expiration ?? AppConstants.cacheExpiration;
  final T data;
  final DateTime createdAt;
  final Duration expiration;

  bool get isExpired => DateTime.now().difference(createdAt) > expiration;
}

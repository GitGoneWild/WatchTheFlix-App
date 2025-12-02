// XtreamSyncService
// Coordinates synchronization of Xtream Codes data between API and local storage.
// Implements smart API usage with TTL-based caching and incremental updates.

import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../epg/epg_models.dart';
import '../storage/xtream_hive_models.dart';
import '../storage/xtream_local_storage.dart';
import '../xtream_codes_client.dart';

/// Sync progress state
enum SyncState {
  idle,
  syncing,
  completed,
  failed,
}

/// Sync progress information
class SyncProgress extends Equatable {
  final SyncState state;
  final String? currentOperation;
  final double progress;
  final String? errorMessage;
  final SyncStats? stats;

  const SyncProgress({
    this.state = SyncState.idle,
    this.currentOperation,
    this.progress = 0.0,
    this.errorMessage,
    this.stats,
  });

  SyncProgress copyWith({
    SyncState? state,
    String? currentOperation,
    double? progress,
    String? errorMessage,
    SyncStats? stats,
  }) {
    return SyncProgress(
      state: state ?? this.state,
      currentOperation: currentOperation ?? this.currentOperation,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [state, currentOperation, progress, errorMessage, stats];
}

/// Statistics from a sync operation
class SyncStats extends Equatable {
  final int channelsImported;
  final int categoriesImported;
  final int moviesImported;
  final int seriesImported;
  final int epgProgramsImported;
  final Duration duration;
  final List<String> errors;

  const SyncStats({
    this.channelsImported = 0,
    this.categoriesImported = 0,
    this.moviesImported = 0,
    this.seriesImported = 0,
    this.epgProgramsImported = 0,
    this.duration = Duration.zero,
    this.errors = const [],
  });

  int get totalItems =>
      channelsImported +
      categoriesImported +
      moviesImported +
      seriesImported +
      epgProgramsImported;

  bool get hasErrors => errors.isNotEmpty;

  @override
  List<Object?> get props => [
        channelsImported,
        categoriesImported,
        moviesImported,
        seriesImported,
        epgProgramsImported,
        duration,
        errors,
      ];
}

/// Sync configuration options
class SyncConfig {
  /// TTL for channel data (default: 1 hour)
  final Duration channelTtl;

  /// TTL for movie data (default: 4 hours)
  final Duration movieTtl;

  /// TTL for series data (default: 4 hours)
  final Duration seriesTtl;

  /// TTL for EPG data (default: 6 hours)
  final Duration epgTtl;

  /// Whether to sync EPG during initial sync
  final bool syncEpgOnInitial;

  /// Whether to sync movies during initial sync
  final bool syncMoviesOnInitial;

  /// Whether to sync series during initial sync
  final bool syncSeriesOnInitial;

  const SyncConfig({
    this.channelTtl = const Duration(hours: 1),
    this.movieTtl = const Duration(hours: 4),
    this.seriesTtl = const Duration(hours: 4),
    this.epgTtl = const Duration(hours: 6),
    this.syncEpgOnInitial = true,
    this.syncMoviesOnInitial = true,
    this.syncSeriesOnInitial = true,
  });

  /// Default sync configuration
  static const SyncConfig defaultConfig = SyncConfig();
}

/// Xtream Codes sync service for coordinating data synchronization.
///
/// This service provides:
/// - Initial full sync on first connection
/// - Incremental updates based on TTL
/// - Graceful error handling with fallback to cached data
/// - Progress tracking for UI feedback
class XtreamSyncService {
  final XtreamCodesClient _client;
  final XtreamLocalStorage _storage;
  final SyncConfig _config;

  /// Stream controller for sync progress updates
  final _progressController = StreamController<SyncProgress>.broadcast();

  /// Current sync progress
  SyncProgress _currentProgress = const SyncProgress();

  XtreamSyncService({
    required XtreamCodesClient client,
    required XtreamLocalStorage storage,
    SyncConfig config = SyncConfig.defaultConfig,
  })  : _client = client,
        _storage = storage,
        _config = config;

  /// Stream of sync progress updates
  Stream<SyncProgress> get progressStream => _progressController.stream;

  /// Current sync progress
  SyncProgress get currentProgress => _currentProgress;

  /// Whether a sync is currently in progress
  bool get isSyncing => _currentProgress.state == SyncState.syncing;

  /// Perform initial full sync for a profile.
  ///
  /// This fetches all data from the Xtream server and stores it locally.
  /// Should be called on first connection to a server.
  Future<SyncStats> performInitialSync(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    if (isSyncing) {
      throw StateError('Sync already in progress');
    }

    final startTime = DateTime.now();
    final errors = <String>[];
    var channelsImported = 0;
    var categoriesImported = 0;
    var moviesImported = 0;
    var seriesImported = 0;
    var epgProgramsImported = 0;

    try {
      _updateProgress(
        state: SyncState.syncing,
        operation: 'Starting initial sync...',
        progress: 0.0,
      );

      moduleLogger.info('Starting initial sync for profile $profileId', tag: 'Sync');

      // Get or create sync status
      final syncStatus = _storage.getOrCreateSyncStatus(profileId);

      // 1. Sync Live TV Categories (5% progress)
      _updateProgress(operation: 'Syncing live TV categories...', progress: 0.05);
      try {
        final liveCategoriesResult = await _client.getLiveTvCategories(credentials);
        if (liveCategoriesResult.isSuccess) {
          await _storage.saveLiveCategories(profileId, liveCategoriesResult.data);
          categoriesImported += liveCategoriesResult.data.length;
        } else {
          errors.add('Live categories: ${liveCategoriesResult.error.message}');
        }
      } catch (e) {
        errors.add('Live categories: $e');
        moduleLogger.warning('Failed to sync live categories: $e', tag: 'Sync');
      }

      // 2. Sync Live TV Channels (20% progress)
      _updateProgress(operation: 'Syncing live TV channels...', progress: 0.10);
      try {
        final channelsResult = await _client.getLiveTvChannels(credentials);
        if (channelsResult.isSuccess) {
          await _storage.saveChannels(profileId, channelsResult.data);
          channelsImported = channelsResult.data.length;
          syncStatus.updateChannelSync(channelsImported);
        } else {
          errors.add('Live channels: ${channelsResult.error.message}');
        }
      } catch (e) {
        errors.add('Live channels: $e');
        moduleLogger.warning('Failed to sync live channels: $e', tag: 'Sync');
      }

      // 3. Sync Movie Categories (25% progress)
      if (_config.syncMoviesOnInitial) {
        _updateProgress(operation: 'Syncing movie categories...', progress: 0.25);
        try {
          final movieCategoriesResult = await _client.getMovieCategories(credentials);
          if (movieCategoriesResult.isSuccess) {
            await _storage.saveMovieCategories(profileId, movieCategoriesResult.data);
            categoriesImported += movieCategoriesResult.data.length;
          } else {
            errors.add('Movie categories: ${movieCategoriesResult.error.message}');
          }
        } catch (e) {
          errors.add('Movie categories: $e');
        }

        // 4. Sync Movies (40% progress)
        _updateProgress(operation: 'Syncing movies...', progress: 0.35);
        try {
          final moviesResult = await _client.getMovies(credentials);
          if (moviesResult.isSuccess) {
            await _storage.saveMovies(profileId, moviesResult.data);
            moviesImported = moviesResult.data.length;
            syncStatus.updateMovieSync(moviesImported);
          } else {
            errors.add('Movies: ${moviesResult.error.message}');
          }
        } catch (e) {
          errors.add('Movies: $e');
          moduleLogger.warning('Failed to sync movies: $e', tag: 'Sync');
        }
      }

      // 5. Sync Series Categories (50% progress)
      if (_config.syncSeriesOnInitial) {
        _updateProgress(operation: 'Syncing series categories...', progress: 0.50);
        try {
          final seriesCategoriesResult = await _client.getSeriesCategories(credentials);
          if (seriesCategoriesResult.isSuccess) {
            await _storage.saveSeriesCategories(profileId, seriesCategoriesResult.data);
            categoriesImported += seriesCategoriesResult.data.length;
          } else {
            errors.add('Series categories: ${seriesCategoriesResult.error.message}');
          }
        } catch (e) {
          errors.add('Series categories: $e');
        }

        // 6. Sync Series (65% progress)
        _updateProgress(operation: 'Syncing TV series...', progress: 0.60);
        try {
          final seriesResult = await _client.getSeries(credentials);
          if (seriesResult.isSuccess) {
            await _storage.saveSeries(profileId, seriesResult.data);
            seriesImported = seriesResult.data.length;
            syncStatus.updateSeriesSync(seriesImported);
          } else {
            errors.add('Series: ${seriesResult.error.message}');
          }
        } catch (e) {
          errors.add('Series: $e');
          moduleLogger.warning('Failed to sync series: $e', tag: 'Sync');
        }
      }

      // 7. Sync EPG (90% progress)
      if (_config.syncEpgOnInitial) {
        _updateProgress(operation: 'Syncing EPG data...', progress: 0.75);
        try {
          final epgResult = await _client.getFullEpg(credentials);
          if (epgResult.isSuccess && epgResult.data.isNotEmpty) {
            // Flatten all programs
            final allPrograms = <EpgProgram>[];
            for (final programs in epgResult.data.programs.values) {
              allPrograms.addAll(programs);
            }
            await _storage.saveEpgPrograms(profileId, allPrograms);
            epgProgramsImported = allPrograms.length;
            syncStatus.updateEpgSync(epgProgramsImported);
          } else if (epgResult.isFailure) {
            errors.add('EPG: ${epgResult.error.message}');
          }
        } catch (e) {
          errors.add('EPG: $e');
          moduleLogger.warning('Failed to sync EPG: $e', tag: 'Sync');
        }
      }

      // Update category sync timestamp
      syncStatus.updateCategorySync();

      // Mark initial sync complete
      syncStatus.markInitialSyncComplete();
      await _storage.saveSyncStatus(syncStatus);

      final duration = DateTime.now().difference(startTime);
      final stats = SyncStats(
        channelsImported: channelsImported,
        categoriesImported: categoriesImported,
        moviesImported: moviesImported,
        seriesImported: seriesImported,
        epgProgramsImported: epgProgramsImported,
        duration: duration,
        errors: errors,
      );

      _updateProgress(
        state: SyncState.completed,
        operation: 'Sync completed',
        progress: 1.0,
        stats: stats,
      );

      moduleLogger.info(
        'Initial sync completed: ${stats.totalItems} items in ${duration.inSeconds}s',
        tag: 'Sync',
      );

      return stats;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Initial sync failed',
        tag: 'Sync',
        error: e,
        stackTrace: stackTrace,
      );

      _updateProgress(
        state: SyncState.failed,
        operation: 'Sync failed',
        errorMessage: e.toString(),
      );

      rethrow;
    }
  }

  /// Perform incremental sync based on TTL settings.
  ///
  /// Only syncs data that has exceeded its TTL.
  Future<SyncStats> performIncrementalSync(
    String profileId,
    XtreamCredentialsModel credentials, {
    bool forceChannels = false,
    bool forceMovies = false,
    bool forceSeries = false,
    bool forceEpg = false,
  }) async {
    if (isSyncing) {
      throw StateError('Sync already in progress');
    }

    final startTime = DateTime.now();
    final errors = <String>[];
    var channelsImported = 0;
    var moviesImported = 0;
    var seriesImported = 0;
    var epgProgramsImported = 0;
    var categoriesImported = 0;

    try {
      _updateProgress(
        state: SyncState.syncing,
        operation: 'Checking for updates...',
        progress: 0.0,
      );

      final syncStatus = _storage.getOrCreateSyncStatus(profileId);
      var operationsDone = 0;
      var totalOperations = 0;

      // Count operations needed
      if (forceChannels || syncStatus.needsChannelRefresh(_config.channelTtl)) {
        totalOperations += 2; // categories + channels
      }
      if (forceMovies || syncStatus.needsMovieRefresh(_config.movieTtl)) {
        totalOperations += 2; // categories + movies
      }
      if (forceSeries || syncStatus.needsSeriesRefresh(_config.seriesTtl)) {
        totalOperations += 2; // categories + series
      }
      if (forceEpg || syncStatus.needsEpgRefresh(_config.epgTtl)) {
        totalOperations += 1;
      }

      if (totalOperations == 0) {
        _updateProgress(
          state: SyncState.completed,
          operation: 'All data is up to date',
          progress: 1.0,
          stats: const SyncStats(),
        );
        return const SyncStats();
      }

      double getProgress() => totalOperations > 0 ? operationsDone / totalOperations : 0.0;

      // Sync channels if needed
      if (forceChannels || syncStatus.needsChannelRefresh(_config.channelTtl)) {
        _updateProgress(operation: 'Syncing live TV...', progress: getProgress());

        try {
          final categoriesResult = await _client.getLiveTvCategories(credentials);
          if (categoriesResult.isSuccess) {
            await _storage.saveLiveCategories(profileId, categoriesResult.data);
            categoriesImported += categoriesResult.data.length;
          }
          operationsDone++;

          final channelsResult = await _client.getLiveTvChannels(credentials);
          if (channelsResult.isSuccess) {
            await _storage.saveChannels(profileId, channelsResult.data);
            channelsImported = channelsResult.data.length;
            syncStatus.updateChannelSync(channelsImported);
          } else {
            errors.add('Channels: ${channelsResult.error.message}');
          }
          operationsDone++;
        } catch (e) {
          errors.add('Channels: $e');
          operationsDone += 2;
        }
      }

      // Sync movies if needed
      if (forceMovies || syncStatus.needsMovieRefresh(_config.movieTtl)) {
        _updateProgress(operation: 'Syncing movies...', progress: getProgress());

        try {
          final categoriesResult = await _client.getMovieCategories(credentials);
          if (categoriesResult.isSuccess) {
            await _storage.saveMovieCategories(profileId, categoriesResult.data);
            categoriesImported += categoriesResult.data.length;
          }
          operationsDone++;

          final moviesResult = await _client.getMovies(credentials);
          if (moviesResult.isSuccess) {
            await _storage.saveMovies(profileId, moviesResult.data);
            moviesImported = moviesResult.data.length;
            syncStatus.updateMovieSync(moviesImported);
          } else {
            errors.add('Movies: ${moviesResult.error.message}');
          }
          operationsDone++;
        } catch (e) {
          errors.add('Movies: $e');
          operationsDone += 2;
        }
      }

      // Sync series if needed
      if (forceSeries || syncStatus.needsSeriesRefresh(_config.seriesTtl)) {
        _updateProgress(operation: 'Syncing TV series...', progress: getProgress());

        try {
          final categoriesResult = await _client.getSeriesCategories(credentials);
          if (categoriesResult.isSuccess) {
            await _storage.saveSeriesCategories(profileId, categoriesResult.data);
            categoriesImported += categoriesResult.data.length;
          }
          operationsDone++;

          final seriesResult = await _client.getSeries(credentials);
          if (seriesResult.isSuccess) {
            await _storage.saveSeries(profileId, seriesResult.data);
            seriesImported = seriesResult.data.length;
            syncStatus.updateSeriesSync(seriesImported);
          } else {
            errors.add('Series: ${seriesResult.error.message}');
          }
          operationsDone++;
        } catch (e) {
          errors.add('Series: $e');
          operationsDone += 2;
        }
      }

      // Sync EPG if needed
      if (forceEpg || syncStatus.needsEpgRefresh(_config.epgTtl)) {
        _updateProgress(operation: 'Syncing EPG...', progress: getProgress());

        try {
          // Clean up old EPG first
          await _storage.cleanupOldEpg(profileId);

          final epgResult = await _client.getFullEpg(credentials);
          if (epgResult.isSuccess && epgResult.data.isNotEmpty) {
            final allPrograms = <EpgProgram>[];
            for (final programs in epgResult.data.programs.values) {
              allPrograms.addAll(programs);
            }
            await _storage.saveEpgPrograms(profileId, allPrograms);
            epgProgramsImported = allPrograms.length;
            syncStatus.updateEpgSync(epgProgramsImported);
          } else if (epgResult.isFailure) {
            errors.add('EPG: ${epgResult.error.message}');
          }
          operationsDone++;
        } catch (e) {
          errors.add('EPG: $e');
          operationsDone++;
        }
      }

      await _storage.saveSyncStatus(syncStatus);

      final duration = DateTime.now().difference(startTime);
      final stats = SyncStats(
        channelsImported: channelsImported,
        categoriesImported: categoriesImported,
        moviesImported: moviesImported,
        seriesImported: seriesImported,
        epgProgramsImported: epgProgramsImported,
        duration: duration,
        errors: errors,
      );

      _updateProgress(
        state: SyncState.completed,
        operation: 'Sync completed',
        progress: 1.0,
        stats: stats,
      );

      moduleLogger.info(
        'Incremental sync completed: ${stats.totalItems} items updated',
        tag: 'Sync',
      );

      return stats;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Incremental sync failed',
        tag: 'Sync',
        error: e,
        stackTrace: stackTrace,
      );

      _updateProgress(
        state: SyncState.failed,
        operation: 'Sync failed',
        errorMessage: e.toString(),
      );

      rethrow;
    }
  }

  /// Refresh only channels and EPG (for quick refresh)
  Future<SyncStats> refreshLiveContent(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    return performIncrementalSync(
      profileId,
      credentials,
      forceChannels: true,
      forceEpg: true,
    );
  }

  /// Refresh only VOD content (movies and series)
  Future<SyncStats> refreshVodContent(
    String profileId,
    XtreamCredentialsModel credentials,
  ) async {
    return performIncrementalSync(
      profileId,
      credentials,
      forceMovies: true,
      forceSeries: true,
    );
  }

  /// Check if initial sync is needed for a profile
  bool needsInitialSync(String profileId) {
    final status = _storage.getSyncStatus(profileId);
    return status == null || !status.isInitialSyncComplete;
  }

  /// Check if any data needs refresh
  bool needsRefresh(String profileId) {
    final status = _storage.getSyncStatus(profileId);
    if (status == null) return true;

    return status.needsChannelRefresh(_config.channelTtl) ||
        status.needsMovieRefresh(_config.movieTtl) ||
        status.needsSeriesRefresh(_config.seriesTtl) ||
        status.needsEpgRefresh(_config.epgTtl);
  }

  /// Get sync status summary
  Map<String, dynamic> getSyncStatusSummary(String profileId) {
    final status = _storage.getSyncStatus(profileId);
    if (status == null) {
      return {
        'isInitialSyncComplete': false,
        'needsSync': true,
      };
    }

    return {
      'isInitialSyncComplete': status.isInitialSyncComplete,
      'lastChannelSync': status.lastChannelSync?.toIso8601String(),
      'lastMovieSync': status.lastMovieSync?.toIso8601String(),
      'lastSeriesSync': status.lastSeriesSync?.toIso8601String(),
      'lastEpgSync': status.lastEpgSync?.toIso8601String(),
      'channelCount': status.channelCount,
      'movieCount': status.movieCount,
      'seriesCount': status.seriesCount,
      'epgProgramCount': status.epgProgramCount,
      'needsChannelRefresh': status.needsChannelRefresh(_config.channelTtl),
      'needsMovieRefresh': status.needsMovieRefresh(_config.movieTtl),
      'needsSeriesRefresh': status.needsSeriesRefresh(_config.seriesTtl),
      'needsEpgRefresh': status.needsEpgRefresh(_config.epgTtl),
    };
  }

  void _updateProgress({
    SyncState? state,
    String? operation,
    double? progress,
    String? errorMessage,
    SyncStats? stats,
  }) {
    _currentProgress = _currentProgress.copyWith(
      state: state,
      currentOperation: operation,
      progress: progress,
      errorMessage: errorMessage,
      stats: stats,
    );
    _progressController.add(_currentProgress);
  }

  /// Reset progress to idle state
  void resetProgress() {
    _currentProgress = const SyncProgress();
    _progressController.add(_currentProgress);
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}

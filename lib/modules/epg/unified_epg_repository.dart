// Unified EPG Repository
// Provides a source-agnostic interface for fetching and managing EPG data.

import 'dart:async';

import '../core/logging/app_logger.dart';
import '../core/models/api_result.dart';
import '../core/models/base_models.dart';
import '../xtreamcodes/epg/epg_models.dart';
import '../xtreamcodes/repositories/epg_repository_impl.dart';
import 'epg_local_storage.dart';
import 'epg_source.dart';
import 'url_epg_provider.dart';

/// Unified EPG repository that works with both URL-based and Xtream Codes EPG sources.
///
/// This repository provides a consistent interface for:
/// - Fetching EPG data from either source type
/// - Caching EPG data locally (in-memory and optionally persistent)
/// - Providing fallback to cached data on fetch failure
/// - Managing refresh policies
class UnifiedEpgRepository {
  UnifiedEpgRepository({
    UrlEpgProvider? urlProvider,
    EpgRepositoryImpl? xtreamRepository,
    EpgLocalStorage? localStorage,
  })  : _urlProvider = urlProvider ?? UrlEpgProvider(),
        _xtreamRepository = xtreamRepository,
        _localStorage = localStorage;
  final UrlEpgProvider _urlProvider;
  final EpgRepositoryImpl? _xtreamRepository;
  final EpgLocalStorage? _localStorage;

  /// In-memory cache for EPG data.
  final Map<String, EpgData> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Current source configuration.
  EpgSourceConfig? _currentConfig;

  /// Get the current source configuration.
  EpgSourceConfig? get currentConfig => _currentConfig;

  /// Configure the EPG source.
  void configure(EpgSourceConfig config) {
    _currentConfig = config;
    moduleLogger.info(
      'EPG source configured: ${config.type.name}',
      tag: 'UnifiedEpg',
    );
  }

  /// Fetch EPG data based on current configuration.
  ///
  /// [forceRefresh] If true, bypass cache and fetch fresh data.
  /// Returns [ApiResult] with [EpgData].
  Future<ApiResult<EpgData>> fetchEpg({
    bool forceRefresh = false,
    XtreamCredentialsModel? credentials,
  }) async {
    final config = _currentConfig;

    if (config == null || !config.isConfigured) {
      moduleLogger.warning(
        'EPG source not configured',
        tag: 'UnifiedEpg',
      );
      return ApiResult.failure(
        const ApiError(
          type: ApiErrorType.validation,
          message: 'EPG source not configured',
        ),
      );
    }

    // Check cache first (unless force refresh)
    final cacheKey = _getCacheKey(config);
    if (!forceRefresh && _isCacheValid(cacheKey, config.refreshInterval)) {
      final cached = _cache[cacheKey];
      if (cached != null) {
        moduleLogger.debug(
          'Returning cached EPG data',
          tag: 'UnifiedEpg',
        );
        return ApiResult.success(cached);
      }
    }

    // Try to load from local storage if cache miss
    if (!forceRefresh && _localStorage != null) {
      final storedData = _loadFromStorage(cacheKey);
      if (storedData != null) {
        _updateCache(cacheKey, storedData);
        moduleLogger.debug(
          'Loaded EPG from local storage',
          tag: 'UnifiedEpg',
        );
        return ApiResult.success(storedData);
      }
    }

    // Fetch based on source type
    return _fetchFromSource(config,
        credentials: credentials, cacheKey: cacheKey);
  }

  /// Fetch EPG from URL source.
  Future<ApiResult<EpgData>> fetchFromUrl(String url) async {
    final config = EpgSourceConfig.fromUrl(url);
    return _fetchFromSource(config, cacheKey: url);
  }

  /// Fetch EPG from Xtream Codes source.
  Future<ApiResult<EpgData>> fetchFromXtream(
    XtreamCredentialsModel credentials,
  ) async {
    if (_xtreamRepository == null) {
      return ApiResult.failure(
        const ApiError(
          type: ApiErrorType.validation,
          message: 'Xtream Codes repository not configured',
        ),
      );
    }

    final cacheKey = EpgLocalStorage.generateXtreamSourceId(
      '${credentials.baseUrl}_${credentials.username}',
    );
    return _xtreamRepository.fetchFullXmltvEpg(credentials).then((result) {
      if (result.isSuccess) {
        _updateCache(cacheKey, result.data);
        _saveToStorage(cacheKey, result.data);
      }
      return result;
    });
  }

  /// Get current program for a channel.
  ///
  /// [channelId] The EPG channel ID to look up.
  /// [credentials] Optional Xtream credentials if using Xtream source.
  Future<ApiResult<EpgProgram?>> getCurrentProgram(
    String channelId, {
    XtreamCredentialsModel? credentials,
  }) async {
    final epgResult = await fetchEpg(credentials: credentials);

    if (epgResult.isFailure) {
      return ApiResult.failure(epgResult.error);
    }

    final program = epgResult.data.getCurrentProgram(channelId);
    return ApiResult.success(program);
  }

  /// Get next program for a channel.
  Future<ApiResult<EpgProgram?>> getNextProgram(
    String channelId, {
    XtreamCredentialsModel? credentials,
  }) async {
    final epgResult = await fetchEpg(credentials: credentials);

    if (epgResult.isFailure) {
      return ApiResult.failure(epgResult.error);
    }

    final program = epgResult.data.getNextProgram(channelId);
    return ApiResult.success(program);
  }

  /// Get daily schedule for a channel.
  Future<ApiResult<List<EpgProgram>>> getDailySchedule(
    String channelId,
    DateTime date, {
    XtreamCredentialsModel? credentials,
  }) async {
    final epgResult = await fetchEpg(credentials: credentials);

    if (epgResult.isFailure) {
      return ApiResult.failure(epgResult.error);
    }

    final schedule = epgResult.data.getDailySchedule(channelId, date);
    return ApiResult.success(schedule);
  }

  /// Get programs in a time range for a channel.
  Future<ApiResult<List<EpgProgram>>> getProgramsInRange(
    String channelId,
    DateTime start,
    DateTime end, {
    XtreamCredentialsModel? credentials,
  }) async {
    final epgResult = await fetchEpg(credentials: credentials);

    if (epgResult.isFailure) {
      return ApiResult.failure(epgResult.error);
    }

    final programs = epgResult.data.getProgramsInRange(channelId, start, end);
    return ApiResult.success(programs);
  }

  /// Refresh EPG data (bypasses cache).
  Future<ApiResult<EpgData>> refresh({
    XtreamCredentialsModel? credentials,
  }) async {
    return fetchEpg(forceRefresh: true, credentials: credentials);
  }

  /// Clear all cached EPG data.
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    moduleLogger.debug('EPG cache cleared', tag: 'UnifiedEpg');
  }

  /// Clear cache for a specific source.
  void clearCacheForSource(EpgSourceConfig config) {
    final key = _getCacheKey(config);
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    _localStorage?.clearEpgData(key);
    moduleLogger.debug('EPG cache cleared for: $key', tag: 'UnifiedEpg');
  }

  /// Check if EPG data is cached for current configuration.
  bool hasCachedData() {
    final config = _currentConfig;
    if (config == null) return false;

    final key = _getCacheKey(config);
    return _cache.containsKey(key);
  }

  /// Get cached EPG data if available.
  EpgData? getCachedData() {
    final config = _currentConfig;
    if (config == null) return null;

    final key = _getCacheKey(config);
    return _cache[key];
  }

  // ============ Private Methods ============

  /// Fetch EPG from the configured source.
  Future<ApiResult<EpgData>> _fetchFromSource(
    EpgSourceConfig config, {
    required String cacheKey,
    XtreamCredentialsModel? credentials,
  }) async {
    try {
      switch (config.type) {
        case EpgSourceType.url:
          return _fetchFromUrlSource(config.epgUrl!, cacheKey);

        case EpgSourceType.xtreamCodes:
          if (credentials == null) {
            return ApiResult.failure(
              const ApiError(
                type: ApiErrorType.validation,
                message: 'Xtream credentials required',
              ),
            );
          }
          return _fetchFromXtreamSource(credentials, cacheKey);

        case EpgSourceType.none:
          return ApiResult.success(EpgData.empty());
      }
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error fetching EPG from source',
        tag: 'UnifiedEpg',
        error: e,
        stackTrace: stackTrace,
      );

      // Try to return cached data on failure
      final cached = _cache[cacheKey];
      if (cached != null) {
        moduleLogger.info(
          'Returning cached EPG data after fetch failure',
          tag: 'UnifiedEpg',
        );
        return ApiResult.success(cached);
      }

      // Try local storage as last resort
      final stored = _loadFromStorage(cacheKey);
      if (stored != null) {
        moduleLogger.info(
          'Returning stored EPG data after fetch failure',
          tag: 'UnifiedEpg',
        );
        return ApiResult.success(stored);
      }

      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Fetch from URL source.
  Future<ApiResult<EpgData>> _fetchFromUrlSource(
    String url,
    String cacheKey,
  ) async {
    moduleLogger.info('Fetching EPG from URL source', tag: 'UnifiedEpg');

    final result = await _urlProvider.fetchEpg(url);

    if (result.isSuccess) {
      _updateCache(cacheKey, result.data);
      _saveToStorage(cacheKey, result.data);
    } else {
      // Try to return cached data on failure
      final cached = _cache[cacheKey];
      if (cached != null) {
        moduleLogger.info(
          'URL fetch failed, returning cached data',
          tag: 'UnifiedEpg',
        );
        return ApiResult.success(cached);
      }

      // Try local storage as fallback
      final stored = _loadFromStorage(cacheKey);
      if (stored != null) {
        moduleLogger.info(
          'URL fetch failed, returning stored data',
          tag: 'UnifiedEpg',
        );
        return ApiResult.success(stored);
      }
    }

    return result;
  }

  /// Fetch from Xtream Codes source.
  Future<ApiResult<EpgData>> _fetchFromXtreamSource(
    XtreamCredentialsModel credentials,
    String cacheKey,
  ) async {
    if (_xtreamRepository == null) {
      return ApiResult.failure(
        const ApiError(
          type: ApiErrorType.validation,
          message: 'Xtream Codes repository not available',
        ),
      );
    }

    moduleLogger.info('Fetching EPG from Xtream source', tag: 'UnifiedEpg');

    final result = await _xtreamRepository.fetchFullXmltvEpg(credentials);

    if (result.isSuccess) {
      _updateCache(cacheKey, result.data);
      _saveToStorage(cacheKey, result.data);
    } else {
      // Try to return cached data on failure
      final cached = _cache[cacheKey];
      if (cached != null) {
        moduleLogger.info(
          'Xtream fetch failed, returning cached data',
          tag: 'UnifiedEpg',
        );
        return ApiResult.success(cached);
      }

      // Try local storage as fallback
      final stored = _loadFromStorage(cacheKey);
      if (stored != null) {
        moduleLogger.info(
          'Xtream fetch failed, returning stored data',
          tag: 'UnifiedEpg',
        );
        return ApiResult.success(stored);
      }
    }

    return result;
  }

  /// Generate cache key for a configuration.
  String _getCacheKey(EpgSourceConfig config) {
    switch (config.type) {
      case EpgSourceType.url:
        return EpgLocalStorage.generateSourceId(config.epgUrl!);
      case EpgSourceType.xtreamCodes:
        return EpgLocalStorage.generateXtreamSourceId(config.profileId!);
      case EpgSourceType.none:
        return 'none';
    }
  }

  /// Check if cache is valid based on refresh interval.
  bool _isCacheValid(String cacheKey, Duration maxAge) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < maxAge;
  }

  /// Update cache with new data.
  void _updateCache(String cacheKey, EpgData data) {
    _cache[cacheKey] = data;
    _cacheTimestamps[cacheKey] = DateTime.now();
    moduleLogger.debug(
      'EPG cache updated: $cacheKey (${data.channels.length} channels, ${data.totalPrograms} programs)',
      tag: 'UnifiedEpg',
    );
  }

  /// Save EPG data to local storage.
  void _saveToStorage(String cacheKey, EpgData data) {
    if (_localStorage == null || !_localStorage.isInitialized) return;

    try {
      _localStorage.saveEpgData(cacheKey, data);
    } catch (e) {
      moduleLogger.warning(
        'Failed to save EPG to storage: $e',
        tag: 'UnifiedEpg',
      );
    }
  }

  /// Load EPG data from local storage.
  EpgData? _loadFromStorage(String cacheKey) {
    if (_localStorage == null || !_localStorage.isInitialized) return null;

    try {
      return _localStorage.loadEpgData(cacheKey);
    } catch (e) {
      moduleLogger.warning(
        'Failed to load EPG from storage: $e',
        tag: 'UnifiedEpg',
      );
      return null;
    }
  }
}

// EpgRepositoryImpl
// Implements EPG repository using XMLTV file download only.
// All EPG data is obtained from the XMLTV file provided by Xtream Codes API.
// NO per-channel EPG API calls are made - this is by design per issue requirements.

import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import '../epg/epg_models.dart';
import '../epg/epg_service.dart';
import '../epg/xmltv_parser.dart';
import '../storage/xtream_local_storage.dart';
import 'xtream_repository_base.dart';

/// Extended timeout for full XML EPG download (5 minutes)
const Duration _xmlEpgTimeout = Duration(minutes: 5);

/// EPG repository implementation using XMLTV only.
///
/// This repository downloads and parses the complete XMLTV EPG file from
/// the Xtream Codes server. NO per-channel EPG API calls are made.
/// EPG data is cached in memory and persisted to local storage for offline access.
///
/// Key design decisions:
/// - All EPG data comes from XMLTV file only (no `get_short_epg` API calls)
/// - Data is cached in memory with configurable TTL from AppConfig
/// - Data is persisted to Hive storage for offline access
/// - Respects `xtreamEpgTtl` configuration for cache expiration
class EpgRepositoryImpl extends XtreamRepositoryBase implements EpgRepository {
  final Dio _dio;
  final XmltvParser _xmltvParser;
  final XtreamLocalStorage? _localStorage;
  final AppConfig _config;

  // Cache for full XMLTV EpgData (in-memory)
  final Map<String, EpgData> _fullEpgCache = {};
  final Map<String, DateTime> _fullEpgCacheTimestamps = {};

  EpgRepositoryImpl({
    Dio? dio,
    XmltvParser? xmltvParser,
    XtreamLocalStorage? localStorage,
    AppConfig? config,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: _xmlEpgTimeout,
              headers: {
                'Accept': '*/*',
                'User-Agent': 'WatchTheFlix/1.0',
              },
            )),
        _xmltvParser = xmltvParser ?? XmltvParser(),
        _localStorage = localStorage,
        _config = config ?? AppConfig();

  /// Get cache TTL from config
  Duration get _cacheDuration => _config.xtreamEpgTtl;

  String _getCacheKey(XtreamCredentialsModel credentials) =>
      '${credentials.baseUrl}_${credentials.username}';

  /// Get profile ID for local storage operations
  String _getProfileId(XtreamCredentialsModel credentials) =>
      '${credentials.username}@${Uri.parse(credentials.baseUrl).host}';

  bool _isFullEpgCacheValid(String cacheKey) {
    final timestamp = _fullEpgCacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  /// Build URL for full XMLTV EPG download.
  ///
  /// Xtream Codes API endpoint: /xmltv.php?username=...&password=...
  String _buildXmltvUrl(XtreamCredentialsModel credentials) {
    final encodedUsername = Uri.encodeComponent(credentials.username);
    final encodedPassword = Uri.encodeComponent(credentials.password);
    return '${credentials.baseUrl}/xmltv.php?'
        'username=$encodedUsername&password=$encodedPassword';
  }

  @override
  Future<ApiResult<EpgData>> fetchFullXmltvEpg(
    XtreamCredentialsModel credentials,
  ) async {
    final cacheKey = _getCacheKey(credentials);
    final profileId = _getProfileId(credentials);

    // Check in-memory cache first
    if (_fullEpgCache.containsKey(cacheKey) &&
        _isFullEpgCacheValid(cacheKey)) {
      moduleLogger.debug('Returning cached full EPG data', tag: 'EPG');
      return ApiResult.success(_fullEpgCache[cacheKey]!);
    }

    // Try to load from local storage if available
    final localEpgData = await _loadFromLocalStorage(profileId);
    if (localEpgData != null && localEpgData.isNotEmpty) {
      // Check if local data is still fresh (only if storage is available)
      if (_localStorage != null && _localStorage.isInitialized) {
        final syncStatus = _localStorage.getSyncStatus(profileId);
        if (syncStatus != null && !syncStatus.needsEpgRefresh(_cacheDuration)) {
          moduleLogger.debug('Returning EPG from local storage', tag: 'EPG');
          _fullEpgCache[cacheKey] = localEpgData;
          _fullEpgCacheTimestamps[cacheKey] = syncStatus.lastEpgSync ?? DateTime.now();
          return ApiResult.success(localEpgData);
        }
      }
    }

    try {
      final url = _buildXmltvUrl(credentials);
      moduleLogger.info('Downloading full XMLTV EPG from Xtream', tag: 'EPG');

      final response = await _dio
          .get<String>(
            url,
            options: Options(
              responseType: ResponseType.plain,
              receiveTimeout: _xmlEpgTimeout,
            ),
          )
          .timeout(_xmlEpgTimeout);

      final xmlContent = response.data;
      if (xmlContent == null || xmlContent.isEmpty) {
        moduleLogger.warning('Empty XMLTV response received', tag: 'EPG');
        // Return local data if available, otherwise empty
        return ApiResult.success(localEpgData ?? EpgData.empty());
      }

      // Validate response looks like XML
      if (!_xmltvParser.isValidXmltv(xmlContent)) {
        moduleLogger.warning(
          'Response does not appear to be valid XMLTV format',
          tag: 'EPG',
        );
        return ApiResult.success(localEpgData ?? EpgData.empty());
      }

      moduleLogger.debug(
        'Received XMLTV data: ${xmlContent.length} bytes',
        tag: 'EPG',
      );

      // Parse the XMLTV content
      final epgData = _xmltvParser.parse(xmlContent, sourceUrl: url);

      if (epgData.isEmpty) {
        moduleLogger.warning('Parsed EPG data is empty', tag: 'EPG');
      } else {
        moduleLogger.info(
          'Parsed full EPG: ${epgData.channels.length} channels, '
          '${epgData.totalPrograms} programs',
          tag: 'EPG',
        );

        // Save to local storage for offline access
        await _saveToLocalStorage(profileId, epgData);
      }

      // Update in-memory cache
      _fullEpgCache[cacheKey] = epgData;
      _fullEpgCacheTimestamps[cacheKey] = DateTime.now();

      return ApiResult.success(epgData);
    } on DioException catch (e) {
      moduleLogger.error(
        'Failed to download XMLTV EPG: ${e.message}',
        tag: 'EPG',
        error: e,
      );

      // Return cached/local data if available
      if (localEpgData != null && localEpgData.isNotEmpty) {
        moduleLogger.info('Returning cached EPG due to download failure', tag: 'EPG');
        return ApiResult.success(localEpgData);
      }

      // Check for specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ApiResult.failure(
          ApiError.timeout('EPG download timed out'),
        );
      }

      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return ApiResult.failure(
          ApiError.auth('Invalid credentials for EPG download'),
        );
      }

      return ApiResult.success(EpgData.empty());
    } on TimeoutException catch (_) {
      moduleLogger.warning('XMLTV EPG download timed out', tag: 'EPG');
      // Return cached/local data if available
      if (localEpgData != null && localEpgData.isNotEmpty) {
        return ApiResult.success(localEpgData);
      }
      return ApiResult.failure(ApiError.timeout('EPG download timed out'));
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception downloading XMLTV EPG',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      // Return cached/local data if available
      if (localEpgData != null && localEpgData.isNotEmpty) {
        return ApiResult.success(localEpgData);
      }
      return ApiResult.success(EpgData.empty());
    }
  }

  /// Load EPG data from local storage.
  Future<EpgData?> _loadFromLocalStorage(String profileId) async {
    if (_localStorage == null || !_localStorage.isInitialized) {
      return null;
    }

    try {
      final programsMap = _localStorage.getAllEpg(profileId);
      if (programsMap.isEmpty) {
        return null;
      }

      // Convert stored programs to EpgData format
      // Note: We don't have channels stored separately, so create from programs
      final channels = <String, EpgChannel>{};
      for (final channelId in programsMap.keys) {
        channels[channelId] = EpgChannel(id: channelId, name: channelId);
      }

      return EpgData(
        channels: channels,
        programs: programsMap,
        fetchedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to load EPG from local storage',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Save EPG data to local storage.
  Future<void> _saveToLocalStorage(String profileId, EpgData epgData) async {
    if (_localStorage == null || !_localStorage.isInitialized) {
      return;
    }

    try {
      // Flatten all programs into a single list
      final allPrograms = <EpgProgram>[];
      for (final programs in epgData.programs.values) {
        allPrograms.addAll(programs);
      }

      await _localStorage.saveEpgPrograms(profileId, allPrograms);

      // Update sync status
      final syncStatus = _localStorage.getOrCreateSyncStatus(profileId);
      syncStatus.updateEpgSync(allPrograms.length);
      await _localStorage.saveSyncStatus(syncStatus);

      moduleLogger.debug(
        'Saved ${allPrograms.length} EPG programs to local storage',
        tag: 'EPG',
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save EPG to local storage',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<ApiResult<List<EpgEntry>>> fetchChannelEpg(
    XtreamCredentialsModel credentials,
    String channelId, {
    int limit = 10,
  }) async {
    // XMLTV-only implementation: Get EPG from full XMLTV data
    // NO per-channel API calls are made
    try {
      moduleLogger.debug(
        'Fetching EPG for channel $channelId from XMLTV data',
        tag: 'EPG',
      );

      final result = await fetchFullXmltvEpg(credentials);
      if (result.isFailure) {
        return ApiResult.success([]);
      }

      final epgData = result.data;
      final programs = epgData.getChannelPrograms(channelId);

      // Filter to get current and upcoming programs, limited by limit
      final now = DateTime.now().toUtc();
      final relevantPrograms = programs
          .where((p) => p.endTime.isAfter(now))
          .take(limit)
          .map((p) => EpgEntry.fromEpgProgram(p))
          .toList();

      moduleLogger.debug(
        'Found ${relevantPrograms.length} EPG entries for channel $channelId',
        tag: 'EPG',
      );

      return ApiResult.success(relevantPrograms);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching channel EPG',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.success([]);
    }
  }

  @override
  Future<ApiResult<Map<String, List<EpgEntry>>>> fetchAllEpg(
    XtreamCredentialsModel credentials,
  ) async {
    // XMLTV-only implementation: Convert full EPG to legacy format
    // NO per-channel API calls are made
    try {
      moduleLogger.info('Fetching all EPG from XMLTV data', tag: 'EPG');

      final result = await fetchFullXmltvEpg(credentials);
      if (result.isFailure) {
        return ApiResult.success({});
      }

      final epgData = result.data;
      final now = DateTime.now().toUtc();
      final entries = <String, List<EpgEntry>>{};

      for (final entry in epgData.programs.entries) {
        final channelId = entry.key;
        final programs = entry.value;

        // Convert programs to EpgEntry format, filtering to current/upcoming
        final channelEntries = programs
            .where((p) => p.endTime.isAfter(now))
            .take(10) // Limit per channel
            .map((p) => EpgEntry.fromEpgProgram(p))
            .toList();

        if (channelEntries.isNotEmpty) {
          entries[channelId] = channelEntries;
        }
      }

      moduleLogger.info(
        'Converted EPG for ${entries.length} channels from XMLTV data',
        tag: 'EPG',
      );

      return ApiResult.success(entries);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching all EPG',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.success({});
    }
  }

  @override
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials) async {
    try {
      final cacheKey = _getCacheKey(credentials);
      final profileId = _getProfileId(credentials);

      // Clear in-memory cache
      _fullEpgCache.remove(cacheKey);
      _fullEpgCacheTimestamps.remove(cacheKey);

      // Clear local storage EPG
      if (_localStorage != null && _localStorage.isInitialized) {
        try {
          // Clear EPG from local storage by re-initializing with empty data
          await _localStorage.saveEpgPrograms(profileId, []);
        } catch (e) {
          moduleLogger.warning('Failed to clear local EPG storage: $e', tag: 'EPG');
        }
      }

      // Fetch fresh full XMLTV EPG data
      final result = await fetchFullXmltvEpg(credentials);
      if (result.isFailure) {
        return ApiResult.failure(result.error);
      }

      moduleLogger.info('EPG data refreshed via XMLTV', tag: 'EPG');
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get current program for a channel from full EPG data.
  Future<ApiResult<EpgProgram?>> getCurrentProgramFromFullEpg(
    XtreamCredentialsModel credentials,
    String channelId,
  ) async {
    final result = await fetchFullXmltvEpg(credentials);
    if (result.isFailure) {
      return ApiResult.failure(result.error);
    }

    final epgData = result.data;
    final program = epgData.getCurrentProgram(channelId);
    return ApiResult.success(program);
  }

  /// Get next program for a channel from full EPG data.
  Future<ApiResult<EpgProgram?>> getNextProgramFromFullEpg(
    XtreamCredentialsModel credentials,
    String channelId,
  ) async {
    final result = await fetchFullXmltvEpg(credentials);
    if (result.isFailure) {
      return ApiResult.failure(result.error);
    }

    final epgData = result.data;
    final program = epgData.getNextProgram(channelId);
    return ApiResult.success(program);
  }

  /// Get daily schedule for a channel from full EPG data.
  Future<ApiResult<List<EpgProgram>>> getDailySchedule(
    XtreamCredentialsModel credentials,
    String channelId,
    DateTime date,
  ) async {
    final result = await fetchFullXmltvEpg(credentials);
    if (result.isFailure) {
      return ApiResult.failure(result.error);
    }

    final epgData = result.data;
    final schedule = epgData.getDailySchedule(channelId, date);
    return ApiResult.success(schedule);
  }

  /// Clear EPG cache for a specific credential.
  void clearCache(XtreamCredentialsModel credentials) {
    final cacheKey = _getCacheKey(credentials);
    _fullEpgCache.remove(cacheKey);
    _fullEpgCacheTimestamps.remove(cacheKey);
    moduleLogger.debug('EPG cache cleared for $cacheKey', tag: 'EPG');
  }

  /// Clear all EPG caches.
  void clearAllCaches() {
    _fullEpgCache.clear();
    _fullEpgCacheTimestamps.clear();
    moduleLogger.debug('All EPG caches cleared', tag: 'EPG');
  }

  /// Check if EPG data is cached for credentials.
  bool hasCachedEpg(XtreamCredentialsModel credentials) {
    final cacheKey = _getCacheKey(credentials);
    return _fullEpgCache.containsKey(cacheKey) &&
        _isFullEpgCacheValid(cacheKey);
  }

  /// Check if EPG needs refresh based on TTL.
  bool needsRefresh(XtreamCredentialsModel credentials) {
    final cacheKey = _getCacheKey(credentials);
    if (!_fullEpgCache.containsKey(cacheKey)) return true;
    return !_isFullEpgCacheValid(cacheKey);
  }
}

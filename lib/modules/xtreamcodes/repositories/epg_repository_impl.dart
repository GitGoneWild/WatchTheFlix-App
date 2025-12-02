// EpgRepositoryImpl
// Implements EPG repository using Dio HTTP client.
// Supports both full XMLTV EPG download and per-channel short EPG API.

import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import '../epg/epg_models.dart';
import '../epg/epg_service.dart';
import '../epg/xmltv_parser.dart';
import 'xtream_repository_base.dart';

/// Default timeout for short EPG requests (15 seconds)
const Duration _epgTimeout = Duration(seconds: 15);

/// Extended timeout for full XML EPG download (5 minutes)
const Duration _xmlEpgTimeout = Duration(minutes: 5);

/// Number of channels to process in each EPG batch request
const int _epgBatchSize = 50;

/// Delay between EPG batch requests to avoid rate limiting
const Duration _epgBatchDelay = Duration(milliseconds: 100);

/// EPG repository implementation with full XMLTV support.
///
/// This repository provides two methods for EPG retrieval:
/// 1. Full XML EPG - Downloads the complete XMLTV file from `/xmltv.php`
/// 2. Short EPG - Uses the per-channel API for quick lookups
class EpgRepositoryImpl extends XtreamRepositoryBase implements EpgRepository {
  final Dio _dio;
  final XmltvParser _xmltvParser;

  // Cache for parsed EpgEntry data (legacy format)
  final Map<String, Map<String, List<EpgEntry>>> _epgCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache for full XMLTV EpgData
  final Map<String, EpgData> _fullEpgCache = {};
  final Map<String, DateTime> _fullEpgCacheTimestamps = {};

  /// Default cache duration for EPG (6 hours - EPG data changes frequently)
  static const Duration _cacheDuration = Duration(hours: 6);

  EpgRepositoryImpl({Dio? dio, XmltvParser? xmltvParser})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _epgTimeout,
              receiveTimeout: _xmlEpgTimeout,
              headers: {
                'Accept': '*/*',
                'User-Agent': 'WatchTheFlix/1.0',
              },
            )),
        _xmltvParser = xmltvParser ?? XmltvParser();

  String _getCacheKey(XtreamCredentialsModel credentials) =>
      '${credentials.baseUrl}_${credentials.username}';

  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

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

  /// Download and parse the full XMLTV EPG file.
  ///
  /// This is the preferred method for getting complete EPG data as it:
  /// - Downloads all EPG data in a single request
  /// - Is more efficient than per-channel API calls
  /// - Provides complete program information
  Future<ApiResult<EpgData>> fetchFullXmltvEpg(
    XtreamCredentialsModel credentials,
  ) async {
    final cacheKey = _getCacheKey(credentials);

    // Check cache first
    if (_fullEpgCache.containsKey(cacheKey) &&
        _isFullEpgCacheValid(cacheKey)) {
      moduleLogger.debug('Returning cached full EPG data', tag: 'EPG');
      return ApiResult.success(_fullEpgCache[cacheKey]!);
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
        return ApiResult.success(EpgData.empty());
      }

      // Validate response looks like XML
      if (!_xmltvParser.isValidXmltv(xmlContent)) {
        moduleLogger.warning(
          'Response does not appear to be valid XMLTV format',
          tag: 'EPG',
        );
        return ApiResult.success(EpgData.empty());
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
      }

      // Update cache
      _fullEpgCache[cacheKey] = epgData;
      _fullEpgCacheTimestamps[cacheKey] = DateTime.now();

      return ApiResult.success(epgData);
    } on DioException catch (e) {
      moduleLogger.error(
        'Failed to download XMLTV EPG: ${e.message}',
        tag: 'EPG',
        error: e,
      );

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
      return ApiResult.failure(ApiError.timeout('EPG download timed out'));
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception downloading XMLTV EPG',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.success(EpgData.empty());
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

  @override
  Future<ApiResult<List<EpgEntry>>> fetchChannelEpg(
    XtreamCredentialsModel credentials,
    String channelId, {
    int limit = 10,
  }) async {
    try {
      moduleLogger.info('Fetching EPG for channel $channelId', tag: 'EPG');

      final url =
          '${buildUrl(credentials, 'get_short_epg')}&stream_id=$channelId&limit=$limit';
      final response =
          await _dio.get<Map<String, dynamic>>(url).timeout(_epgTimeout);

      if (response.data == null) {
        return ApiResult.success([]);
      }

      final data = response.data!;
      final epgListings = data['epg_listings'] as List<dynamic>? ?? [];

      final entries = epgListings.map((json) {
        return EpgEntry.fromJson(json as Map<String, dynamic>);
      }).toList();

      moduleLogger.info(
        'Fetched ${entries.length} EPG entries for channel $channelId',
        tag: 'EPG',
      );

      return ApiResult.success(entries);
    } on DioException catch (e) {
      moduleLogger.error(
        'Failed to fetch channel EPG',
        tag: 'EPG',
        error: e,
      );
      // Return empty list on failure - EPG is not critical
      return ApiResult.success([]);
    } on TimeoutException catch (_) {
      moduleLogger.warning('EPG request timed out for channel $channelId', tag: 'EPG');
      return ApiResult.success([]);
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
    try {
      final cacheKey = _getCacheKey(credentials);

      // Check cache
      if (_epgCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        return ApiResult.success(_epgCache[cacheKey]!);
      }

      moduleLogger.info('Fetching all EPG data', tag: 'EPG');

      // First, get all live channels to determine which EPG to fetch
      final channelsUrl = buildUrl(credentials, 'get_live_streams');
      final channelsResponse =
          await _dio.get<dynamic>(channelsUrl).timeout(_epgTimeout);

      final channelsList = safeParseList(channelsResponse.data);
      if (channelsList.isEmpty) {
        moduleLogger.warning('No channels found for EPG loading', tag: 'EPG');
        return ApiResult.success({});
      }

      final channelIds = channelsList
          .map((c) => c['stream_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      moduleLogger.info(
        'Fetching EPG for ${channelIds.length} channels',
        tag: 'EPG',
      );

      final result = <String, List<EpgEntry>>{};
      var successCount = 0;
      var failCount = 0;

      // Process in batches to avoid overwhelming the server
      for (var i = 0; i < channelIds.length; i += _epgBatchSize) {
        final batch = channelIds.skip(i).take(_epgBatchSize).toList();

        final futures = batch.map((channelId) async {
          try {
            final epgResult = await fetchChannelEpg(
              credentials,
              channelId,
              limit: 10,
            );

            if (epgResult.isSuccess && epgResult.data.isNotEmpty) {
              result[channelId] = epgResult.data;
              successCount++;
            }
          } catch (_) {
            failCount++;
          }
        });

        await Future.wait(futures);

        // Small delay between batches
        if (i + _epgBatchSize < channelIds.length) {
          await Future.delayed(_epgBatchDelay);
        }
      }

      // Update cache
      _epgCache[cacheKey] = result;
      _cacheTimestamps[cacheKey] = DateTime.now();

      moduleLogger.info(
        'EPG fetch completed: $successCount channels with EPG, '
        '$failCount failures out of ${channelIds.length} channels',
        tag: 'EPG',
      );

      return ApiResult.success(result);
    } on TimeoutException catch (_) {
      moduleLogger.warning('EPG batch fetch timed out', tag: 'EPG');
      return ApiResult.success({});
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching all EPG',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty map on failure - EPG is optional
      return ApiResult.success({});
    }
  }

  @override
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials) async {
    try {
      final cacheKey = _getCacheKey(credentials);

      // Clear all caches
      _epgCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      _fullEpgCache.remove(cacheKey);
      _fullEpgCacheTimestamps.remove(cacheKey);

      // Fetch fresh full XMLTV EPG data (preferred method)
      final result = await fetchFullXmltvEpg(credentials);
      if (result.isFailure) {
        // Fall back to per-channel API if XML fails
        moduleLogger.warning(
          'Full EPG refresh failed, falling back to per-channel API',
          tag: 'EPG',
        );
        final fallbackResult = await fetchAllEpg(credentials);
        if (fallbackResult.isFailure) {
          return ApiResult.failure(fallbackResult.error);
        }
      }

      moduleLogger.info('EPG data refreshed', tag: 'EPG');
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Clear all EPG caches for a specific credential.
  void clearCache(XtreamCredentialsModel credentials) {
    final cacheKey = _getCacheKey(credentials);
    _epgCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    _fullEpgCache.remove(cacheKey);
    _fullEpgCacheTimestamps.remove(cacheKey);
    moduleLogger.debug('EPG cache cleared for $cacheKey', tag: 'EPG');
  }

  /// Clear all EPG caches.
  void clearAllCaches() {
    _epgCache.clear();
    _cacheTimestamps.clear();
    _fullEpgCache.clear();
    _fullEpgCacheTimestamps.clear();
    moduleLogger.debug('All EPG caches cleared', tag: 'EPG');
  }

  /// Check if EPG data is cached for credentials.
  bool hasCachedEpg(XtreamCredentialsModel credentials) {
    final cacheKey = _getCacheKey(credentials);
    return (_fullEpgCache.containsKey(cacheKey) &&
            _isFullEpgCacheValid(cacheKey)) ||
        (_epgCache.containsKey(cacheKey) && _isCacheValid(cacheKey));
  }
}

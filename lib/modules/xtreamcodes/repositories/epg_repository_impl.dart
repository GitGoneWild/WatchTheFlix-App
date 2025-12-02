// EpgRepositoryImpl
// Implements EPG repository using Dio HTTP client.

import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import '../epg/epg_service.dart';
import 'xtream_repository_base.dart';

/// Default timeout for EPG requests (15 seconds)
const Duration _epgTimeout = Duration(seconds: 15);

/// Extended timeout for batch EPG fetch (3 minutes)
const Duration _epgBatchTimeout = Duration(minutes: 3);

/// Number of channels to process in each EPG batch request
const int _epgBatchSize = 50;

/// Delay between EPG batch requests to avoid rate limiting
const Duration _epgBatchDelay = Duration(milliseconds: 100);

/// EPG repository implementation
class EpgRepositoryImpl extends XtreamRepositoryBase implements EpgRepository {
  final Dio _dio;

  // Cache for EPG data
  final Map<String, Map<String, List<EpgEntry>>> _epgCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Default cache duration for EPG (6 hours - EPG data changes frequently)
  static const Duration _cacheDuration = Duration(hours: 6);

  EpgRepositoryImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _epgTimeout,
              receiveTimeout: _epgTimeout,
              headers: {
                'Accept': '*/*',
                'User-Agent': 'WatchTheFlix/1.0',
              },
            ));

  String _getCacheKey(XtreamCredentialsModel credentials) =>
      '${credentials.baseUrl}_${credentials.username}';

  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
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

      // Clear cache
      _epgCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);

      // Fetch fresh EPG data
      final result = await fetchAllEpg(credentials);
      if (result.isFailure) {
        return ApiResult.failure(result.error);
      }

      moduleLogger.info('EPG data refreshed', tag: 'EPG');
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

// LiveTvRepositoryImpl
// Implements Live TV repository using Dio HTTP client.

import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import '../livetv/livetv_service.dart';
import '../mappers/xtream_to_domain_mappers.dart';
import '../epg/epg_service.dart';
import 'xtream_repository_base.dart';

/// Default timeout for live TV requests (30 seconds)
const Duration _liveTvTimeout = Duration(seconds: 30);

/// Extended timeout for large data requests (60 seconds)
const Duration _extendedTimeout = Duration(seconds: 60);

/// Live TV repository implementation
class LiveTvRepositoryImpl extends XtreamRepositoryBase
    implements LiveTvRepository {
  final Dio _dio;
  final EpgRepository? _epgRepository;

  // Cache for categories and channels
  final Map<String, List<DomainCategory>> _categoryCache = {};
  final Map<String, List<DomainChannel>> _channelCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Default cache duration (1 hour)
  static const Duration _cacheDuration = Duration(hours: 1);

  LiveTvRepositoryImpl({Dio? dio, EpgRepository? epgRepository})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _liveTvTimeout,
              receiveTimeout: _extendedTimeout,
              headers: {
                'Accept': '*/*',
                'User-Agent': 'WatchTheFlix/1.0',
              },
            )),
        _epgRepository = epgRepository;

  String _getCacheKey(XtreamCredentialsModel credentials) =>
      '${credentials.baseUrl}_${credentials.username}';

  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  @override
  Future<ApiResult<List<DomainCategory>>> fetchCategories(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      final cacheKey = _getCacheKey(credentials);

      // Check cache
      if (_categoryCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        return ApiResult.success(_categoryCache[cacheKey]!);
      }

      moduleLogger.info('Fetching live TV categories', tag: 'LiveTV');

      final url = buildUrl(credentials, 'get_live_categories');
      final response = await _dio.get<dynamic>(url).timeout(_liveTvTimeout);

      final dataList = safeParseList(response.data);
      final categories = dataList
          .map((json) => XtreamToDomainMappers.mapCategory(json))
          .toList();

      // Update cache
      _categoryCache[cacheKey] = categories;
      _cacheTimestamps[cacheKey] = DateTime.now();

      moduleLogger.info(
        'Fetched ${categories.length} live TV categories',
        tag: 'LiveTV',
      );

      return ApiResult.success(categories);
    } on DioException catch (e) {
      moduleLogger.error('Failed to fetch live categories', tag: 'LiveTV', error: e);
      return ApiResult.failure(handleApiError(e, 'Fetch live categories'));
    } on TimeoutException catch (_) {
      return ApiResult.failure(
        ApiError.timeout('Fetching live categories timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching live categories',
        tag: 'LiveTV',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<DomainChannel>>> fetchChannels(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) async {
    try {
      final cacheKey = _getCacheKey(credentials);
      final fullCacheKey = '$cacheKey${categoryId ?? ''}';

      // Check cache
      if (_channelCache.containsKey(fullCacheKey) && _isCacheValid(cacheKey)) {
        return ApiResult.success(_channelCache[fullCacheKey]!);
      }

      moduleLogger.info(
        'Fetching live TV channels${categoryId != null ? ' for category $categoryId' : ''}',
        tag: 'LiveTV',
      );

      String url = buildUrl(credentials, 'get_live_streams');
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }

      final response = await _dio.get<dynamic>(url).timeout(_extendedTimeout);

      final dataList = safeParseList(response.data);
      final channels = dataList.map((json) {
        final streamId = json['stream_id']?.toString() ?? '';
        final streamUrl = buildLiveStreamUrl(credentials, streamId);
        return XtreamToDomainMappers.mapChannel(json, streamUrl);
      }).toList();

      // Update cache
      _channelCache[fullCacheKey] = channels;
      _cacheTimestamps[cacheKey] = DateTime.now();

      moduleLogger.info(
        'Fetched ${channels.length} live TV channels',
        tag: 'LiveTV',
      );

      return ApiResult.success(channels);
    } on DioException catch (e) {
      moduleLogger.error('Failed to fetch live channels', tag: 'LiveTV', error: e);
      return ApiResult.failure(handleApiError(e, 'Fetch live channels'));
    } on TimeoutException catch (_) {
      return ApiResult.failure(
        ApiError.timeout('Fetching live channels timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching live channels',
        tag: 'LiveTV',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<DomainChannel>>> fetchChannelsWithEpg(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) async {
    // First fetch channels
    final channelsResult = await fetchChannels(
      credentials,
      categoryId: categoryId,
    );

    if (channelsResult.isFailure) {
      return channelsResult;
    }

    final channels = channelsResult.data;

    // If no EPG repository, return channels without EPG
    if (_epgRepository == null) {
      return ApiResult.success(channels);
    }

    try {
      // Fetch EPG data
      final epgResult = await _epgRepository.fetchAllEpg(credentials);

      if (epgResult.isFailure) {
        // Return channels without EPG if EPG fetch fails
        moduleLogger.warning(
          'EPG fetch failed: ${epgResult.error.message}, returning channels without EPG',
          tag: 'LiveTV',
        );
        return ApiResult.success(channels);
      }

      final epgData = epgResult.data;

      // Attach EPG info to channels
      final channelsWithEpg = channels.map((channel) {
        final epgList = epgData[channel.id] ?? [];
        EpgEntry? currentProgram;
        EpgEntry? nextProgram;

        for (final entry in epgList) {
          if (entry.isCurrentlyAiring) {
            currentProgram = entry;
            break;
          }
        }

        if (currentProgram != null) {
          for (final entry in epgList) {
            if (entry.startTime.isAfter(currentProgram.endTime)) {
              nextProgram = entry;
              break;
            }
          }

          return channel.copyWith(
            epgInfo: EpgInfo(
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

      return ApiResult.success(channelsWithEpg);
    } catch (e) {
      moduleLogger.warning('EPG integration failed: $e', tag: 'LiveTV');
      return ApiResult.success(channels);
    }
  }

  @override
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials) async {
    try {
      final cacheKey = _getCacheKey(credentials);

      // Clear cache
      _categoryCache.remove(cacheKey);
      _channelCache.removeWhere((key, _) => key.startsWith(cacheKey));
      _cacheTimestamps.remove(cacheKey);

      // Refresh categories
      final categoriesResult = await fetchCategories(credentials);
      if (categoriesResult.isFailure) {
        return ApiResult.failure(categoriesResult.error);
      }

      // Refresh channels
      final channelsResult = await fetchChannels(credentials);
      if (channelsResult.isFailure) {
        return ApiResult.failure(channelsResult.error);
      }

      moduleLogger.info('Live TV data refreshed', tag: 'LiveTV');
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

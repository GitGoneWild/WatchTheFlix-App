// SeriesRepositoryImpl
// Implements Series repository using Dio HTTP client.

import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import '../series/series_service.dart';
import '../mappers/xtream_to_domain_mappers.dart';
import 'xtream_repository_base.dart';

/// Default timeout for series requests (30 seconds)
const Duration _seriesTimeout = Duration(seconds: 30);

/// Extended timeout for large data requests (60 seconds)
const Duration _extendedTimeout = Duration(seconds: 60);

/// Series repository implementation
class SeriesRepositoryImpl extends XtreamRepositoryBase
    implements SeriesRepository {
  SeriesRepositoryImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _seriesTimeout,
              receiveTimeout: _extendedTimeout,
              headers: {
                'Accept': '*/*',
                'User-Agent': 'WatchTheFlix/1.0',
              },
            ));
  final Dio _dio;

  // Cache for categories and series
  final Map<String, List<DomainCategory>> _categoryCache = {};
  final Map<String, List<DomainSeries>> _seriesCache = {};
  final Map<String, DomainSeries> _seriesDetailsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Default cache duration (1 hour)
  static const Duration _cacheDuration = Duration(hours: 1);

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

      moduleLogger.info('Fetching series categories', tag: 'Series');

      final url = buildUrl(credentials, 'get_series_categories');
      final response = await _dio.get<dynamic>(url).timeout(_seriesTimeout);

      final dataList = safeParseList(response.data);
      final categories = dataList
          .map((json) => XtreamToDomainMappers.mapCategory(json))
          .toList();

      // Update cache
      _categoryCache[cacheKey] = categories;
      _cacheTimestamps[cacheKey] = DateTime.now();

      moduleLogger.info(
        'Fetched ${categories.length} series categories',
        tag: 'Series',
      );

      return ApiResult.success(categories);
    } on DioException catch (e) {
      moduleLogger.error('Failed to fetch series categories',
          tag: 'Series', error: e);
      return ApiResult.failure(handleApiError(e, 'Fetch series categories'));
    } on TimeoutException catch (_) {
      return ApiResult.failure(
        ApiError.timeout('Fetching series categories timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching series categories',
        tag: 'Series',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<DomainSeries>>> fetchSeries(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) async {
    try {
      final cacheKey = _getCacheKey(credentials);
      final fullCacheKey = '$cacheKey${categoryId ?? ''}';

      // Check cache
      if (_seriesCache.containsKey(fullCacheKey) && _isCacheValid(cacheKey)) {
        return ApiResult.success(_seriesCache[fullCacheKey]!);
      }

      moduleLogger.info(
        'Fetching series${categoryId != null ? ' for category $categoryId' : ''}',
        tag: 'Series',
      );

      String url = buildUrl(credentials, 'get_series');
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }

      final response = await _dio.get<dynamic>(url).timeout(_extendedTimeout);

      final dataList = safeParseList(response.data);
      final series = dataList
          .map((json) => XtreamToDomainMappers.mapSeries(json))
          .toList();

      // Update cache
      _seriesCache[fullCacheKey] = series;
      _cacheTimestamps[cacheKey] = DateTime.now();

      moduleLogger.info('Fetched ${series.length} series', tag: 'Series');

      return ApiResult.success(series);
    } on DioException catch (e) {
      moduleLogger.error('Failed to fetch series', tag: 'Series', error: e);
      return ApiResult.failure(handleApiError(e, 'Fetch series'));
    } on TimeoutException catch (_) {
      return ApiResult.failure(
        ApiError.timeout('Fetching series timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching series',
        tag: 'Series',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<DomainSeries>> fetchSeriesDetails(
    XtreamCredentialsModel credentials,
    String seriesId,
  ) async {
    try {
      final cacheKey = _getCacheKey(credentials);
      final detailsCacheKey = '${cacheKey}_$seriesId';

      // Check cache
      if (_seriesDetailsCache.containsKey(detailsCacheKey) &&
          _isCacheValid(cacheKey)) {
        return ApiResult.success(_seriesDetailsCache[detailsCacheKey]!);
      }

      moduleLogger.info('Fetching series details for $seriesId', tag: 'Series');

      final url =
          '${buildUrl(credentials, 'get_series_info')}&series_id=$seriesId';
      final response =
          await _dio.get<Map<String, dynamic>>(url).timeout(_seriesTimeout);

      if (response.data == null) {
        return ApiResult.failure(
          const ApiError(
              type: ApiErrorType.notFound, message: 'Series not found'),
        );
      }

      final series = XtreamToDomainMappers.mapSeriesWithEpisodes(
        response.data!,
        (streamId, extension) => buildSeriesStreamUrl(
          credentials,
          streamId,
          extension: extension,
        ),
      );

      // Update cache
      _seriesDetailsCache[detailsCacheKey] = series;

      moduleLogger.info('Fetched series details for $seriesId', tag: 'Series');

      return ApiResult.success(series);
    } on DioException catch (e) {
      moduleLogger.error('Failed to fetch series details',
          tag: 'Series', error: e);
      return ApiResult.failure(handleApiError(e, 'Fetch series details'));
    } on TimeoutException catch (_) {
      return ApiResult.failure(
        ApiError.timeout('Fetching series details timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching series details',
        tag: 'Series',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials) async {
    try {
      final cacheKey = _getCacheKey(credentials);

      // Clear cache
      _categoryCache.remove(cacheKey);
      _seriesCache.removeWhere((key, _) => key.startsWith(cacheKey));
      _seriesDetailsCache.removeWhere((key, _) => key.startsWith(cacheKey));
      _cacheTimestamps.remove(cacheKey);

      // Refresh categories
      final categoriesResult = await fetchCategories(credentials);
      if (categoriesResult.isFailure) {
        return ApiResult.failure(categoriesResult.error);
      }

      // Refresh series
      final seriesResult = await fetchSeries(credentials);
      if (seriesResult.isFailure) {
        return ApiResult.failure(seriesResult.error);
      }

      moduleLogger.info('Series data refreshed', tag: 'Series');
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

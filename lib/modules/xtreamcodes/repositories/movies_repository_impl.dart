// MoviesRepositoryImpl
// Implements Movies repository using Dio HTTP client.

import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import '../movies/movies_service.dart';
import '../mappers/xtream_to_domain_mappers.dart';
import 'xtream_repository_base.dart';

/// Default timeout for movie requests (30 seconds)
const Duration _moviesTimeout = Duration(seconds: 30);

/// Extended timeout for large data requests (60 seconds)
const Duration _extendedTimeout = Duration(seconds: 60);

/// Movies repository implementation
class MoviesRepositoryImpl extends XtreamRepositoryBase
    implements MoviesRepository {
  MoviesRepositoryImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _moviesTimeout,
              receiveTimeout: _extendedTimeout,
              headers: {
                'Accept': '*/*',
                'User-Agent': 'WatchTheFlix/1.0',
              },
            ));
  final Dio _dio;

  // Cache for categories and movies
  final Map<String, List<DomainCategory>> _categoryCache = {};
  final Map<String, List<VodItem>> _moviesCache = {};
  final Map<String, VodItem> _movieDetailsCache = {};
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

      moduleLogger.info('Fetching movie categories', tag: 'Movies');

      final url = buildUrl(credentials, 'get_vod_categories');
      final response = await _dio.get<dynamic>(url).timeout(_moviesTimeout);

      final dataList = safeParseList(response.data);
      final categories = dataList
          .map((json) => XtreamToDomainMappers.mapCategory(json))
          .toList();

      // Update cache
      _categoryCache[cacheKey] = categories;
      _cacheTimestamps[cacheKey] = DateTime.now();

      moduleLogger.info(
        'Fetched ${categories.length} movie categories',
        tag: 'Movies',
      );

      return ApiResult.success(categories);
    } on DioException catch (e) {
      moduleLogger.error('Failed to fetch movie categories',
          tag: 'Movies', error: e);
      return ApiResult.failure(handleApiError(e, 'Fetch movie categories'));
    } on TimeoutException catch (_) {
      return ApiResult.failure(
        ApiError.timeout('Fetching movie categories timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching movie categories',
        tag: 'Movies',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<VodItem>>> fetchMovies(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) async {
    try {
      final cacheKey = _getCacheKey(credentials);
      final fullCacheKey = '$cacheKey${categoryId ?? ''}';

      // Check cache
      if (_moviesCache.containsKey(fullCacheKey) && _isCacheValid(cacheKey)) {
        return ApiResult.success(_moviesCache[fullCacheKey]!);
      }

      moduleLogger.info(
        'Fetching movies${categoryId != null ? ' for category $categoryId' : ''}',
        tag: 'Movies',
      );

      String url = buildUrl(credentials, 'get_vod_streams');
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }

      final response = await _dio.get<dynamic>(url).timeout(_extendedTimeout);

      final dataList = safeParseList(response.data);
      final movies = dataList.map((json) {
        final streamId = json['stream_id']?.toString() ?? '';
        final extension = (json['container_extension'] ?? 'mp4').toString();
        final streamUrl = buildMovieStreamUrl(
          credentials,
          streamId,
          extension: extension,
        );
        return XtreamToDomainMappers.mapMovie(json, streamUrl);
      }).toList();

      // Update cache
      _moviesCache[fullCacheKey] = movies;
      _cacheTimestamps[cacheKey] = DateTime.now();

      moduleLogger.info('Fetched ${movies.length} movies', tag: 'Movies');

      return ApiResult.success(movies);
    } on DioException catch (e) {
      moduleLogger.error('Failed to fetch movies', tag: 'Movies', error: e);
      return ApiResult.failure(handleApiError(e, 'Fetch movies'));
    } on TimeoutException catch (_) {
      return ApiResult.failure(
        ApiError.timeout('Fetching movies timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching movies',
        tag: 'Movies',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<VodItem>> fetchMovieDetails(
    XtreamCredentialsModel credentials,
    String movieId,
  ) async {
    try {
      final cacheKey = _getCacheKey(credentials);
      final detailsCacheKey = '${cacheKey}_$movieId';

      // Check cache
      if (_movieDetailsCache.containsKey(detailsCacheKey) &&
          _isCacheValid(cacheKey)) {
        return ApiResult.success(_movieDetailsCache[detailsCacheKey]!);
      }

      moduleLogger.info('Fetching movie details for $movieId', tag: 'Movies');

      final url = '${buildUrl(credentials, 'get_vod_info')}&vod_id=$movieId';
      final response =
          await _dio.get<Map<String, dynamic>>(url).timeout(_moviesTimeout);

      if (response.data == null) {
        return ApiResult.failure(
          const ApiError(
              type: ApiErrorType.notFound, message: 'Movie not found'),
        );
      }

      final data = response.data!;
      final info = data['info'] as Map<String, dynamic>? ?? {};
      final movieData = data['movie_data'] as Map<String, dynamic>? ?? {};

      // Merge info and movie_data
      final mergedData = <String, dynamic>{
        ...info,
        ...movieData,
        'stream_id': movieId,
      };

      final streamId = mergedData['stream_id']?.toString() ?? movieId;
      final extension = (mergedData['container_extension'] ?? 'mp4').toString();
      final streamUrl = buildMovieStreamUrl(
        credentials,
        streamId,
        extension: extension,
      );

      final movie = XtreamToDomainMappers.mapMovie(mergedData, streamUrl);

      // Update cache
      _movieDetailsCache[detailsCacheKey] = movie;

      moduleLogger.info('Fetched movie details for $movieId', tag: 'Movies');

      return ApiResult.success(movie);
    } on DioException catch (e) {
      moduleLogger.error('Failed to fetch movie details',
          tag: 'Movies', error: e);
      return ApiResult.failure(handleApiError(e, 'Fetch movie details'));
    } on TimeoutException catch (_) {
      return ApiResult.failure(
        ApiError.timeout('Fetching movie details timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching movie details',
        tag: 'Movies',
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
      _moviesCache.removeWhere((key, _) => key.startsWith(cacheKey));
      _movieDetailsCache.removeWhere((key, _) => key.startsWith(cacheKey));
      _cacheTimestamps.remove(cacheKey);

      // Refresh categories
      final categoriesResult = await fetchCategories(credentials);
      if (categoriesResult.isFailure) {
        return ApiResult.failure(categoriesResult.error);
      }

      // Refresh movies
      final moviesResult = await fetchMovies(credentials);
      if (moviesResult.isFailure) {
        return ApiResult.failure(moviesResult.error);
      }

      moduleLogger.info('Movies data refreshed', tag: 'Movies');
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

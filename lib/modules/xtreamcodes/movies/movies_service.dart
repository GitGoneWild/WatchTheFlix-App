// MoviesService
// Service for managing VOD movies, categories, and streaming.

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';

/// Movies service interface
abstract class IMoviesService {
  /// Get all movie categories
  Future<ApiResult<List<DomainCategory>>> getCategories(
    XtreamCredentialsModel credentials,
  );

  /// Get all movies
  Future<ApiResult<List<VodItem>>> getMovies(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  });

  /// Get movie details
  Future<ApiResult<VodItem>> getMovieDetails(
    XtreamCredentialsModel credentials,
    String movieId,
  );

  /// Get stream URL for a movie
  String getStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String extension,
  });

  /// Refresh movies data
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials);
}

/// Movies service implementation
class MoviesService implements IMoviesService {
  MoviesService({required MoviesRepository repository})
      : _repository = repository;
  final MoviesRepository _repository;

  @override
  Future<ApiResult<List<DomainCategory>>> getCategories(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      moduleLogger.info('Fetching movie categories', tag: 'Movies');
      return await _repository.fetchCategories(credentials);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch movie categories',
        tag: 'Movies',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<VodItem>>> getMovies(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) async {
    try {
      moduleLogger.info(
        'Fetching movies${categoryId != null ? ' for category $categoryId' : ''}',
        tag: 'Movies',
      );
      return await _repository.fetchMovies(credentials, categoryId: categoryId);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch movies',
        tag: 'Movies',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<VodItem>> getMovieDetails(
    XtreamCredentialsModel credentials,
    String movieId,
  ) async {
    try {
      moduleLogger.info('Fetching movie details for $movieId', tag: 'Movies');
      return await _repository.fetchMovieDetails(credentials, movieId);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch movie details',
        tag: 'Movies',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  String getStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String extension = 'mp4',
  }) {
    return '${credentials.baseUrl}/movie/${credentials.username}/${credentials.password}/$streamId.$extension';
  }

  @override
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials) async {
    try {
      moduleLogger.info('Refreshing movies data', tag: 'Movies');
      return await _repository.refresh(credentials);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

/// Movies repository interface
abstract class MoviesRepository {
  /// Fetch movie categories from API
  Future<ApiResult<List<DomainCategory>>> fetchCategories(
    XtreamCredentialsModel credentials,
  );

  /// Fetch movies from API
  Future<ApiResult<List<VodItem>>> fetchMovies(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  });

  /// Fetch movie details from API
  Future<ApiResult<VodItem>> fetchMovieDetails(
    XtreamCredentialsModel credentials,
    String movieId,
  );

  /// Refresh cached data
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials);
}

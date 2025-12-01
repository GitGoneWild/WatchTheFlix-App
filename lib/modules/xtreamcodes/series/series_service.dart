// SeriesService
// Service for managing TV series, seasons, episodes, and streaming.

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';

/// Series service interface
abstract class ISeriesService {
  /// Get all series categories
  Future<ApiResult<List<DomainCategory>>> getCategories(
    XtreamCredentialsModel credentials,
  );

  /// Get all series
  Future<ApiResult<List<DomainSeries>>> getSeries(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  });

  /// Get series details with seasons and episodes
  Future<ApiResult<DomainSeries>> getSeriesDetails(
    XtreamCredentialsModel credentials,
    String seriesId,
  );

  /// Get stream URL for an episode
  String getStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String extension,
  });

  /// Refresh series data
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials);
}

/// Series service implementation
class SeriesService implements ISeriesService {
  final SeriesRepository _repository;

  SeriesService({required SeriesRepository repository})
      : _repository = repository;

  @override
  Future<ApiResult<List<DomainCategory>>> getCategories(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      moduleLogger.info('Fetching series categories', tag: 'Series');
      return await _repository.fetchCategories(credentials);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch series categories',
        tag: 'Series',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<DomainSeries>>> getSeries(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) async {
    try {
      moduleLogger.info(
        'Fetching series${categoryId != null ? ' for category $categoryId' : ''}',
        tag: 'Series',
      );
      return await _repository.fetchSeries(credentials, categoryId: categoryId);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch series',
        tag: 'Series',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<DomainSeries>> getSeriesDetails(
    XtreamCredentialsModel credentials,
    String seriesId,
  ) async {
    try {
      moduleLogger.info('Fetching series details for $seriesId', tag: 'Series');
      return await _repository.fetchSeriesDetails(credentials, seriesId);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch series details',
        tag: 'Series',
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
    return '${credentials.baseUrl}/series/${credentials.username}/${credentials.password}/$streamId.$extension';
  }

  @override
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials) async {
    try {
      moduleLogger.info('Refreshing series data', tag: 'Series');
      return await _repository.refresh(credentials);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

/// Series repository interface
abstract class SeriesRepository {
  /// Fetch series categories from API
  Future<ApiResult<List<DomainCategory>>> fetchCategories(
    XtreamCredentialsModel credentials,
  );

  /// Fetch series from API
  Future<ApiResult<List<DomainSeries>>> fetchSeries(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  });

  /// Fetch series details with seasons and episodes from API
  Future<ApiResult<DomainSeries>> fetchSeriesDetails(
    XtreamCredentialsModel credentials,
    String seriesId,
  );

  /// Refresh cached data
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials);
}

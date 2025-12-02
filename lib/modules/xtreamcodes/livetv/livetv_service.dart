// LiveTvService
// Service for managing live TV channels, categories, and streaming.

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';

/// Live TV service interface
abstract class ILiveTvService {
  /// Get all live TV categories
  Future<ApiResult<List<DomainCategory>>> getCategories(
    XtreamCredentialsModel credentials,
  );

  /// Get all live TV channels
  Future<ApiResult<List<DomainChannel>>> getChannels(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  });

  /// Get channels with EPG information
  Future<ApiResult<List<DomainChannel>>> getChannelsWithEpg(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  });

  /// Get stream URL for a channel
  String getStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String format,
  });

  /// Refresh live TV data
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials);
}

/// Live TV service implementation
class LiveTvService implements ILiveTvService {
  LiveTvService({required LiveTvRepository repository})
      : _repository = repository;
  final LiveTvRepository _repository;

  @override
  Future<ApiResult<List<DomainCategory>>> getCategories(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      moduleLogger.info('Fetching live TV categories', tag: 'LiveTV');
      return await _repository.fetchCategories(credentials);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch live TV categories',
        tag: 'LiveTV',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<DomainChannel>>> getChannels(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) async {
    try {
      moduleLogger.info(
        'Fetching live TV channels${categoryId != null ? ' for category $categoryId' : ''}',
        tag: 'LiveTV',
      );
      return await _repository.fetchChannels(credentials,
          categoryId: categoryId);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch live TV channels',
        tag: 'LiveTV',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<DomainChannel>>> getChannelsWithEpg(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) async {
    try {
      moduleLogger.info(
        'Fetching live TV channels with EPG',
        tag: 'LiveTV',
      );
      return await _repository.fetchChannelsWithEpg(
        credentials,
        categoryId: categoryId,
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch live TV channels with EPG',
        tag: 'LiveTV',
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
    String format = 'm3u8',
  }) {
    return '${credentials.baseUrl}/live/${credentials.username}/${credentials.password}/$streamId.$format';
  }

  @override
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials) async {
    try {
      moduleLogger.info('Refreshing live TV data', tag: 'LiveTV');
      return await _repository.refresh(credentials);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

/// Live TV repository interface
abstract class LiveTvRepository {
  /// Fetch live TV categories from API
  Future<ApiResult<List<DomainCategory>>> fetchCategories(
    XtreamCredentialsModel credentials,
  );

  /// Fetch live TV channels from API
  Future<ApiResult<List<DomainChannel>>> fetchChannels(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  });

  /// Fetch channels with EPG information
  Future<ApiResult<List<DomainChannel>>> fetchChannelsWithEpg(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  });

  /// Refresh cached data
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials);
}

// Xtream API Client
// HTTP client for Xtream Codes API interactions using Dio.

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import '../auth/xtream_credentials.dart';
import '../models/xtream_api_models.dart';

/// Xtream API Client
class XtreamApiClient {
  XtreamApiClient({
    required XtreamCredentials credentials,
    Dio? dio,
  })  : _credentials = credentials,
        _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      connectTimeout: AppConfig().defaultTimeout,
      receiveTimeout: AppConfig().extendedTimeout,
      validateStatus: (status) => status != null && status < 500,
    );
  }

  final XtreamCredentials _credentials;
  final Dio _dio;

  /// Authenticate and get account info
  Future<ApiResult<XtreamAuthResponse>> authenticate() async {
    try {
      moduleLogger.info('Authenticating with Xtream server', tag: 'XtreamAPI');

      final response = await _dio.get<Map<String, dynamic>>(
        _credentials.apiUrl,
        queryParameters: {
          'username': _credentials.username,
          'password': _credentials.password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = XtreamAuthResponse.fromJson(response.data!);
        
        if (!authResponse.userInfo.isActive) {
          return ApiResult.failure(
            ApiError.auth('Account is not active or has expired'),
          );
        }

        moduleLogger.info('Authentication successful', tag: 'XtreamAPI');
        return ApiResult.success(authResponse);
      }

      return ApiResult.failure(
        ApiError.server('Authentication failed', response.statusCode),
      );
    } on DioException catch (e) {
      moduleLogger.error(
        'Authentication failed',
        tag: 'XtreamAPI',
        error: e,
      );
      return ApiResult.failure(_mapDioError(e));
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Unexpected error during authentication',
        tag: 'XtreamAPI',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get live stream categories
  Future<ApiResult<List<XtreamLiveCategory>>> getLiveCategories() async {
    return _getList<XtreamLiveCategory>(
      'get_live_categories',
      (json) => XtreamLiveCategory.fromJson(json as Map<String, dynamic>),
      'live categories',
    );
  }

  /// Get live streams
  Future<ApiResult<List<XtreamLiveStream>>> getLiveStreams({
    String? categoryId,
  }) async {
    return _getList<XtreamLiveStream>(
      'get_live_streams',
      (json) => XtreamLiveStream.fromJson(json as Map<String, dynamic>),
      'live streams',
      additionalParams: categoryId != null ? {'category_id': categoryId} : null,
    );
  }

  /// Get VOD categories
  Future<ApiResult<List<XtreamVodCategory>>> getVodCategories() async {
    return _getList<XtreamVodCategory>(
      'get_vod_categories',
      (json) => XtreamVodCategory.fromJson(json as Map<String, dynamic>),
      'VOD categories',
    );
  }

  /// Get VOD streams
  Future<ApiResult<List<XtreamVodStream>>> getVodStreams({
    String? categoryId,
  }) async {
    return _getList<XtreamVodStream>(
      'get_vod_streams',
      (json) => XtreamVodStream.fromJson(json as Map<String, dynamic>),
      'VOD streams',
      additionalParams: categoryId != null ? {'category_id': categoryId} : null,
    );
  }

  /// Get VOD info by stream ID
  Future<ApiResult<XtreamVodInfo>> getVodInfo(String vodId) async {
    try {
      moduleLogger.info('Fetching VOD info for: $vodId', tag: 'XtreamAPI');

      final response = await _dio.get<Map<String, dynamic>>(
        _credentials.apiUrl,
        queryParameters: {
          'username': _credentials.username,
          'password': _credentials.password,
          'action': 'get_vod_info',
          'vod_id': vodId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final vodInfo = XtreamVodInfo.fromJson(response.data!);
        return ApiResult.success(vodInfo);
      }

      return ApiResult.failure(
        ApiError.server('Failed to fetch VOD info', response.statusCode),
      );
    } on DioException catch (e) {
      return ApiResult.failure(_mapDioError(e));
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get series categories
  Future<ApiResult<List<XtreamSeriesCategory>>> getSeriesCategories() async {
    return _getList<XtreamSeriesCategory>(
      'get_series_categories',
      (json) => XtreamSeriesCategory.fromJson(json as Map<String, dynamic>),
      'series categories',
    );
  }

  /// Get series
  Future<ApiResult<List<XtreamSeries>>> getSeries({
    String? categoryId,
  }) async {
    return _getList<XtreamSeries>(
      'get_series',
      (json) => XtreamSeries.fromJson(json as Map<String, dynamic>),
      'series',
      additionalParams: categoryId != null ? {'category_id': categoryId} : null,
    );
  }

  /// Get series info by series ID
  Future<ApiResult<XtreamSeriesInfo>> getSeriesInfo(String seriesId) async {
    try {
      moduleLogger.info('Fetching series info for: $seriesId', tag: 'XtreamAPI');

      final response = await _dio.get<Map<String, dynamic>>(
        _credentials.apiUrl,
        queryParameters: {
          'username': _credentials.username,
          'password': _credentials.password,
          'action': 'get_series_info',
          'series_id': seriesId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final seriesInfo = XtreamSeriesInfo.fromJson(response.data!);
        return ApiResult.success(seriesInfo);
      }

      return ApiResult.failure(
        ApiError.server('Failed to fetch series info', response.statusCode),
      );
    } on DioException catch (e) {
      return ApiResult.failure(_mapDioError(e));
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Download XMLTV EPG data
  Future<ApiResult<String>> downloadXmltvEpg() async {
    try {
      moduleLogger.info('Downloading XMLTV EPG', tag: 'XtreamAPI');

      final response = await _dio.get<String>(
        _credentials.xmltvUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: AppConfig().extendedTimeout * 2,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        moduleLogger.info(
          'XMLTV EPG downloaded successfully (${response.data!.length} bytes)',
          tag: 'XtreamAPI',
        );
        return ApiResult.success(response.data!);
      }

      return ApiResult.failure(
        ApiError.server('Failed to download EPG', response.statusCode),
      );
    } on DioException catch (e) {
      moduleLogger.error('EPG download failed', tag: 'XtreamAPI', error: e);
      return ApiResult.failure(_mapDioError(e));
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Unexpected error downloading EPG',
        tag: 'XtreamAPI',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Build live stream URL
  String getLiveStreamUrl(String streamId, {String extension = 'ts'}) {
    return '${_credentials.baseUrl}/live/${_credentials.username}/${_credentials.password}/$streamId.$extension';
  }

  /// Build VOD stream URL
  String getVodStreamUrl(String streamId, String extension) {
    return '${_credentials.baseUrl}/movie/${_credentials.username}/${_credentials.password}/$streamId.$extension';
  }

  /// Build series episode stream URL
  String getSeriesStreamUrl(String episodeId, String extension) {
    return '${_credentials.baseUrl}/series/${_credentials.username}/${_credentials.password}/$episodeId.$extension';
  }

  /// Generic list fetcher
  Future<ApiResult<List<T>>> _getList<T>(
    String action,
    T Function(dynamic) fromJson,
    String resourceName, {
    Map<String, String>? additionalParams,
  }) async {
    try {
      moduleLogger.info('Fetching $resourceName', tag: 'XtreamAPI');

      final queryParams = {
        'username': _credentials.username,
        'password': _credentials.password,
        'action': action,
        ...?additionalParams,
      };

      final response = await _dio.get<List<dynamic>>(
        _credentials.apiUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data!.map((json) => fromJson(json)).toList();
        moduleLogger.info(
          'Fetched ${items.length} $resourceName',
          tag: 'XtreamAPI',
        );
        return ApiResult.success(items);
      }

      return ApiResult.failure(
        ApiError.server('Failed to fetch $resourceName', response.statusCode),
      );
    } on DioException catch (e) {
      moduleLogger.error(
        'Failed to fetch $resourceName',
        tag: 'XtreamAPI',
        error: e,
      );
      return ApiResult.failure(_mapDioError(e));
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Unexpected error fetching $resourceName',
        tag: 'XtreamAPI',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Map Dio errors to ApiError
  ApiError _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError.timeout('Request timed out');
      case DioExceptionType.connectionError:
        return ApiError.network('Connection error');
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
          return ApiError.auth('Authentication failed');
        }
        return ApiError.server(
          'Server error: ${error.response?.statusMessage}',
          error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const ApiError(
          type: ApiErrorType.unknown,
          message: 'Request cancelled',
        );
      default:
        return ApiError.network('Network error: ${error.message}');
    }
  }
}

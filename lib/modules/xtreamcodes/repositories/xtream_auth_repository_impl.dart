// XtreamAuthRepositoryImpl
// Implements authentication repository using Dio HTTP client.

import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import '../account/xtream_account_models.dart';
import '../auth/xtream_auth_service.dart';
import 'xtream_repository_base.dart';

/// Default timeout for authentication requests (15 seconds)
const Duration _authTimeout = Duration(seconds: 15);

/// Xtream authentication repository implementation
class XtreamAuthRepositoryImpl extends XtreamRepositoryBase
    implements XtreamAuthRepository {
  XtreamAuthRepositoryImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _authTimeout,
              receiveTimeout: _authTimeout,
              headers: {
                'Accept': '*/*',
                'User-Agent': 'WatchTheFlix/1.0',
              },
            ));
  final Dio _dio;

  @override
  Future<ApiResult<XtreamAccountOverview>> authenticate(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      moduleLogger.info(
        'Authenticating ${credentials.username}',
        tag: 'XtreamAuth',
      );

      final url = buildUrl(credentials, '');
      // Note: Dio handles timeout via BaseOptions, no additional timeout needed
      final response = await _dio.get<Map<String, dynamic>>(url);

      if (response.data == null) {
        return ApiResult.failure(
          ApiError.auth('Invalid response from server'),
        );
      }

      final data = response.data!;

      // Check for error responses
      if (data['user_info'] == null && data['error'] != null) {
        return ApiResult.failure(
          ApiError.auth(data['error'].toString()),
        );
      }

      final accountOverview = XtreamAccountOverview.fromJson(data);

      moduleLogger.info(
        'Authentication response received for ${credentials.username}',
        tag: 'XtreamAuth',
      );

      return ApiResult.success(accountOverview);
    } on DioException catch (e) {
      moduleLogger.error(
        'Authentication failed',
        tag: 'XtreamAuth',
        error: e,
      );
      return ApiResult.failure(_handleDioError(e));
    } on TimeoutException catch (_) {
      moduleLogger.error(
        'Authentication timed out',
        tag: 'XtreamAuth',
      );
      return ApiResult.failure(
        ApiError.timeout('Authentication timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Authentication exception',
        tag: 'XtreamAuth',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Handle Dio errors and convert to ApiError
  ApiError _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError.timeout('Connection timed out');
      case DioExceptionType.connectionError:
        return ApiError.network('Unable to connect to server');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return ApiError.auth('Invalid credentials');
        }
        return ApiError.server(
          'Server error',
          statusCode,
        );
      default:
        return ApiError(
          type: ApiErrorType.unknown,
          message: e.message ?? 'Authentication failed',
          originalError: e,
        );
    }
  }
}

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';

/// API client interface
abstract class ApiClient {
  /// Make GET request
  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  /// Make POST request
  Future<Response<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });

  /// Download file
  Future<String> download(String url);
}

/// API client implementation using Dio
class ApiClientImpl implements ApiClient {
  ApiClientImpl() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Accept': '*/*',
          'User-Agent': 'WatchTheFlix/1.0',
        },
      ),
    );

    // Only add log interceptor in debug mode with minimal output
    // to avoid console spam from excessive logging
    assert(() {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (object) => AppLogger.debug(object.toString()),
        ),
      );
      return true;
    }());
  }
  late final Dio _dio;

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        url,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Response<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<String> download(String url) async {
    try {
      final response = await _dio.get<String>(url);
      return response.data ?? '';
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timeout. Please check your internet.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Unable to connect. Please check your internet.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode == 401 || statusCode == 403) {
          return AuthException(
            statusCode: statusCode,
          );
        }
        return ServerException(
          message: e.response?.statusMessage ?? 'Server error',
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return const AppException(message: 'Request cancelled');
      default:
        return AppException(
          message: e.message ?? 'An error occurred',
        );
    }
  }
}

// NetworkClient
// HTTP client wrapper with retry logic, interceptors, and error handling.
// Provides a consistent network interface for all modules.

import 'dart:async';
import 'dart:math' as math;

import '../config/app_config.dart';
import '../logging/app_logger.dart';

/// Network request result wrapper
class NetworkResult<T> {
  final T? data;
  final NetworkError? error;
  final int? statusCode;

  const NetworkResult({
    this.data,
    this.error,
    this.statusCode,
  });

  bool get isSuccess => error == null && data != null;
  bool get isFailure => error != null;

  /// Map the result to a different type
  NetworkResult<R> map<R>(R Function(T data) mapper) {
    if (data != null) {
      return NetworkResult(data: mapper(data), statusCode: statusCode);
    }
    return NetworkResult(error: error, statusCode: statusCode);
  }
}

/// Network error types
enum NetworkErrorType {
  connectionError,
  timeout,
  serverError,
  authError,
  parseError,
  unknown,
}

/// Network error model
class NetworkError {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const NetworkError({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'NetworkError($type): $message';
}

/// Network request interceptor interface
abstract class NetworkInterceptor {
  /// Called before request is sent
  Future<Map<String, String>> onRequest(Map<String, String> headers);

  /// Called on successful response
  Future<void> onResponse(int statusCode, dynamic data);

  /// Called on error
  Future<void> onError(NetworkError error);
}

/// Network client interface
abstract class INetworkClient {
  /// Perform GET request
  Future<NetworkResult<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Perform POST request
  Future<NetworkResult<T>> post<T>(
    String url, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Add interceptor
  void addInterceptor(NetworkInterceptor interceptor);

  /// Remove interceptor
  void removeInterceptor(NetworkInterceptor interceptor);
}

/// Retry configuration
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
  });

  /// Calculate delay for a given retry attempt
  Duration getDelayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;
    final multiplier = math.pow(backoffMultiplier, attempt - 1).toDouble();
    return Duration(
      milliseconds: (initialDelay.inMilliseconds * multiplier).round(),
    );
  }
}

/// Default retry configuration
const defaultRetryConfig = RetryConfig();

/// Helper to execute with retry logic
Future<T> executeWithRetry<T>({
  required Future<T> Function() operation,
  required bool Function(dynamic error) shouldRetry,
  RetryConfig config = defaultRetryConfig,
  String? operationName,
}) async {
  int attempt = 0;
  dynamic lastError;

  while (attempt < config.maxRetries) {
    try {
      return await operation();
    } catch (e) {
      lastError = e;
      attempt++;

      if (!shouldRetry(e) || attempt >= config.maxRetries) {
        break;
      }

      final delay = config.getDelayForAttempt(attempt);
      moduleLogger.warning(
        '${operationName ?? 'Operation'} failed, retrying in ${delay.inMilliseconds}ms (attempt $attempt/${config.maxRetries})',
        error: e,
      );

      await Future.delayed(delay);
    }
  }

  throw lastError;
}

/// Helper to execute with timeout
Future<T> executeWithTimeout<T>({
  required Future<T> Function() operation,
  Duration? timeout,
  String? operationName,
}) async {
  final effectiveTimeout = timeout ?? AppConfig().defaultTimeout;

  try {
    return await operation().timeout(effectiveTimeout);
  } on TimeoutException {
    throw NetworkError(
      type: NetworkErrorType.timeout,
      message: '${operationName ?? 'Request'} timed out after ${effectiveTimeout.inSeconds}s',
    );
  }
}

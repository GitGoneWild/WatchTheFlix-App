// ApiResult
// Generic result wrapper for API operations with success/failure handling.

/// API result wrapper for handling success and failure cases
class ApiResult<T> {
  final T? _data;
  final ApiError? _error;

  const ApiResult._({T? data, ApiError? error})
      : _data = data,
        _error = error;

  /// Create a success result
  factory ApiResult.success(T data) => ApiResult._(data: data);

  /// Create a failure result
  factory ApiResult.failure(ApiError error) => ApiResult._(error: error);

  /// Check if this is a success result
  bool get isSuccess => _error == null && _data != null;

  /// Check if this is a failure result
  bool get isFailure => _error != null;

  /// Get the data (throws if failure)
  T get data {
    if (_data == null) {
      throw StateError('Cannot access data on a failure result');
    }
    return _data;
  }

  /// Get the data or null
  T? get dataOrNull => _data;

  /// Get the error (throws if success)
  ApiError get error {
    if (_error == null) {
      throw StateError('Cannot access error on a success result');
    }
    return _error;
  }

  /// Get the error or null
  ApiError? get errorOrNull => _error;

  /// Map the result to a different type
  ApiResult<R> map<R>(R Function(T data) mapper) {
    if (isSuccess) {
      return ApiResult.success(mapper(data));
    }
    return ApiResult.failure(error);
  }

  /// Execute a callback based on success or failure
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(ApiError error) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(data);
    }
    return onFailure(error);
  }

  /// Execute callback on success
  void onSuccess(void Function(T data) callback) {
    if (isSuccess) {
      callback(data);
    }
  }

  /// Execute callback on failure
  void onFailure(void Function(ApiError error) callback) {
    if (isFailure) {
      callback(error);
    }
  }
}

/// API error types
enum ApiErrorType {
  network,
  server,
  auth,
  notFound,
  timeout,
  parse,
  validation,
  unknown,
}

/// API error model
class ApiError {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  /// Create from exception
  factory ApiError.fromException(dynamic exception) {
    if (exception is ApiError) return exception;

    return ApiError(
      type: ApiErrorType.unknown,
      message: exception.toString(),
      originalError: exception,
    );
  }

  /// Create a network error
  factory ApiError.network([String? message]) => ApiError(
        type: ApiErrorType.network,
        message: message ?? 'Network error occurred',
      );

  /// Create a server error
  factory ApiError.server([String? message, int? statusCode]) => ApiError(
        type: ApiErrorType.server,
        message: message ?? 'Server error occurred',
        statusCode: statusCode,
      );

  /// Create an auth error
  factory ApiError.auth([String? message]) => ApiError(
        type: ApiErrorType.auth,
        message: message ?? 'Authentication failed',
      );

  /// Create a timeout error
  factory ApiError.timeout([String? message]) => ApiError(
        type: ApiErrorType.timeout,
        message: message ?? 'Request timed out',
      );

  @override
  String toString() => 'ApiError($type): $message';
}

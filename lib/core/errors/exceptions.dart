/// Base exception class
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'AppException: $message (code: $statusCode)';
}

/// Server exception
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.statusCode,
    super.data,
  });
}

/// Cache exception
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error occurred',
    super.statusCode,
    super.data,
  });
}

/// Parse exception
class ParseException extends AppException {
  const ParseException({
    super.message = 'Failed to parse data',
    super.statusCode,
    super.data,
  });
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication failed',
    super.statusCode,
    super.data,
  });
}

/// Validation exception
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

// XtreamAuthService
// Handles all Xtream authentication logic including login, token/session handling, and error types.
// No UI code - only domain/data logic.

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import '../account/xtream_account_models.dart';

/// Authentication error types
enum AuthErrorType {
  invalidCredentials,
  serverUnreachable,
  accountExpired,
  accountDisabled,
  networkError,
  unknown,
}

/// Authentication error model
class XtreamAuthError extends ApiError {
  final AuthErrorType authErrorType;

  const XtreamAuthError({
    required this.authErrorType,
    required super.message,
    super.statusCode,
    super.originalError,
  }) : super(type: ApiErrorType.auth);

  factory XtreamAuthError.invalidCredentials([String? message]) {
    return XtreamAuthError(
      authErrorType: AuthErrorType.invalidCredentials,
      message: message ?? 'Invalid username or password',
    );
  }

  factory XtreamAuthError.serverUnreachable([String? message]) {
    return XtreamAuthError(
      authErrorType: AuthErrorType.serverUnreachable,
      message: message ?? 'Server is unreachable',
    );
  }

  factory XtreamAuthError.accountExpired([String? message]) {
    return XtreamAuthError(
      authErrorType: AuthErrorType.accountExpired,
      message: message ?? 'Account has expired',
    );
  }

  factory XtreamAuthError.accountDisabled([String? message]) {
    return XtreamAuthError(
      authErrorType: AuthErrorType.accountDisabled,
      message: message ?? 'Account is disabled',
    );
  }
}

/// Authentication result model
class XtreamAuthResult {
  final bool isAuthenticated;
  final XtreamAccountOverview? accountInfo;
  final XtreamAuthError? error;

  const XtreamAuthResult({
    required this.isAuthenticated,
    this.accountInfo,
    this.error,
  });

  factory XtreamAuthResult.success(XtreamAccountOverview accountInfo) {
    return XtreamAuthResult(
      isAuthenticated: true,
      accountInfo: accountInfo,
    );
  }

  factory XtreamAuthResult.failure(XtreamAuthError error) {
    return XtreamAuthResult(
      isAuthenticated: false,
      error: error,
    );
  }
}

/// Xtream authentication service interface
abstract class IXtreamAuthService {
  /// Login with credentials
  Future<ApiResult<XtreamAuthResult>> login(XtreamCredentialsModel credentials);

  /// Validate existing session
  Future<ApiResult<bool>> validateSession(XtreamCredentialsModel credentials);
}

/// Xtream authentication service implementation
class XtreamAuthService implements IXtreamAuthService {
  final XtreamAuthRepository _repository;

  XtreamAuthService({required XtreamAuthRepository repository})
      : _repository = repository;

  @override
  Future<ApiResult<XtreamAuthResult>> login(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      moduleLogger.info(
        'Attempting login for ${credentials.username}',
        tag: 'XtreamAuth',
      );

      final result = await _repository.authenticate(credentials);

      if (result.isFailure) {
        moduleLogger.warning(
          'Login failed: ${result.error.message}',
          tag: 'XtreamAuth',
        );
        return ApiResult.failure(result.error);
      }

      final accountInfo = result.data;

      // Check authentication status
      if (!accountInfo.isAuthenticated) {
        final error = XtreamAuthError.invalidCredentials(
          accountInfo.userInfo.message.isNotEmpty
              ? accountInfo.userInfo.message
              : null,
        );
        return ApiResult.success(XtreamAuthResult.failure(error));
      }

      // Check account status
      if (accountInfo.userInfo.isExpired) {
        final error = XtreamAuthError.accountExpired();
        return ApiResult.success(XtreamAuthResult.failure(error));
      }

      if (!accountInfo.userInfo.isActive) {
        final error = XtreamAuthError.accountDisabled(
          'Account status: ${accountInfo.userInfo.status}',
        );
        return ApiResult.success(XtreamAuthResult.failure(error));
      }

      moduleLogger.info(
        'Login successful for ${credentials.username}',
        tag: 'XtreamAuth',
      );

      return ApiResult.success(XtreamAuthResult.success(accountInfo));
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Login exception',
        tag: 'XtreamAuth',
        error: e,
        stackTrace: stackTrace,
      );

      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<bool>> validateSession(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      final result = await login(credentials);

      if (result.isSuccess) {
        return ApiResult.success(result.data.isAuthenticated);
      }

      return ApiResult.failure(result.error);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

/// Xtream authentication repository interface
abstract class XtreamAuthRepository {
  /// Authenticate with Xtream server
  Future<ApiResult<XtreamAccountOverview>> authenticate(
    XtreamCredentialsModel credentials,
  );
}

// Xtream Auth Service
// Service for managing Xtream Codes authentication and credential storage.

import 'dart:convert';

import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import '../../core/storage/storage_service.dart';
import 'xtream_credentials.dart';

/// Storage key for Xtream credentials
const String _xtreamCredentialsKey = 'xtream_credentials';

/// Xtream authentication service interface
abstract class IXtreamAuthService {
  /// Save credentials to storage
  Future<ApiResult<void>> saveCredentials(XtreamCredentials credentials);

  /// Load credentials from storage
  Future<ApiResult<XtreamCredentials>> loadCredentials();

  /// Check if credentials exist
  Future<bool> hasCredentials();

  /// Clear stored credentials
  Future<ApiResult<void>> clearCredentials();

  /// Validate credentials format
  ApiResult<void> validateCredentials(XtreamCredentials credentials);
}

/// Xtream authentication service implementation
class XtreamAuthService implements IXtreamAuthService {
  XtreamAuthService({
    required IStorageService storage,
  }) : _storage = storage;

  final IStorageService _storage;

  @override
  Future<ApiResult<void>> saveCredentials(XtreamCredentials credentials) async {
    try {
      // Validate before saving
      final validation = validateCredentials(credentials);
      if (validation.isFailure) {
        return validation;
      }

      moduleLogger.info('Saving Xtream credentials', tag: 'XtreamAuth');

      final json = credentials.toJson();
      final result = await _storage.setJson(_xtreamCredentialsKey, json);

      if (result.isFailure) {
        return ApiResult.failure(
          ApiError(
            type: ApiErrorType.unknown,
            message: result.error!.message,
          ),
        );
      }

      moduleLogger.info('Credentials saved successfully', tag: 'XtreamAuth');
      return ApiResult.success(null);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save credentials',
        tag: 'XtreamAuth',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<XtreamCredentials>> loadCredentials() async {
    try {
      moduleLogger.info('Loading Xtream credentials', tag: 'XtreamAuth');

      final result = await _storage.getJson(_xtreamCredentialsKey);

      if (result.isFailure) {
        if (result.error!.type == StorageErrorType.notFound) {
          return ApiResult.failure(
            const ApiError(
              type: ApiErrorType.notFound,
              message: 'No credentials found',
            ),
          );
        }
        return ApiResult.failure(
          ApiError(
            type: ApiErrorType.unknown,
            message: result.error!.message,
          ),
        );
      }

      final credentials = XtreamCredentials.fromJson(result.data!);
      moduleLogger.info('Credentials loaded successfully', tag: 'XtreamAuth');
      return ApiResult.success(credentials);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to load credentials',
        tag: 'XtreamAuth',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<bool> hasCredentials() async {
    final result = await _storage.containsKey(_xtreamCredentialsKey);
    return result.isSuccess && (result.data ?? false);
  }

  @override
  Future<ApiResult<void>> clearCredentials() async {
    try {
      moduleLogger.info('Clearing Xtream credentials', tag: 'XtreamAuth');

      final result = await _storage.remove(_xtreamCredentialsKey);

      if (result.isFailure) {
        return ApiResult.failure(
          ApiError(
            type: ApiErrorType.unknown,
            message: result.error!.message,
          ),
        );
      }

      moduleLogger.info('Credentials cleared successfully', tag: 'XtreamAuth');
      return ApiResult.success(null);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to clear credentials',
        tag: 'XtreamAuth',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  ApiResult<void> validateCredentials(XtreamCredentials credentials) {
    if (credentials.serverUrl.isEmpty) {
      return ApiResult.failure(
        const ApiError(
          type: ApiErrorType.validation,
          message: 'Server URL is required',
        ),
      );
    }

    if (credentials.username.isEmpty) {
      return ApiResult.failure(
        const ApiError(
          type: ApiErrorType.validation,
          message: 'Username is required',
        ),
      );
    }

    if (credentials.password.isEmpty) {
      return ApiResult.failure(
        const ApiError(
          type: ApiErrorType.validation,
          message: 'Password is required',
        ),
      );
    }

    if (!credentials.serverUrl.startsWith('http://') &&
        !credentials.serverUrl.startsWith('https://')) {
      return ApiResult.failure(
        const ApiError(
          type: ApiErrorType.validation,
          message: 'Server URL must start with http:// or https://',
        ),
      );
    }

    return ApiResult.success(null);
  }
}

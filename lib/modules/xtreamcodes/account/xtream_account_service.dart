// XtreamAccountService
// Responsible for fetching and mapping Xtream account overview data for a given profile.
// Depends on core/network and core/models only.

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import 'xtream_account_models.dart';

/// Xtream account service interface
abstract class IXtreamAccountService {
  /// Get account overview for a profile
  Future<ApiResult<XtreamAccountOverview>> getAccountOverview(
    XtreamCredentialsModel credentials,
  );

  /// Check if account is valid and active
  Future<ApiResult<bool>> validateAccount(XtreamCredentialsModel credentials);
}

/// Xtream account service implementation
class XtreamAccountService implements IXtreamAccountService {
  final XtreamAccountRepository _repository;

  XtreamAccountService({required XtreamAccountRepository repository})
      : _repository = repository;

  @override
  Future<ApiResult<XtreamAccountOverview>> getAccountOverview(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      moduleLogger.info('Fetching account overview for ${credentials.username}',
          tag: 'XtreamAccount');

      final result = await _repository.fetchAccountInfo(credentials);

      if (result.isSuccess) {
        moduleLogger.info(
            'Account overview fetched successfully: ${result.data.status.displayName}',
            tag: 'XtreamAccount');
      }

      return result;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch account overview',
        tag: 'XtreamAccount',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<bool>> validateAccount(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      final result = await getAccountOverview(credentials);

      if (result.isSuccess) {
        return ApiResult.success(
          result.data.isAuthenticated && result.data.userInfo.isActive,
        );
      }

      return ApiResult.failure(result.error);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

/// Xtream account repository interface
abstract class XtreamAccountRepository {
  /// Fetch account information from Xtream API
  Future<ApiResult<XtreamAccountOverview>> fetchAccountInfo(
    XtreamCredentialsModel credentials,
  );
}

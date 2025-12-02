// XtreamAccountRepositoryImpl
// Implements account repository using Dio HTTP client.

import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';
import '../account/xtream_account_models.dart';
import '../account/xtream_account_service.dart';
import 'xtream_repository_base.dart';

/// Default timeout for account requests (15 seconds)
const Duration _accountTimeout = Duration(seconds: 15);

/// Xtream account repository implementation
class XtreamAccountRepositoryImpl extends XtreamRepositoryBase
    implements XtreamAccountRepository {
  XtreamAccountRepositoryImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _accountTimeout,
              receiveTimeout: _accountTimeout,
              headers: {
                'Accept': '*/*',
                'User-Agent': 'WatchTheFlix/1.0',
              },
            ));
  final Dio _dio;

  @override
  Future<ApiResult<XtreamAccountOverview>> fetchAccountInfo(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      moduleLogger.info(
        'Fetching account info for ${credentials.username}',
        tag: 'XtreamAccount',
      );

      final url = buildUrl(credentials, '');
      // Note: Dio handles timeout via BaseOptions, no additional timeout needed
      final response = await _dio.get<Map<String, dynamic>>(url);

      if (response.data == null) {
        return ApiResult.failure(
          ApiError.server('Invalid response from server'),
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
        'Account info fetched for ${credentials.username}',
        tag: 'XtreamAccount',
      );

      return ApiResult.success(accountOverview);
    } on DioException catch (e) {
      moduleLogger.error(
        'Failed to fetch account info',
        tag: 'XtreamAccount',
        error: e,
      );
      return ApiResult.failure(handleApiError(e, 'Fetch account info'));
    } on TimeoutException catch (_) {
      moduleLogger.error(
        'Account info request timed out',
        tag: 'XtreamAccount',
      );
      return ApiResult.failure(
        ApiError.timeout('Request timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Account info exception',
        tag: 'XtreamAccount',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

// URL EPG Provider
// Service for fetching EPG data from user-provided URLs.

import 'dart:async';

import 'package:dio/dio.dart';

import '../core/logging/app_logger.dart';
import '../core/models/api_result.dart';
import '../xtreamcodes/epg/epg_models.dart';
import '../xtreamcodes/epg/xmltv_parser.dart';

/// Default timeout for EPG URL requests.
const Duration _urlEpgTimeout = Duration(minutes: 3);

/// EPG fetch result containing data and metadata.
class EpgFetchResult {
  /// The parsed EPG data.
  final EpgData data;

  /// Whether the fetch was successful.
  final bool success;

  /// Error message if fetch failed.
  final String? errorMessage;

  /// Timestamp when the fetch was attempted.
  final DateTime fetchedAt;

  const EpgFetchResult({
    required this.data,
    required this.success,
    this.errorMessage,
    required this.fetchedAt,
  });

  /// Create a successful result.
  ///
  /// [fetchedAt] Optional timestamp for when the fetch occurred.
  /// Defaults to current UTC time if not provided.
  factory EpgFetchResult.success(EpgData data, {DateTime? fetchedAt}) {
    return EpgFetchResult(
      data: data,
      success: true,
      fetchedAt: fetchedAt ?? DateTime.now().toUtc(),
    );
  }

  /// Create a failure result with cached data.
  ///
  /// [fetchedAt] Optional timestamp for when the fetch was attempted.
  /// Defaults to current UTC time if not provided.
  factory EpgFetchResult.failure(
    String message, {
    EpgData? cachedData,
    DateTime? fetchedAt,
  }) {
    return EpgFetchResult(
      data: cachedData ?? EpgData.empty(),
      success: false,
      errorMessage: message,
      fetchedAt: fetchedAt ?? DateTime.now().toUtc(),
    );
  }
}

/// Provider for fetching EPG data from URLs.
///
/// Supports XMLTV format EPG files from any HTTP/HTTPS URL.
/// Handles network errors, parsing errors, and provides validation.
class UrlEpgProvider {
  final Dio _dio;
  final XmltvParser _parser;

  UrlEpgProvider({Dio? dio, XmltvParser? parser})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _urlEpgTimeout,
              receiveTimeout: _urlEpgTimeout,
              headers: {
                'Accept': '*/*',
                'User-Agent': 'WatchTheFlix/1.0',
              },
            )),
        _parser = parser ?? XmltvParser();

  /// Fetch and parse EPG data from a URL.
  ///
  /// [url] The URL to fetch EPG data from.
  /// Returns [ApiResult] with [EpgData] on success.
  Future<ApiResult<EpgData>> fetchEpg(String url) async {
    try {
      moduleLogger.info('Fetching EPG from URL: $url', tag: 'UrlEpgProvider');

      // Validate URL
      final validationError = _validateUrl(url);
      if (validationError != null) {
        moduleLogger.warning(
          'Invalid EPG URL: $validationError',
          tag: 'UrlEpgProvider',
        );
        return ApiResult.failure(ApiError(
          type: ApiErrorType.validation,
          message: validationError,
        ));
      }

      // Fetch the EPG content
      final response = await _dio
          .get<String>(
            url,
            options: Options(
              responseType: ResponseType.plain,
              receiveTimeout: _urlEpgTimeout,
            ),
          )
          .timeout(_urlEpgTimeout);

      final content = response.data;
      if (content == null || content.isEmpty) {
        moduleLogger.warning('Empty EPG response from URL', tag: 'UrlEpgProvider');
        return ApiResult.failure(ApiError(
          type: ApiErrorType.parse,
          message: 'Empty EPG response received',
        ));
      }

      // Validate content looks like XMLTV
      if (!_parser.isValidXmltv(content)) {
        moduleLogger.warning(
          'Response does not appear to be valid XMLTV format',
          tag: 'UrlEpgProvider',
        );
        return ApiResult.failure(ApiError(
          type: ApiErrorType.parse,
          message: 'Invalid EPG format. Expected XMLTV format.',
        ));
      }

      moduleLogger.debug(
        'Received EPG data: ${content.length} bytes',
        tag: 'UrlEpgProvider',
      );

      // Parse the XMLTV content
      final epgData = _parser.parse(content, sourceUrl: url);

      if (epgData.isEmpty) {
        moduleLogger.warning(
          'Parsed EPG data is empty',
          tag: 'UrlEpgProvider',
        );
        return ApiResult.failure(ApiError(
          type: ApiErrorType.parse,
          message: 'No valid EPG data found in the response',
        ));
      }

      moduleLogger.info(
        'Successfully parsed EPG: ${epgData.channels.length} channels, '
        '${epgData.totalPrograms} programs',
        tag: 'UrlEpgProvider',
      );

      return ApiResult.success(epgData);
    } on DioException catch (e) {
      moduleLogger.error(
        'Failed to fetch EPG from URL: ${e.message}',
        tag: 'UrlEpgProvider',
        error: e,
      );

      return ApiResult.failure(_handleDioError(e));
    } on TimeoutException catch (_) {
      moduleLogger.warning('EPG URL fetch timed out', tag: 'UrlEpgProvider');
      return ApiResult.failure(
        ApiError.timeout('EPG download timed out'),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Exception fetching EPG from URL',
        tag: 'UrlEpgProvider',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError(
        type: ApiErrorType.unknown,
        message: 'Failed to fetch EPG: ${e.toString()}',
        originalError: e,
      ));
    }
  }

  /// Validate an EPG URL without fetching the full content.
  ///
  /// Performs a HEAD request to check if the URL is accessible.
  Future<ApiResult<bool>> validateUrl(String url) async {
    try {
      // Basic URL validation
      final validationError = _validateUrl(url);
      if (validationError != null) {
        return ApiResult.failure(ApiError(
          type: ApiErrorType.validation,
          message: validationError,
        ));
      }

      // Try a HEAD request to check if URL is accessible
      final response = await _dio.head(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return ApiResult.success(true);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiResult.failure(ApiError.auth(
          'EPG URL requires authentication',
        ));
      } else if (response.statusCode == 404) {
        return ApiResult.failure(ApiError(
          type: ApiErrorType.notFound,
          message: 'EPG URL not found',
        ));
      } else {
        return ApiResult.failure(ApiError.server(
          'EPG URL returned status ${response.statusCode}',
          response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return ApiResult.failure(_handleDioError(e));
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Validate URL format.
  String? _validateUrl(String url) {
    if (url.isEmpty) {
      return 'EPG URL cannot be empty';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return 'Invalid URL format';
    }

    if (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'URL must start with http:// or https://';
    }

    if (!uri.hasAuthority || uri.host.isEmpty) {
      return 'URL must contain a valid host';
    }

    return null;
  }

  /// Handle Dio errors and convert to ApiError.
  ApiError _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError.timeout('EPG download timed out');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return ApiError.auth('EPG URL requires authentication');
        } else if (statusCode == 404) {
          return ApiError(
            type: ApiErrorType.notFound,
            message: 'EPG URL not found',
            statusCode: statusCode,
          );
        } else {
          return ApiError.server(
            'EPG server error: ${e.message}',
            statusCode,
          );
        }

      case DioExceptionType.connectionError:
        return ApiError.network('Unable to connect to EPG server');

      case DioExceptionType.cancel:
        return ApiError(
          type: ApiErrorType.unknown,
          message: 'EPG request was cancelled',
        );

      default:
        return ApiError.network('Network error: ${e.message}');
    }
  }
}

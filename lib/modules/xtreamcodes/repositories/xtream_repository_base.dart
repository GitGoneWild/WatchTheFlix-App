// XtreamRepositoryBase
// Base class for Xtream API repositories with common response handling.

import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/logging/app_logger.dart';

/// Base class for Xtream API repositories
abstract class XtreamRepositoryBase {
  /// Build API URL with authentication
  /// Username and password are URL-encoded for query parameter safety
  String buildUrl(XtreamCredentialsModel credentials, String action) {
    final encodedUsername = Uri.encodeComponent(credentials.username);
    final encodedPassword = Uri.encodeComponent(credentials.password);
    return '${credentials.baseUrl}/player_api.php?'
        'username=$encodedUsername&password=$encodedPassword'
        '&action=$action';
  }

  /// Build stream URL for live content
  /// Note: Credentials are NOT URL-encoded in stream paths as this is the
  /// Xtream Codes API standard format. Most media players expect unencoded
  /// paths. Users should avoid special characters in credentials if possible.
  String buildLiveStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String format = 'm3u8',
  }) {
    return '${credentials.baseUrl}/live/${credentials.username}/${credentials.password}/$streamId.$format';
  }

  /// Build stream URL for movie content
  /// Note: Credentials are NOT URL-encoded in stream paths as this is the
  /// Xtream Codes API standard format. Most media players expect unencoded
  /// paths. Users should avoid special characters in credentials if possible.
  String buildMovieStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String extension = 'mp4',
  }) {
    return '${credentials.baseUrl}/movie/${credentials.username}/${credentials.password}/$streamId.$extension';
  }

  /// Build stream URL for series content
  /// Note: Credentials are NOT URL-encoded in stream paths as this is the
  /// Xtream Codes API standard format. Most media players expect unencoded
  /// paths. Users should avoid special characters in credentials if possible.
  String buildSeriesStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String extension = 'mp4',
  }) {
    return '${credentials.baseUrl}/series/${credentials.username}/${credentials.password}/$streamId.$extension';
  }

  /// Handle common API errors
  ApiError handleApiError(dynamic error, String operation) {
    moduleLogger.error(
      '$operation failed',
      tag: 'XtreamRepo',
      error: error,
    );

    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout')) {
      return ApiError.timeout('$operation timed out');
    }

    if (errorStr.contains('connection') || errorStr.contains('socket')) {
      return ApiError.network('Failed to connect to server');
    }

    if (errorStr.contains('401') || errorStr.contains('403')) {
      return ApiError.auth('Authentication failed');
    }

    if (errorStr.contains('404')) {
      return const ApiError(
        type: ApiErrorType.notFound,
        message: 'Resource not found',
      );
    }

    if (errorStr.contains('500') || errorStr.contains('server')) {
      return ApiError.server('Server error');
    }

    return ApiError(
      type: ApiErrorType.unknown,
      message: '$operation failed: $error',
      originalError: error,
    );
  }

  /// Safely parse list response (handles error maps)
  List<Map<String, dynamic>> safeParseList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map) {
      moduleLogger.warning(
        'Expected list but got map: $data',
        tag: 'XtreamRepo',
      );
      return [];
    }
    return [];
  }

  /// Safely parse rating value
  double? parseRating(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safely parse integer value
  int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}

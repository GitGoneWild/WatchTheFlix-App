import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/models/category_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/series_model.dart';
import '../../domain/entities/playlist_source.dart';

/// Default timeout for Xtream API requests (30 seconds)
const Duration kXtreamDefaultTimeout = Duration(seconds: 30);

/// Extended timeout for large data requests like movies/series lists (60 seconds)
const Duration kXtreamExtendedTimeout = Duration(seconds: 60);

/// Short timeout for quick requests like login (15 seconds)
const Duration kXtreamShortTimeout = Duration(seconds: 15);

/// EPG (Electronic Program Guide) entry model
class EpgEntry {
  final String channelId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? language;

  const EpgEntry({
    required this.channelId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.language,
  });

  /// Check if this program is currently airing
  bool get isCurrentlyAiring {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress {
    if (!isCurrentlyAiring) return 0.0;
    final now = DateTime.now();
    final totalDuration = endTime.difference(startTime).inSeconds;
    final elapsed = now.difference(startTime).inSeconds;
    return elapsed / totalDuration;
  }

  factory EpgEntry.fromJson(Map<String, dynamic> json) {
    final startTime = _parseDateTime(json['start'] ?? json['start_timestamp']);
    final endTime = _parseDateTime(json['end'] ?? json['stop_timestamp']);
    
    return EpgEntry(
      channelId: json['epg_id']?.toString() ?? json['channel_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? json['desc'],
      startTime: startTime ?? DateTime.now(),
      endTime: endTime ?? DateTime.now().add(const Duration(hours: 1)),
      language: json['lang'],
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    if (value is String) {
      // Try ISO format first
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      // Try Unix timestamp
      final timestamp = int.tryParse(value);
      if (timestamp != null) return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }
    return null;
  }
}

/// Xtream API login response
class XtreamLoginResponse {
  final String username;
  final String password;
  final String message;
  final int auth;
  final String status;
  final DateTime? expDate;
  final bool isTrial;
  final int activeConnections;
  final int maxConnections;
  final List<String> allowedOutputFormats;
  final String serverUrl;

  XtreamLoginResponse({
    required this.username,
    required this.password,
    required this.message,
    required this.auth,
    required this.status,
    this.expDate,
    this.isTrial = false,
    this.activeConnections = 0,
    this.maxConnections = 1,
    this.allowedOutputFormats = const [],
    required this.serverUrl,
  });

  bool get isAuthenticated => auth == 1;

  factory XtreamLoginResponse.fromJson(
    Map<String, dynamic> json,
    String serverUrl,
  ) {
    final userInfo = json['user_info'] ?? {};
    final serverInfo = json['server_info'] ?? {};

    return XtreamLoginResponse(
      username: userInfo['username'] ?? '',
      password: userInfo['password'] ?? '',
      message: userInfo['message'] ?? '',
      auth: userInfo['auth'] ?? 0,
      status: userInfo['status'] ?? '',
      expDate: userInfo['exp_date'] != null
          ? DateTime.tryParse(userInfo['exp_date'].toString())
          : null,
      isTrial: userInfo['is_trial'] == '1' || userInfo['is_trial'] == true,
      activeConnections:
          int.tryParse(userInfo['active_cons']?.toString() ?? '') ?? 0,
      maxConnections:
          int.tryParse(userInfo['max_connections']?.toString() ?? '') ?? 1,
      allowedOutputFormats: (serverInfo['allowed_output_formats'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      serverUrl: serverUrl,
    );
  }
}

/// Xtream API client interface
abstract class XtreamApiClient {
  /// Login to Xtream server
  Future<XtreamLoginResponse> login(XtreamCredentials credentials);

  /// Fetch live TV categories
  Future<List<CategoryModel>> fetchLiveCategories(
    XtreamCredentials credentials,
  );

  /// Fetch live TV channels
  Future<List<ChannelModel>> fetchLiveChannels(
    XtreamCredentials credentials, {
    String? categoryId,
  });

  /// Fetch movie categories
  Future<List<CategoryModel>> fetchMovieCategories(
    XtreamCredentials credentials,
  );

  /// Fetch movies
  Future<List<MovieModel>> fetchMovies(
    XtreamCredentials credentials, {
    String? categoryId,
  });

  /// Fetch series categories
  Future<List<CategoryModel>> fetchSeriesCategories(
    XtreamCredentials credentials,
  );

  /// Fetch series
  Future<List<SeriesModel>> fetchSeries(
    XtreamCredentials credentials, {
    String? categoryId,
  });

  /// Fetch series info (seasons and episodes)
  Future<SeriesModel> fetchSeriesInfo(
    XtreamCredentials credentials,
    String seriesId,
  );

  /// Get live stream URL
  String getLiveStreamUrl(
    XtreamCredentials credentials,
    String streamId, {
    String format = 'm3u8',
  });

  /// Get movie stream URL
  String getMovieStreamUrl(
    XtreamCredentials credentials,
    String streamId, {
    String extension = 'mp4',
  });

  /// Get series stream URL
  String getSeriesStreamUrl(
    XtreamCredentials credentials,
    String streamId, {
    String extension = 'mp4',
  });

  /// Fetch short EPG (current and next program) for a stream
  Future<List<EpgEntry>> fetchShortEpg(
    XtreamCredentials credentials,
    String streamId, {
    int limit = 2,
  });

  /// Fetch EPG for all live streams
  Future<Map<String, List<EpgEntry>>> fetchAllEpg(
    XtreamCredentials credentials,
  );
}

/// Xtream API client implementation
class XtreamApiClientImpl implements XtreamApiClient {
  final ApiClient _apiClient;

  XtreamApiClientImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  String _buildUrl(XtreamCredentials credentials, String action) {
    final encodedUsername = Uri.encodeComponent(credentials.username);
    final encodedPassword = Uri.encodeComponent(credentials.password);
    return '${credentials.baseUrl}/player_api.php?'
        'username=$encodedUsername&password=$encodedPassword'
        '&action=$action';
  }

  /// Wrap API call with timeout to prevent hanging
  Future<T> _withTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = kXtreamDefaultTimeout,
    required String operationName,
  }) async {
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            '$operationName timed out after ${timeout.inSeconds} seconds',
            timeout,
          );
        },
      );
    } on TimeoutException catch (e) {
      AppLogger.error('$operationName timeout', e);
      throw ServerException(
        message: 'Request timed out. The server may be slow or unreachable.',
      );
    }
  }

  @override
  Future<XtreamLoginResponse> login(XtreamCredentials credentials) async {
    return _withTimeout(
      () async {
        try {
          final encodedUsername = Uri.encodeComponent(credentials.username);
          final encodedPassword = Uri.encodeComponent(credentials.password);
          final url =
              '${credentials.baseUrl}/player_api.php?username=$encodedUsername&password=$encodedPassword';
          
          final response = await _apiClient.get<Map<String, dynamic>>(url);

          if (response.data == null) {
            throw const AuthException(message: 'Invalid response from server');
          }

          // Check for error responses (some servers return error in JSON)
          final data = response.data!;
          if (data['user_info'] == null && data['error'] != null) {
            throw AuthException(message: data['error'].toString());
          }

          final loginResponse = XtreamLoginResponse.fromJson(
            data,
            credentials.baseUrl,
          );

          if (!loginResponse.isAuthenticated) {
            final msg = loginResponse.message.isNotEmpty
                ? loginResponse.message
                : 'Authentication failed';
            throw AuthException(message: msg);
          }

          AppLogger.info('Xtream login successful for ${credentials.username}');
          return loginResponse;
        } catch (e) {
          AppLogger.error('Xtream login failed', e);
          if (e is AppException) rethrow;
          throw AuthException(message: 'Login failed: ${_getErrorMessage(e)}');
        }
      },
      timeout: kXtreamShortTimeout,
      operationName: 'Login',
    );
  }

  /// Extract user-friendly error message from exception
  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out';
        case DioExceptionType.connectionError:
          return 'Unable to connect to server';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            return 'Invalid credentials';
          }
          return 'Server error (${statusCode ?? 'unknown'})';
        default:
          return error.message ?? 'Network error';
      }
    }
    final msg = error.toString();
    // Clean up common prefixes
    return msg
        .replaceAll('Exception: ', '')
        .replaceAll('DioException: ', '')
        .replaceAll('SocketException: ', '');
  }

  /// Helper method to safely parse a rating value that could be int, double, or String
  double? _parseRating(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper method to safely parse a list response that might come back as
  /// a Map (error response) or empty
  List<dynamic> _safeParseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    // Some servers return {} or {"error": "..."} instead of []
    if (data is Map) {
      AppLogger.warning('Expected list but got map: $data');
      return [];
    }
    return [];
  }

  @override
  Future<List<CategoryModel>> fetchLiveCategories(
    XtreamCredentials credentials,
  ) async {
    return _withTimeout(
      () async {
        try {
          final url = _buildUrl(credentials, 'get_live_categories');
          final response = await _apiClient.get<dynamic>(url);

          return _safeParseList(response.data)
              .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          AppLogger.error('Failed to fetch live categories', e);
          if (e is AppException) rethrow;
          throw ServerException(message: 'Failed to fetch categories: ${_getErrorMessage(e)}');
        }
      },
      timeout: kXtreamDefaultTimeout,
      operationName: 'Fetch live categories',
    );
  }

  @override
  Future<List<ChannelModel>> fetchLiveChannels(
    XtreamCredentials credentials, {
    String? categoryId,
  }) async {
    return _withTimeout(
      () async {
        try {
          String url = _buildUrl(credentials, 'get_live_streams');
          if (categoryId != null) {
            url += '&category_id=$categoryId';
          }
          final response = await _apiClient.get<dynamic>(url);

          return _safeParseList(response.data).map((json) {
            final streamId = json['stream_id']?.toString() ?? '';
            return ChannelModel.fromJson({
              ...json as Map<String, dynamic>,
              'stream_url': getLiveStreamUrl(credentials, streamId),
            });
          }).toList();
        } catch (e) {
          AppLogger.error('Failed to fetch live channels', e);
          if (e is AppException) rethrow;
          throw ServerException(message: 'Failed to fetch channels: ${_getErrorMessage(e)}');
        }
      },
      timeout: kXtreamExtendedTimeout,
      operationName: 'Fetch live channels',
    );
  }

  @override
  Future<List<CategoryModel>> fetchMovieCategories(
    XtreamCredentials credentials,
  ) async {
    return _withTimeout(
      () async {
        try {
          final url = _buildUrl(credentials, 'get_vod_categories');
          final response = await _apiClient.get<dynamic>(url);

          return _safeParseList(response.data)
              .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          AppLogger.error('Failed to fetch movie categories', e);
          if (e is AppException) rethrow;
          throw ServerException(message: 'Failed to fetch movie categories: ${_getErrorMessage(e)}');
        }
      },
      timeout: kXtreamDefaultTimeout,
      operationName: 'Fetch movie categories',
    );
  }

  @override
  Future<List<MovieModel>> fetchMovies(
    XtreamCredentials credentials, {
    String? categoryId,
  }) async {
    return _withTimeout(
      () async {
        try {
          String url = _buildUrl(credentials, 'get_vod_streams');
          if (categoryId != null) {
            url += '&category_id=$categoryId';
          }
          final response = await _apiClient.get<dynamic>(url);

          return _safeParseList(response.data).map((json) {
            final streamId = json['stream_id']?.toString() ?? '';
            final extension = json['container_extension'] ?? 'mp4';
            return MovieModel.fromJson({
              ...json as Map<String, dynamic>,
              'stream_url': getMovieStreamUrl(
                credentials,
                streamId,
                extension: extension,
              ),
            });
          }).toList();
        } catch (e) {
          AppLogger.error('Failed to fetch movies', e);
          if (e is AppException) rethrow;
          throw ServerException(message: 'Failed to fetch movies: ${_getErrorMessage(e)}');
        }
      },
      timeout: kXtreamExtendedTimeout,
      operationName: 'Fetch movies',
    );
  }

  @override
  Future<List<CategoryModel>> fetchSeriesCategories(
    XtreamCredentials credentials,
  ) async {
    return _withTimeout(
      () async {
        try {
          final url = _buildUrl(credentials, 'get_series_categories');
          final response = await _apiClient.get<dynamic>(url);

          return _safeParseList(response.data)
              .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          AppLogger.error('Failed to fetch series categories', e);
          if (e is AppException) rethrow;
          throw ServerException(message: 'Failed to fetch series categories: ${_getErrorMessage(e)}');
        }
      },
      timeout: kXtreamDefaultTimeout,
      operationName: 'Fetch series categories',
    );
  }

  @override
  Future<List<SeriesModel>> fetchSeries(
    XtreamCredentials credentials, {
    String? categoryId,
  }) async {
    return _withTimeout(
      () async {
        try {
          String url = _buildUrl(credentials, 'get_series');
          if (categoryId != null) {
            url += '&category_id=$categoryId';
          }
          final response = await _apiClient.get<dynamic>(url);

          return _safeParseList(response.data)
              .map((json) => SeriesModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          AppLogger.error('Failed to fetch series', e);
          if (e is AppException) rethrow;
          throw ServerException(message: 'Failed to fetch series: ${_getErrorMessage(e)}');
        }
      },
      timeout: kXtreamExtendedTimeout,
      operationName: 'Fetch series',
    );
  }

  @override
  Future<SeriesModel> fetchSeriesInfo(
    XtreamCredentials credentials,
    String seriesId,
  ) async {
    return _withTimeout(
      () async {
        try {
          final url = '${_buildUrl(credentials, 'get_series_info')}&series_id=$seriesId';
          final response = await _apiClient.get<Map<String, dynamic>>(url);

          if (response.data == null) {
            throw const ServerException(message: 'Series not found');
          }

          final data = response.data!;
          final info = data['info'] ?? {};
          final episodes = data['episodes'] as Map<String, dynamic>? ?? {};

          // Build seasons with episodes
          final seasons = <SeasonModel>[];
          episodes.forEach((seasonNumber, episodeList) {
            if (episodeList is! List) return;
            final episodeModels = episodeList.map((e) {
              final streamId = e['id']?.toString() ?? '';
              final extension = e['container_extension'] ?? 'mp4';
              return EpisodeModel.fromJson({
                ...e as Map<String, dynamic>,
                'stream_url': getSeriesStreamUrl(
                  credentials,
                  streamId,
                  extension: extension,
                ),
              });
            }).toList();

            seasons.add(SeasonModel(
              id: seasonNumber,
              seasonNumber: int.tryParse(seasonNumber) ?? 1,
              episodes: episodeModels,
            ));
          });

          return SeriesModel(
            id: seriesId,
            name: info['name'] ?? '',
            posterUrl: info['cover'],
            backdropUrl: info['backdrop_path']?.isNotEmpty == true
                ? info['backdrop_path'][0]
                : null,
            description: info['plot'],
            releaseDate: info['releaseDate'],
            rating: _parseRating(info['rating']),
            genre: info['genre'],
            seasons: seasons,
          );
        } catch (e) {
          AppLogger.error('Failed to fetch series info', e);
          if (e is AppException) rethrow;
          throw ServerException(message: 'Failed to fetch series info: ${_getErrorMessage(e)}');
        }
      },
      timeout: kXtreamDefaultTimeout,
      operationName: 'Fetch series info',
    );
  }

  @override
  String getLiveStreamUrl(
    XtreamCredentials credentials,
    String streamId, {
    String format = 'm3u8',
  }) {
    return '${credentials.baseUrl}/live/${credentials.username}/${credentials.password}/$streamId.$format';
  }

  @override
  String getMovieStreamUrl(
    XtreamCredentials credentials,
    String streamId, {
    String extension = 'mp4',
  }) {
    return '${credentials.baseUrl}/movie/${credentials.username}/${credentials.password}/$streamId.$extension';
  }

  @override
  String getSeriesStreamUrl(
    XtreamCredentials credentials,
    String streamId, {
    String extension = 'mp4',
  }) {
    return '${credentials.baseUrl}/series/${credentials.username}/${credentials.password}/$streamId.$extension';
  }

  @override
  Future<List<EpgEntry>> fetchShortEpg(
    XtreamCredentials credentials,
    String streamId, {
    int limit = 2,
  }) async {
    // Use a shorter timeout for EPG as it's not critical
    return _withTimeout(
      () async {
        try {
          final url = '${_buildUrl(credentials, 'get_short_epg')}&stream_id=$streamId&limit=$limit';
          final response = await _apiClient.get<Map<String, dynamic>>(url);

          if (response.data == null) {
            return [];
          }

          final data = response.data!;
          final epgListings = data['epg_listings'] as List? ?? [];

          return epgListings
              .map((json) => EpgEntry.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          AppLogger.error('Failed to fetch short EPG', e);
          // Return empty list on failure - EPG is not critical
          return [];
        }
      },
      timeout: kXtreamShortTimeout,
      operationName: 'Fetch short EPG',
    );
  }

  @override
  Future<Map<String, List<EpgEntry>>> fetchAllEpg(
    XtreamCredentials credentials,
  ) async {
    // Use extended timeout for full EPG but handle failures gracefully
    return _withTimeout(
      () async {
        try {
          // Try the standard EPG endpoint first
          final url = _buildUrl(credentials, 'get_simple_data_table');
          final response = await _apiClient.get<dynamic>(url);

          if (response.data == null) {
            return {};
          }

          final data = response.data;
          if (data is! Map<String, dynamic>) {
            AppLogger.warning('EPG response is not a map: ${data.runtimeType}');
            return {};
          }

          final epgListings = data['epg_listings'] as List? ?? [];
          final result = <String, List<EpgEntry>>{};

          for (final json in epgListings) {
            if (json is! Map<String, dynamic>) continue;
            try {
              final entry = EpgEntry.fromJson(json);
              result.putIfAbsent(entry.channelId, () => []).add(entry);
            } catch (e) {
              // Skip invalid entries
              AppLogger.debug('Skipping invalid EPG entry: $e');
            }
          }

          return result;
        } catch (e) {
          AppLogger.error('Failed to fetch all EPG', e);
          // Return empty map on failure - EPG is optional
          return {};
        }
      },
      timeout: kXtreamExtendedTimeout,
      operationName: 'Fetch all EPG',
    );
  }
}

import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/models/category_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/series_model.dart';
import '../../domain/entities/playlist_source.dart';

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

  @override
  Future<XtreamLoginResponse> login(XtreamCredentials credentials) async {
    try {
      final encodedUsername = Uri.encodeComponent(credentials.username);
      final encodedPassword = Uri.encodeComponent(credentials.password);
      final url =
          '${credentials.baseUrl}/player_api.php?username=$encodedUsername&password=$encodedPassword';
      final response = await _apiClient.get<Map<String, dynamic>>(url);

      if (response.data == null) {
        throw const AuthException(message: 'Invalid response from server');
      }

      final loginResponse = XtreamLoginResponse.fromJson(
        response.data!,
        credentials.baseUrl,
      );

      if (!loginResponse.isAuthenticated) {
        throw const AuthException(message: 'Authentication failed');
      }

      AppLogger.info('Xtream login successful for ${credentials.username}');
      return loginResponse;
    } catch (e) {
      AppLogger.error('Xtream login failed', e);
      if (e is AppException) rethrow;
      throw AuthException(message: 'Login failed: $e');
    }
  }

  @override
  Future<List<CategoryModel>> fetchLiveCategories(
    XtreamCredentials credentials,
  ) async {
    try {
      final url = _buildUrl(credentials, 'get_live_categories');
      final response = await _apiClient.get<List<dynamic>>(url);

      return (response.data ?? [])
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch live categories', e);
      throw ServerException(message: 'Failed to fetch categories: $e');
    }
  }

  @override
  Future<List<ChannelModel>> fetchLiveChannels(
    XtreamCredentials credentials, {
    String? categoryId,
  }) async {
    try {
      String url = _buildUrl(credentials, 'get_live_streams');
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }
      final response = await _apiClient.get<List<dynamic>>(url);

      return (response.data ?? []).map((json) {
        final streamId = json['stream_id']?.toString() ?? '';
        return ChannelModel.fromJson({
          ...json,
          'stream_url': getLiveStreamUrl(credentials, streamId),
        });
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch live channels', e);
      throw ServerException(message: 'Failed to fetch channels: $e');
    }
  }

  @override
  Future<List<CategoryModel>> fetchMovieCategories(
    XtreamCredentials credentials,
  ) async {
    try {
      final url = _buildUrl(credentials, 'get_vod_categories');
      final response = await _apiClient.get<List<dynamic>>(url);

      return (response.data ?? [])
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch movie categories', e);
      throw ServerException(message: 'Failed to fetch movie categories: $e');
    }
  }

  @override
  Future<List<MovieModel>> fetchMovies(
    XtreamCredentials credentials, {
    String? categoryId,
  }) async {
    try {
      String url = _buildUrl(credentials, 'get_vod_streams');
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }
      final response = await _apiClient.get<List<dynamic>>(url);

      return (response.data ?? []).map((json) {
        final streamId = json['stream_id']?.toString() ?? '';
        final extension = json['container_extension'] ?? 'mp4';
        return MovieModel.fromJson({
          ...json,
          'stream_url': getMovieStreamUrl(
            credentials,
            streamId,
            extension: extension,
          ),
        });
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch movies', e);
      throw ServerException(message: 'Failed to fetch movies: $e');
    }
  }

  @override
  Future<List<CategoryModel>> fetchSeriesCategories(
    XtreamCredentials credentials,
  ) async {
    try {
      final url = _buildUrl(credentials, 'get_series_categories');
      final response = await _apiClient.get<List<dynamic>>(url);

      return (response.data ?? [])
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch series categories', e);
      throw ServerException(message: 'Failed to fetch series categories: $e');
    }
  }

  @override
  Future<List<SeriesModel>> fetchSeries(
    XtreamCredentials credentials, {
    String? categoryId,
  }) async {
    try {
      String url = _buildUrl(credentials, 'get_series');
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }
      final response = await _apiClient.get<List<dynamic>>(url);

      return (response.data ?? [])
          .map((json) => SeriesModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch series', e);
      throw ServerException(message: 'Failed to fetch series: $e');
    }
  }

  @override
  Future<SeriesModel> fetchSeriesInfo(
    XtreamCredentials credentials,
    String seriesId,
  ) async {
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
        final episodeModels = (episodeList as List).map((e) {
          final streamId = e['id']?.toString() ?? '';
          final extension = e['container_extension'] ?? 'mp4';
          return EpisodeModel.fromJson({
            ...e,
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
        rating:
            info['rating'] != null ? double.tryParse(info['rating']) : null,
        genre: info['genre'],
        seasons: seasons,
      );
    } catch (e) {
      AppLogger.error('Failed to fetch series info', e);
      if (e is AppException) rethrow;
      throw ServerException(message: 'Failed to fetch series info: $e');
    }
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
    try {
      final url = '${_buildUrl(credentials, 'get_short_epg')}&stream_id=$streamId&limit=$limit';
      final response = await _apiClient.get<Map<String, dynamic>>(url);

      if (response.data == null) {
        return [];
      }

      final data = response.data!;
      final epgListings = data['epg_listings'] as List? ?? [];

      return epgListings
          .map((json) => EpgEntry.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch short EPG', e);
      return [];
    }
  }

  @override
  Future<Map<String, List<EpgEntry>>> fetchAllEpg(
    XtreamCredentials credentials,
  ) async {
    try {
      final url = _buildUrl(credentials, 'get_simple_data_table');
      final response = await _apiClient.get<Map<String, dynamic>>(url);

      if (response.data == null) {
        return {};
      }

      final data = response.data!;
      final epgListings = data['epg_listings'] as List? ?? [];
      final result = <String, List<EpgEntry>>{};

      for (final json in epgListings) {
        final entry = EpgEntry.fromJson(json);
        result.putIfAbsent(entry.channelId, () => []).add(entry);
      }

      return result;
    } catch (e) {
      AppLogger.error('Failed to fetch all EPG', e);
      return {};
    }
  }
}

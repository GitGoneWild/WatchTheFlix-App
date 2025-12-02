// XtreamCodesClient
// Main entry point for Xtream Codes API operations.
// Provides a unified interface to all Xtream services.

import 'package:dio/dio.dart';

import '../core/config/app_config.dart';
import '../core/models/api_result.dart';
import '../core/models/base_models.dart';
import '../core/logging/app_logger.dart';
import 'auth/xtream_auth_service.dart';
import 'account/xtream_account_models.dart';
import 'account/xtream_account_service.dart';
import 'livetv/livetv_service.dart';
import 'movies/movies_service.dart';
import 'series/series_service.dart';
import 'epg/epg_service.dart';
import 'repositories/repositories.dart';

/// Xtream Codes API client providing unified access to all services
class XtreamCodesClient {
  final XtreamAuthService _authService;
  final XtreamAccountService _accountService;
  final LiveTvService _liveTvService;
  final MoviesService _moviesService;
  final SeriesService _seriesService;
  final EpgService _epgService;

  /// Factory constructor that creates all services with default implementations
  factory XtreamCodesClient({Dio? dio}) {
    final config = AppConfig();
    final httpClient = dio ??
        Dio(BaseOptions(
          connectTimeout: config.defaultTimeout,
          receiveTimeout: config.extendedTimeout,
          headers: {
            'Accept': '*/*',
            'User-Agent': 'WatchTheFlix/1.0',
          },
        ));

    // Create repositories
    final authRepo = XtreamAuthRepositoryImpl(dio: httpClient);
    final accountRepo = XtreamAccountRepositoryImpl(dio: httpClient);
    final epgRepo = EpgRepositoryImpl(dio: httpClient);
    final liveTvRepo = LiveTvRepositoryImpl(dio: httpClient, epgRepository: epgRepo);
    final moviesRepo = MoviesRepositoryImpl(dio: httpClient);
    final seriesRepo = SeriesRepositoryImpl(dio: httpClient);

    // Create services
    final authService = XtreamAuthService(repository: authRepo);
    final accountService = XtreamAccountService(repository: accountRepo);
    final liveTvService = LiveTvService(repository: liveTvRepo);
    final moviesService = MoviesService(repository: moviesRepo);
    final seriesService = SeriesService(repository: seriesRepo);
    final epgService = EpgService(repository: epgRepo);

    return XtreamCodesClient._(
      authService: authService,
      accountService: accountService,
      liveTvService: liveTvService,
      moviesService: moviesService,
      seriesService: seriesService,
      epgService: epgService,
    );
  }

  XtreamCodesClient._({
    required XtreamAuthService authService,
    required XtreamAccountService accountService,
    required LiveTvService liveTvService,
    required MoviesService moviesService,
    required SeriesService seriesService,
    required EpgService epgService,
  })  : _authService = authService,
        _accountService = accountService,
        _liveTvService = liveTvService,
        _moviesService = moviesService,
        _seriesService = seriesService,
        _epgService = epgService;

  // ============ Authentication ============

  /// Authenticate with Xtream Codes server
  Future<ApiResult<XtreamAuthResult>> login(
    XtreamCredentialsModel credentials,
  ) {
    return _authService.login(credentials);
  }

  /// Validate existing session
  Future<ApiResult<bool>> validateSession(
    XtreamCredentialsModel credentials,
  ) {
    return _authService.validateSession(credentials);
  }

  // ============ Account ============

  /// Get account overview including user and server info
  Future<ApiResult<XtreamAccountOverview>> getAccountOverview(
    XtreamCredentialsModel credentials,
  ) {
    return _accountService.getAccountOverview(credentials);
  }

  /// Check if account is valid and active
  Future<ApiResult<bool>> validateAccount(
    XtreamCredentialsModel credentials,
  ) {
    return _accountService.validateAccount(credentials);
  }

  // ============ Live TV ============

  /// Get all live TV categories
  Future<ApiResult<List<DomainCategory>>> getLiveTvCategories(
    XtreamCredentialsModel credentials,
  ) {
    return _liveTvService.getCategories(credentials);
  }

  /// Get live TV channels
  Future<ApiResult<List<DomainChannel>>> getLiveTvChannels(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) {
    return _liveTvService.getChannels(credentials, categoryId: categoryId);
  }

  /// Get live TV channels with EPG information
  Future<ApiResult<List<DomainChannel>>> getLiveTvChannelsWithEpg(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) {
    return _liveTvService.getChannelsWithEpg(credentials, categoryId: categoryId);
  }

  /// Get stream URL for a live channel
  String getLiveStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String format = 'm3u8',
  }) {
    return _liveTvService.getStreamUrl(credentials, streamId, format: format);
  }

  /// Refresh live TV data
  Future<ApiResult<void>> refreshLiveTv(
    XtreamCredentialsModel credentials,
  ) {
    return _liveTvService.refresh(credentials);
  }

  // ============ Movies ============

  /// Get all movie categories
  Future<ApiResult<List<DomainCategory>>> getMovieCategories(
    XtreamCredentialsModel credentials,
  ) {
    return _moviesService.getCategories(credentials);
  }

  /// Get movies
  Future<ApiResult<List<VodItem>>> getMovies(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) {
    return _moviesService.getMovies(credentials, categoryId: categoryId);
  }

  /// Get movie details
  Future<ApiResult<VodItem>> getMovieDetails(
    XtreamCredentialsModel credentials,
    String movieId,
  ) {
    return _moviesService.getMovieDetails(credentials, movieId);
  }

  /// Get stream URL for a movie
  String getMovieStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String extension = 'mp4',
  }) {
    return _moviesService.getStreamUrl(credentials, streamId, extension: extension);
  }

  /// Refresh movies data
  Future<ApiResult<void>> refreshMovies(
    XtreamCredentialsModel credentials,
  ) {
    return _moviesService.refresh(credentials);
  }

  // ============ Series ============

  /// Get all series categories
  Future<ApiResult<List<DomainCategory>>> getSeriesCategories(
    XtreamCredentialsModel credentials,
  ) {
    return _seriesService.getCategories(credentials);
  }

  /// Get series
  Future<ApiResult<List<DomainSeries>>> getSeries(
    XtreamCredentialsModel credentials, {
    String? categoryId,
  }) {
    return _seriesService.getSeries(credentials, categoryId: categoryId);
  }

  /// Get series details with seasons and episodes
  Future<ApiResult<DomainSeries>> getSeriesDetails(
    XtreamCredentialsModel credentials,
    String seriesId,
  ) {
    return _seriesService.getSeriesDetails(credentials, seriesId);
  }

  /// Get stream URL for a series episode
  String getSeriesStreamUrl(
    XtreamCredentialsModel credentials,
    String streamId, {
    String extension = 'mp4',
  }) {
    return _seriesService.getStreamUrl(credentials, streamId, extension: extension);
  }

  /// Refresh series data
  Future<ApiResult<void>> refreshSeries(
    XtreamCredentialsModel credentials,
  ) {
    return _seriesService.refresh(credentials);
  }

  // ============ EPG ============

  /// Get EPG for a specific channel
  Future<ApiResult<List<EpgEntry>>> getChannelEpg(
    XtreamCredentialsModel credentials,
    String channelId, {
    int limit = 10,
  }) {
    return _epgService.getChannelEpg(credentials, channelId, limit: limit);
  }

  /// Get EPG for all channels
  Future<ApiResult<Map<String, List<EpgEntry>>>> getAllEpg(
    XtreamCredentialsModel credentials,
  ) {
    return _epgService.getAllEpg(credentials);
  }

  /// Get current program for a channel
  Future<ApiResult<EpgEntry?>> getCurrentProgram(
    XtreamCredentialsModel credentials,
    String channelId,
  ) {
    return _epgService.getCurrentProgram(credentials, channelId);
  }

  /// Refresh EPG data
  Future<ApiResult<void>> refreshEpg(
    XtreamCredentialsModel credentials,
  ) {
    return _epgService.refresh(credentials);
  }

  // ============ Bulk Operations ============

  /// Refresh all data (live TV, movies, series, EPG)
  Future<void> refreshAll(XtreamCredentialsModel credentials) async {
    moduleLogger.info('Refreshing all Xtream data', tag: 'XtreamClient');

    await Future.wait([
      refreshLiveTv(credentials),
      refreshMovies(credentials),
      refreshSeries(credentials),
      refreshEpg(credentials),
    ]);

    moduleLogger.info('All Xtream data refreshed', tag: 'XtreamClient');
  }
}

// Xtream Channel Repository
// Implementation of ChannelRepository that uses Xtream Codes API for data.

import '../../domain/entities/category.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../modules/core/logging/app_logger.dart';
import '../../modules/core/models/base_models.dart' as base;
import '../../modules/xtreamcodes/account/xtream_api_client.dart';
import '../../modules/xtreamcodes/mappers/xtream_mappers.dart';
import '../../modules/xtreamcodes/repositories/xtream_live_repository.dart';
import '../../modules/xtreamcodes/repositories/xtream_vod_repository.dart';
import '../../modules/xtreamcodes/xtream_service_manager.dart';
import '../datasources/local/local_storage.dart';
import '../models/channel_model.dart';

/// Channel repository implementation using Xtream Codes API
class XtreamChannelRepository implements ChannelRepository {
  XtreamChannelRepository({
    required XtreamServiceManager serviceManager,
    required LocalStorage localStorage,
  })  : _serviceManager = serviceManager,
        _localStorage = localStorage;

  final XtreamServiceManager _serviceManager;
  final LocalStorage _localStorage;

  /// Check if Xtream service is available
  bool get _isXtreamAvailable => _serviceManager.isInitialized;

  /// Get the live repository (throws if not initialized)
  IXtreamLiveRepository get _liveRepository =>
      _serviceManager.repositoryFactory.liveRepository;

  /// Get the VOD repository (throws if not initialized)
  IXtreamVodRepository get _vodRepository =>
      _serviceManager.repositoryFactory.vodRepository;

  /// Get the API client (throws if not initialized)
  XtreamApiClient get _apiClient =>
      _serviceManager.repositoryFactory.apiClient;

  @override
  Future<List<Channel>> getLiveChannels({String? categoryId}) async {
    if (!_isXtreamAvailable) {
      moduleLogger.warning(
        'Xtream service not initialized, returning empty list',
        tag: 'XtreamChannelRepo',
      );
      return [];
    }

    try {
      moduleLogger.info(
        'Fetching live channels from Xtream (categoryId: $categoryId)',
        tag: 'XtreamChannelRepo',
      );

      final result = await _liveRepository.getLiveChannels(
        categoryId: categoryId,
      );

      if (result.isFailure) {
        moduleLogger.error(
          'Failed to get live channels: ${result.error.message}',
          tag: 'XtreamChannelRepo',
        );
        return [];
      }

      // Convert domain channels to entity channels
      final channels = result.data
          .map((domainChannel) => _domainChannelToEntity(domainChannel))
          .toList();

      moduleLogger.info(
        'Retrieved ${channels.length} live channels',
        tag: 'XtreamChannelRepo',
      );

      return channels;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error fetching live channels',
        tag: 'XtreamChannelRepo',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<Category>> getLiveCategories() async {
    if (!_isXtreamAvailable) {
      moduleLogger.warning(
        'Xtream service not initialized, returning empty list',
        tag: 'XtreamChannelRepo',
      );
      return [];
    }

    try {
      moduleLogger.info(
        'Fetching live categories from Xtream',
        tag: 'XtreamChannelRepo',
      );

      final result = await _liveRepository.getLiveCategories();

      if (result.isFailure) {
        moduleLogger.error(
          'Failed to get live categories: ${result.error.message}',
          tag: 'XtreamChannelRepo',
        );
        return [];
      }

      // Convert domain categories to entity categories
      final categories = result.data
          .map((domainCategory) => _domainCategoryToEntity(domainCategory))
          .toList();

      moduleLogger.info(
        'Retrieved ${categories.length} live categories',
        tag: 'XtreamChannelRepo',
      );

      return categories;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error fetching live categories',
        tag: 'XtreamChannelRepo',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<Movie>> getMovies({String? categoryId}) async {
    if (!_isXtreamAvailable) {
      moduleLogger.warning(
        'Xtream service not initialized, returning empty list',
        tag: 'XtreamChannelRepo',
      );
      return [];
    }

    try {
      moduleLogger.info(
        'Fetching movies from Xtream (categoryId: $categoryId)',
        tag: 'XtreamChannelRepo',
      );

      final result = await _vodRepository.getVodItems(
        categoryId: categoryId,
      );

      if (result.isFailure) {
        moduleLogger.error(
          'Failed to get movies: ${result.error.message}',
          tag: 'XtreamChannelRepo',
        );
        return [];
      }

      // Convert VOD items to Movie entities
      final List<Movie> movies =
          result.data.map((vodItem) => _vodItemToMovie(vodItem)).toList();

      moduleLogger.info(
        'Retrieved ${movies.length} movies',
        tag: 'XtreamChannelRepo',
      );

      return movies;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error fetching movies',
        tag: 'XtreamChannelRepo',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<Category>> getMovieCategories() async {
    if (!_isXtreamAvailable) {
      moduleLogger.warning(
        'Xtream service not initialized, returning empty list',
        tag: 'XtreamChannelRepo',
      );
      return [];
    }

    try {
      moduleLogger.info(
        'Fetching movie categories from Xtream',
        tag: 'XtreamChannelRepo',
      );

      final result = await _vodRepository.getVodCategories();

      if (result.isFailure) {
        moduleLogger.error(
          'Failed to get movie categories: ${result.error.message}',
          tag: 'XtreamChannelRepo',
        );
        return [];
      }

      // Convert domain categories to entity categories
      final categories = result.data
          .map((domainCategory) => _domainCategoryToEntity(domainCategory))
          .toList();

      moduleLogger.info(
        'Retrieved ${categories.length} movie categories',
        tag: 'XtreamChannelRepo',
      );

      return categories;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error fetching movie categories',
        tag: 'XtreamChannelRepo',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<Series>> getAllSeries({String? categoryId}) async {
    if (!_isXtreamAvailable) {
      moduleLogger.warning(
        'Xtream service not initialized, returning empty list',
        tag: 'XtreamChannelRepo',
      );
      return [];
    }

    try {
      moduleLogger.info(
        'Fetching series from Xtream (categoryId: $categoryId)',
        tag: 'XtreamChannelRepo',
      );

      // Use API client directly for series as VOD repository doesn't expose it
      final result = await _apiClient.getSeries(categoryId: categoryId);

      if (result.isFailure) {
        moduleLogger.error(
          'Failed to get series: ${result.error.message}',
          tag: 'XtreamChannelRepo',
        );
        return [];
      }

      // Convert Xtream series to entity series
      final series = result.data
          .map((xtreamSeries) => _xtreamSeriesToEntity(xtreamSeries))
          .toList();

      moduleLogger.info(
        'Retrieved ${series.length} series',
        tag: 'XtreamChannelRepo',
      );

      return series;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error fetching series',
        tag: 'XtreamChannelRepo',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<Category>> getSeriesCategories() async {
    if (!_isXtreamAvailable) {
      moduleLogger.warning(
        'Xtream service not initialized, returning empty list',
        tag: 'XtreamChannelRepo',
      );
      return [];
    }

    try {
      moduleLogger.info(
        'Fetching series categories from Xtream',
        tag: 'XtreamChannelRepo',
      );

      // Use API client directly for series categories
      final result = await _apiClient.getSeriesCategories();

      if (result.isFailure) {
        moduleLogger.error(
          'Failed to get series categories: ${result.error.message}',
          tag: 'XtreamChannelRepo',
        );
        return [];
      }

      // Convert Xtream categories to entity categories
      final categories = result.data
          .map((cat) => XtreamMappers.seriesCategoryToCategory(cat))
          .map((domainCategory) => _domainCategoryToEntity(domainCategory))
          .toList();

      moduleLogger.info(
        'Retrieved ${categories.length} series categories',
        tag: 'XtreamChannelRepo',
      );

      return categories;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error fetching series categories',
        tag: 'XtreamChannelRepo',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<Series> getSeriesDetails(String seriesId) async {
    if (!_isXtreamAvailable) {
      throw StateError('Xtream service not initialized');
    }

    try {
      moduleLogger.info(
        'Fetching series details from Xtream (seriesId: $seriesId)',
        tag: 'XtreamChannelRepo',
      );

      // Extract the actual series ID (remove prefix if present)
      final actualSeriesId = seriesId.startsWith('xtream_series_')
          ? seriesId.replaceFirst('xtream_series_', '')
          : seriesId;

      final result = await _apiClient.getSeriesInfo(actualSeriesId);

      if (result.isFailure) {
        throw Exception('Failed to get series details: ${result.error.message}');
      }

      // Convert Xtream series info to entity series
      final domainSeries = XtreamMappers.seriesInfoToDoMainSeries(
        result.data,
        actualSeriesId,
        _apiClient,
      );

      return _domainSeriesToEntity(domainSeries);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error fetching series details',
        tag: 'XtreamChannelRepo',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<SearchResult> search(String query) async {
    if (!_isXtreamAvailable) {
      return const SearchResult(
        channels: [],
        movies: [],
        series: [],
      );
    }

    try {
      final lowerQuery = query.toLowerCase();

      // Get all content and filter locally
      final channelsResult = await _liveRepository.getLiveChannels();
      final moviesResult = await _vodRepository.getVodItems();
      final seriesResult = await _apiClient.getSeries();

      final channels = channelsResult.isSuccess
          ? channelsResult.data
              .where((c) => c.name.toLowerCase().contains(lowerQuery))
              .map((c) => _domainChannelToEntity(c))
              .toList()
          : <Channel>[];

      final movies = moviesResult.isSuccess
          ? moviesResult.data
              .where((m) => m.name.toLowerCase().contains(lowerQuery))
              .map((m) => _vodItemToMovie(m))
              .toList()
          : <Movie>[];

      final series = seriesResult.isSuccess
          ? seriesResult.data
              .where((s) => s.name.toLowerCase().contains(lowerQuery))
              .map((s) => _xtreamSeriesToEntity(s))
              .toList()
          : <Series>[];

      return SearchResult(
        channels: channels,
        movies: movies,
        series: series,
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error searching content',
        tag: 'XtreamChannelRepo',
        error: e,
        stackTrace: stackTrace,
      );
      return const SearchResult(
        channels: [],
        movies: [],
        series: [],
      );
    }
  }

  @override
  Future<Channel?> getChannelById(String id) async {
    if (!_isXtreamAvailable) return null;

    try {
      final result = await _liveRepository.getLiveChannels();
      if (result.isFailure) return null;

      final channel = result.data.where((c) => c.id == id).firstOrNull;
      return channel != null ? _domainChannelToEntity(channel) : null;
    } catch (e) {
      moduleLogger.error(
        'Error getting channel by ID',
        tag: 'XtreamChannelRepo',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<Movie?> getMovieById(String id) async {
    if (!_isXtreamAvailable) return null;

    try {
      final result = await _vodRepository.getVodInfo(id);
      if (result.isFailure) return null;

      return _vodItemToMovie(result.data);
    } catch (e) {
      moduleLogger.error(
        'Error getting movie by ID',
        tag: 'XtreamChannelRepo',
        error: e,
      );
      return null;
    }
  }

  // Favorites and recent channels use local storage

  @override
  Future<List<Channel>> getFavorites() async {
    final models = await _localStorage.getFavorites();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addToFavorites(Channel channel) async {
    await _localStorage.addFavorite(ChannelModel.fromEntity(channel));
  }

  @override
  Future<void> removeFromFavorites(String channelId) async {
    await _localStorage.removeFavorite(channelId);
  }

  @override
  Future<bool> isFavorite(String channelId) async {
    final favorites = await _localStorage.getFavorites();
    return favorites.any((f) => f.id == channelId);
  }

  @override
  Future<List<Channel>> getRecentChannels() async {
    final models = await _localStorage.getRecentChannels();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addToRecent(Channel channel) async {
    await _localStorage.addRecentChannel(ChannelModel.fromEntity(channel));
  }

  // Mapper methods

  /// Convert domain channel to entity channel
  Channel _domainChannelToEntity(base.DomainChannel domainChannel) {
    return Channel(
      id: domainChannel.id,
      name: domainChannel.name,
      streamUrl: domainChannel.streamUrl,
      logoUrl: domainChannel.logoUrl,
      groupTitle: domainChannel.groupTitle,
      categoryId: domainChannel.categoryId,
      type: _convertContentType(domainChannel.type),
      metadata: domainChannel.metadata,
      epgInfo: domainChannel.epgInfo != null
          ? EpgInfo(
              currentProgram: domainChannel.epgInfo!.currentProgram,
              nextProgram: domainChannel.epgInfo!.nextProgram,
              startTime: domainChannel.epgInfo!.startTime,
              endTime: domainChannel.epgInfo!.endTime,
              description: domainChannel.epgInfo!.description,
            )
          : null,
    );
  }

  /// Convert domain category to entity category
  Category _domainCategoryToEntity(base.DomainCategory domainCategory) {
    return Category(
      id: domainCategory.id,
      name: domainCategory.name,
      channelCount: domainCategory.channelCount,
    );
  }

  /// Convert VOD item to Movie entity
  Movie _vodItemToMovie(base.VodItem vodItem) {
    return Movie(
      id: vodItem.id,
      name: vodItem.name,
      streamUrl: vodItem.streamUrl,
      posterUrl: vodItem.posterUrl,
      backdropUrl: vodItem.backdropUrl,
      categoryId: vodItem.categoryId,
      description: vodItem.description,
      releaseDate: vodItem.releaseDate,
      rating: vodItem.rating,
      duration: vodItem.duration,
      genre: vodItem.genre,
      metadata: vodItem.metadata,
    );
  }

  /// Convert domain series to entity series
  Series _domainSeriesToEntity(base.DomainSeries domainSeries) {
    return Series(
      id: domainSeries.id,
      name: domainSeries.name,
      posterUrl: domainSeries.posterUrl,
      backdropUrl: domainSeries.backdropUrl,
      categoryId: domainSeries.categoryId,
      description: domainSeries.description,
      releaseDate: domainSeries.releaseDate,
      rating: domainSeries.rating,
      genre: domainSeries.genre,
      seasons: domainSeries.seasons
          .map((s) => _domainSeasonToEntity(s))
          .toList(),
      metadata: domainSeries.metadata,
    );
  }

  /// Convert Xtream series to entity series (without seasons)
  Series _xtreamSeriesToEntity(
    dynamic xtreamSeries,
  ) {
    // Use mapper to convert to domain series first
    final domainSeries = XtreamMappers.seriesToDomainSeries(
      xtreamSeries,
      _apiClient,
    );
    return _domainSeriesToEntity(domainSeries);
  }

  /// Convert domain season to entity season
  Season _domainSeasonToEntity(base.Season domainSeason) {
    return Season(
      id: domainSeason.id,
      seasonNumber: domainSeason.seasonNumber,
      name: domainSeason.name,
      posterUrl: domainSeason.posterUrl,
      episodes: domainSeason.episodes
          .map((e) => _domainEpisodeToEntity(e))
          .toList(),
    );
  }

  /// Convert domain episode to entity episode
  Episode _domainEpisodeToEntity(base.Episode domainEpisode) {
    return Episode(
      id: domainEpisode.id,
      episodeNumber: domainEpisode.episodeNumber,
      name: domainEpisode.name,
      streamUrl: domainEpisode.streamUrl,
      description: domainEpisode.description,
      duration: domainEpisode.duration,
    );
  }

  /// Convert content type from base models to domain entities
  ContentType _convertContentType(base.ContentType type) {
    switch (type) {
      case base.ContentType.live:
        return ContentType.live;
      case base.ContentType.movie:
        return ContentType.movie;
      case base.ContentType.series:
        return ContentType.series;
    }
  }
}

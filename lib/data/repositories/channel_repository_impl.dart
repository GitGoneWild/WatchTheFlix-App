import '../../domain/entities/channel.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../features/xtream/xtream_api_client.dart';
import '../datasources/local/local_storage.dart';
import '../models/channel_model.dart';

/// Channel repository implementation
class ChannelRepositoryImpl implements ChannelRepository {
  final PlaylistRepository _playlistRepository;
  final XtreamApiClient _xtreamApiClient;
  late final LocalStorage _localStorage;

  // In-memory cache
  List<Channel>? _channelCache;
  List<Category>? _categoryCache;
  List<Movie>? _movieCache;
  List<Series>? _seriesCache;

  ChannelRepositoryImpl({
    required PlaylistRepository playlistRepository,
    required XtreamApiClient xtreamApiClient,
  })  : _playlistRepository = playlistRepository,
        _xtreamApiClient = xtreamApiClient;

  void setLocalStorage(LocalStorage localStorage) {
    _localStorage = localStorage;
  }

  @override
  Future<List<Channel>> getLiveChannels({String? categoryId}) async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

    if (activePlaylist.isXtream && activePlaylist.xtreamCredentials != null) {
      final channels = await _xtreamApiClient.fetchLiveChannels(
        activePlaylist.xtreamCredentials!,
        categoryId: categoryId,
      );
      _channelCache = channels.map((c) => c.toEntity()).toList();
      return _channelCache!;
    }

    final channels = categoryId != null
        ? await _playlistRepository.getChannelsByCategory(
            activePlaylist.id,
            categoryId,
          )
        : await _playlistRepository.refreshPlaylist(activePlaylist.id);

    _channelCache = channels.where((c) => c.type == ContentType.live).toList();
    return _channelCache!;
  }

  @override
  Future<List<Category>> getLiveCategories() async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

    if (activePlaylist.isXtream && activePlaylist.xtreamCredentials != null) {
      final categories = await _xtreamApiClient.fetchLiveCategories(
        activePlaylist.xtreamCredentials!,
      );
      _categoryCache = categories.map((c) => c.toEntity()).toList();
      return _categoryCache!;
    }

    _categoryCache = await _playlistRepository.getCategories(activePlaylist.id);
    return _categoryCache!;
  }

  @override
  Future<List<Movie>> getMovies({String? categoryId}) async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

    if (activePlaylist.isXtream && activePlaylist.xtreamCredentials != null) {
      final movies = await _xtreamApiClient.fetchMovies(
        activePlaylist.xtreamCredentials!,
        categoryId: categoryId,
      );
      _movieCache = movies.map((m) => m.toEntity()).toList();
      return _movieCache!;
    }

    // For M3U, filter channels by movie type
    final channels = await _playlistRepository.refreshPlaylist(activePlaylist.id);
    return channels
        .where((c) => c.type == ContentType.movie)
        .map(
          (c) => Movie(
            id: c.id,
            name: c.name,
            streamUrl: c.streamUrl,
            posterUrl: c.logoUrl,
            categoryId: c.categoryId,
          ),
        )
        .toList();
  }

  @override
  Future<List<Category>> getMovieCategories() async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

    if (activePlaylist.isXtream && activePlaylist.xtreamCredentials != null) {
      final categories = await _xtreamApiClient.fetchMovieCategories(
        activePlaylist.xtreamCredentials!,
      );
      return categories.map((c) => c.toEntity()).toList();
    }

    return [];
  }

  @override
  Future<List<Series>> getAllSeries({String? categoryId}) async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

    if (activePlaylist.isXtream && activePlaylist.xtreamCredentials != null) {
      final series = await _xtreamApiClient.fetchSeries(
        activePlaylist.xtreamCredentials!,
        categoryId: categoryId,
      );
      _seriesCache = series.map((s) => s.toEntity()).toList();
      return _seriesCache!;
    }

    return [];
  }

  @override
  Future<List<Category>> getSeriesCategories() async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

    if (activePlaylist.isXtream && activePlaylist.xtreamCredentials != null) {
      final categories = await _xtreamApiClient.fetchSeriesCategories(
        activePlaylist.xtreamCredentials!,
      );
      return categories.map((c) => c.toEntity()).toList();
    }

    return [];
  }

  @override
  Future<Series> getSeriesDetails(String seriesId) async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null || !activePlaylist.isXtream) {
      throw Exception('Series details only available for Xtream sources');
    }

    final seriesModel = await _xtreamApiClient.fetchSeriesInfo(
      activePlaylist.xtreamCredentials!,
      seriesId,
    );
    return seriesModel.toEntity();
  }

  @override
  Future<SearchResult> search(String query) async {
    final lowerQuery = query.toLowerCase();

    // Search in cached data
    final channels = (_channelCache ?? [])
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .toList();

    final movies = (_movieCache ?? [])
        .where((m) => m.name.toLowerCase().contains(lowerQuery))
        .toList();

    final series = (_seriesCache ?? [])
        .where((s) => s.name.toLowerCase().contains(lowerQuery))
        .toList();

    return SearchResult(
      channels: channels,
      movies: movies,
      series: series,
    );
  }

  @override
  Future<Channel?> getChannelById(String id) async {
    return _channelCache?.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<Movie?> getMovieById(String id) async {
    return _movieCache?.where((m) => m.id == id).firstOrNull;
  }

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
}

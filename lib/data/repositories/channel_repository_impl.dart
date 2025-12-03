import '../../domain/entities/channel.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../datasources/local/local_storage.dart';
import '../models/channel_model.dart';

/// Channel repository implementation
class ChannelRepositoryImpl implements ChannelRepository {
  ChannelRepositoryImpl({
    required PlaylistRepository playlistRepository,
    required LocalStorage localStorage,
  })  : _playlistRepository = playlistRepository,
        _localStorage = localStorage;
  final PlaylistRepository _playlistRepository;
  final LocalStorage _localStorage;

  // In-memory cache
  List<Channel>? _channelCache;
  List<Category>? _categoryCache;
  List<Movie>? _movieCache;
  List<Series>? _seriesCache;

  @override
  Future<List<Channel>> getLiveChannels({String? categoryId}) async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

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

    _categoryCache = await _playlistRepository.getCategories(activePlaylist.id);
    return _categoryCache!;
  }

  @override
  Future<List<Movie>> getMovies({String? categoryId}) async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

    // For M3U, filter channels by movie type
    final channels =
        await _playlistRepository.refreshPlaylist(activePlaylist.id);
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

    return [];
  }

  @override
  Future<List<Series>> getAllSeries({String? categoryId}) async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

    return [];
  }

  @override
  Future<List<Category>> getSeriesCategories() async {
    final activePlaylist = await _playlistRepository.getActivePlaylist();
    if (activePlaylist == null) return [];

    return [];
  }

  @override
  Future<Series> getSeriesDetails(String seriesId) async {
    throw Exception('Series details not available for M3U sources');
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

  @override
  Future<void> removeFromRecent(String channelId) async {
    await _localStorage.removeRecentChannel(channelId);
  }

  @override
  Future<void> clearRecentHistory() async {
    await _localStorage.clearRecentChannels();
  }
}

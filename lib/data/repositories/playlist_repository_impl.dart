import '../../core/utils/logger.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/playlist_source.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../features/m3u/m3u_parser.dart';
import '../datasources/local/local_storage.dart';
import '../datasources/remote/api_client.dart';
import '../models/category_model.dart';
import '../models/channel_model.dart';
import '../models/playlist_source_model.dart';

/// Playlist repository implementation
class PlaylistRepositoryImpl implements PlaylistRepository {
  final LocalStorage _localStorage;
  final ApiClient _apiClient;
  final M3UParser _m3uParser;

  // In-memory cache
  final Map<String, List<ChannelModel>> _channelCache = {};
  final Map<String, List<CategoryModel>> _categoryCache = {};

  PlaylistRepositoryImpl({
    required LocalStorage localStorage,
    required ApiClient apiClient,
    required M3UParser m3uParser,
  })  : _localStorage = localStorage,
        _apiClient = apiClient,
        _m3uParser = m3uParser;

  @override
  Future<List<PlaylistSource>> getPlaylists() async {
    final models = await _localStorage.getPlaylists();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PlaylistSource> addPlaylist(PlaylistSource playlist) async {
    final model = PlaylistSourceModel.fromEntity(playlist);
    await _localStorage.addPlaylist(model);
    AppLogger.info('Playlist added: ${playlist.name}');
    return playlist;
  }

  @override
  Future<PlaylistSource> updatePlaylist(PlaylistSource playlist) async {
    final playlists = await _localStorage.getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      playlists[index] = PlaylistSourceModel.fromEntity(playlist);
      await _localStorage.savePlaylists(playlists);
    }
    return playlist;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await _localStorage.deletePlaylist(id);
    _channelCache.remove(id);
    _categoryCache.remove(id);
    AppLogger.info('Playlist deleted: $id');
  }

  @override
  Future<void> setActivePlaylist(String id) async {
    await _localStorage.setActivePlaylistId(id);
  }

  @override
  Future<PlaylistSource?> getActivePlaylist() async {
    final activeId = await _localStorage.getActivePlaylistId();
    if (activeId == null) return null;

    final playlists = await getPlaylists();
    return playlists.where((p) => p.id == activeId).firstOrNull;
  }

  @override
  Future<List<Channel>> refreshPlaylist(String id) async {
    final playlists = await _localStorage.getPlaylists();
    final playlist = playlists.where((p) => p.id == id).firstOrNull;

    if (playlist == null) return [];

    List<ChannelModel> channels;

    if (playlist.type == 'm3uUrl' || playlist.type == 'm3uFile') {
      final content = await _apiClient.download(playlist.url);
      channels = _m3uParser.parse(content);
    } else {
      // For Xtream, channels are fetched via XtreamApiClient separately
      channels = [];
    }

    _channelCache[id] = channels;
    await _localStorage.cacheChannels(id, channels);

    return channels.map((c) => c.toEntity()).toList();
  }

  @override
  Future<List<Channel>> parseM3U(String content) async {
    final channels = _m3uParser.parse(content);
    return channels.map((c) => c.toEntity()).toList();
  }

  @override
  Future<List<Channel>> parseM3UFromUrl(String url) async {
    final content = await _apiClient.download(url);
    return parseM3U(content);
  }

  @override
  Future<List<Category>> getCategories(String playlistId) async {
    if (_categoryCache.containsKey(playlistId)) {
      return _categoryCache[playlistId]!.map((c) => c.toEntity()).toList();
    }

    // Get channels and extract unique categories
    final channels = await _getChannelsForPlaylist(playlistId);
    final categoryMap = <String, CategoryModel>{};

    for (final channel in channels) {
      final groupTitle = channel.groupTitle;
      if (groupTitle != null && groupTitle.isNotEmpty) {
        if (!categoryMap.containsKey(groupTitle)) {
          categoryMap[groupTitle] = CategoryModel(
            id: groupTitle,
            name: groupTitle,
            channelCount: 1,
          );
        } else {
          final existing = categoryMap[groupTitle]!;
          categoryMap[groupTitle] = CategoryModel(
            id: existing.id,
            name: existing.name,
            channelCount: existing.channelCount + 1,
          );
        }
      }
    }

    final categories = categoryMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    _categoryCache[playlistId] = categories;
    return categories.map((c) => c.toEntity()).toList();
  }

  @override
  Future<List<Channel>> getChannelsByCategory(
    String playlistId,
    String categoryId,
  ) async {
    final channels = await _getChannelsForPlaylist(playlistId);
    return channels
        .where(
          (c) => c.groupTitle == categoryId || c.categoryId == categoryId,
        )
        .map((c) => c.toEntity())
        .toList();
  }

  @override
  Future<List<Channel>> searchChannels(String playlistId, String query) async {
    final channels = await _getChannelsForPlaylist(playlistId);
    final lowerQuery = query.toLowerCase();

    return channels
        .where(
          (c) =>
              c.name.toLowerCase().contains(lowerQuery) ||
              (c.groupTitle?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .map((c) => c.toEntity())
        .toList();
  }

  Future<List<ChannelModel>> _getChannelsForPlaylist(String playlistId) async {
    if (_channelCache.containsKey(playlistId)) {
      return _channelCache[playlistId]!;
    }

    final cached = await _localStorage.getCachedChannels(playlistId);
    if (cached != null) {
      _channelCache[playlistId] = cached;
      return cached;
    }

    // Fetch fresh data
    final channels = await refreshPlaylist(playlistId);
    return channels.map((c) => ChannelModel.fromEntity(c)).toList();
  }
}

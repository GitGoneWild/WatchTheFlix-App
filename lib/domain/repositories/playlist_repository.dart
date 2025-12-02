import '../entities/category.dart';
import '../entities/channel.dart';
import '../entities/playlist_source.dart';

/// Playlist repository interface
abstract class PlaylistRepository {
  /// Get all playlist sources
  Future<List<PlaylistSource>> getPlaylists();

  /// Add a new playlist source
  Future<PlaylistSource> addPlaylist(PlaylistSource playlist);

  /// Update an existing playlist
  Future<PlaylistSource> updatePlaylist(PlaylistSource playlist);

  /// Delete a playlist
  Future<void> deletePlaylist(String id);

  /// Set active playlist
  Future<void> setActivePlaylist(String id);

  /// Get active playlist
  Future<PlaylistSource?> getActivePlaylist();

  /// Refresh playlist data
  Future<List<Channel>> refreshPlaylist(String id);

  /// Parse M3U content
  Future<List<Channel>> parseM3U(String content);

  /// Parse M3U from URL
  Future<List<Channel>> parseM3UFromUrl(String url);

  /// Get categories from playlist
  Future<List<Category>> getCategories(String playlistId);

  /// Get channels by category
  Future<List<Channel>> getChannelsByCategory(
    String playlistId,
    String categoryId,
  );

  /// Search channels
  Future<List<Channel>> searchChannels(String playlistId, String query);
}

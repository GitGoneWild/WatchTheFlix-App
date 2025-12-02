import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/channel_model.dart';
import '../../models/playlist_source_model.dart';

/// Local storage interface
abstract class LocalStorage {
  /// Get all playlist sources
  Future<List<PlaylistSourceModel>> getPlaylists();

  /// Save playlist sources
  Future<void> savePlaylists(List<PlaylistSourceModel> playlists);

  /// Add playlist source
  Future<void> addPlaylist(PlaylistSourceModel playlist);

  /// Delete playlist source
  Future<void> deletePlaylist(String id);

  /// Get active playlist ID
  Future<String?> getActivePlaylistId();

  /// Set active playlist ID
  Future<void> setActivePlaylistId(String id);

  /// Get cached channels for playlist
  Future<List<ChannelModel>?> getCachedChannels(String playlistId);

  /// Save cached channels for playlist
  Future<void> cacheChannels(String playlistId, List<ChannelModel> channels);

  /// Get favorites
  Future<List<ChannelModel>> getFavorites();

  /// Add to favorites
  Future<void> addFavorite(ChannelModel channel);

  /// Remove from favorites
  Future<void> removeFavorite(String channelId);

  /// Get recent channels
  Future<List<ChannelModel>> getRecentChannels();

  /// Add to recent channels
  Future<void> addRecentChannel(ChannelModel channel);

  /// Get settings
  Future<Map<String, dynamic>?> getSettings();

  /// Save settings
  Future<void> saveSettings(Map<String, dynamic> settings);

  /// Clear all data
  Future<void> clearAll();
}

/// Local storage implementation using SharedPreferences
class LocalStorageImpl implements LocalStorage {
  LocalStorageImpl({required SharedPreferences sharedPreferences})
      : _sharedPreferences = sharedPreferences;
  final SharedPreferences _sharedPreferences;

  @override
  Future<List<PlaylistSourceModel>> getPlaylists() async {
    try {
      final jsonString =
          _sharedPreferences.getString(AppConstants.keyPlaylistSources);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map(
            (json) =>
                PlaylistSourceModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get playlists: $e');
    }
  }

  @override
  Future<void> savePlaylists(List<PlaylistSourceModel> playlists) async {
    try {
      final jsonList = playlists.map((p) => p.toJson()).toList();
      await _sharedPreferences.setString(
        AppConstants.keyPlaylistSources,
        json.encode(jsonList),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save playlists: $e');
    }
  }

  @override
  Future<void> addPlaylist(PlaylistSourceModel playlist) async {
    final playlists = await getPlaylists();
    playlists.add(playlist);
    await savePlaylists(playlists);
  }

  @override
  Future<void> deletePlaylist(String id) async {
    final playlists = await getPlaylists();
    playlists.removeWhere((p) => p.id == id);
    await savePlaylists(playlists);
  }

  @override
  Future<String?> getActivePlaylistId() async {
    return _sharedPreferences.getString(AppConstants.keyActivePlaylist);
  }

  @override
  Future<void> setActivePlaylistId(String id) async {
    await _sharedPreferences.setString(AppConstants.keyActivePlaylist, id);
  }

  @override
  Future<List<ChannelModel>?> getCachedChannels(String playlistId) async {
    try {
      final jsonString =
          _sharedPreferences.getString('cached_channels_$playlistId');
      if (jsonString == null) return null;

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => ChannelModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheChannels(
    String playlistId,
    List<ChannelModel> channels,
  ) async {
    try {
      final jsonList = channels.map((c) => c.toJson()).toList();
      await _sharedPreferences.setString(
        'cached_channels_$playlistId',
        json.encode(jsonList),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache channels: $e');
    }
  }

  @override
  Future<List<ChannelModel>> getFavorites() async {
    try {
      final jsonString =
          _sharedPreferences.getString(AppConstants.keyFavorites);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => ChannelModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addFavorite(ChannelModel channel) async {
    final favorites = await getFavorites();
    if (!favorites.any((f) => f.id == channel.id)) {
      favorites.add(channel);
      final jsonList = favorites.map((c) => c.toJson()).toList();
      await _sharedPreferences.setString(
        AppConstants.keyFavorites,
        json.encode(jsonList),
      );
    }
  }

  @override
  Future<void> removeFavorite(String channelId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((f) => f.id == channelId);
    final jsonList = favorites.map((c) => c.toJson()).toList();
    await _sharedPreferences.setString(
      AppConstants.keyFavorites,
      json.encode(jsonList),
    );
  }

  @override
  Future<List<ChannelModel>> getRecentChannels() async {
    try {
      final jsonString =
          _sharedPreferences.getString(AppConstants.keyRecentChannels);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => ChannelModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addRecentChannel(ChannelModel channel) async {
    final recent = await getRecentChannels();
    recent.removeWhere((r) => r.id == channel.id);
    recent.insert(0, channel);
    // Keep only last 20 recent channels
    final trimmed = recent.take(20).toList();
    final jsonList = trimmed.map((c) => c.toJson()).toList();
    await _sharedPreferences.setString(
      AppConstants.keyRecentChannels,
      json.encode(jsonList),
    );
  }

  @override
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final jsonString = _sharedPreferences.getString(AppConstants.keySettings);
      if (jsonString == null) return null;
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _sharedPreferences.setString(
      AppConstants.keySettings,
      json.encode(settings),
    );
  }

  @override
  Future<void> clearAll() async {
    await _sharedPreferences.clear();
  }
}

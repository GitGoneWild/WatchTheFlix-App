import '../../domain/entities/playlist_source.dart';

/// Playlist source model for data layer
class PlaylistSourceModel {
  final String id;
  final String name;
  final String url;
  final String type;
  final DateTime addedAt;
  final DateTime? lastUpdated;
  final XtreamCredentialsModel? xtreamCredentials;
  final bool isActive;

  const PlaylistSourceModel({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.addedAt,
    this.lastUpdated,
    this.xtreamCredentials,
    this.isActive = true,
  });

  /// Create from JSON
  factory PlaylistSourceModel.fromJson(Map<String, dynamic> json) {
    return PlaylistSourceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? 'm3uUrl',
      addedAt: DateTime.tryParse(json['added_at'] as String? ?? '') ??
          DateTime.now(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'] as String)
          : null,
      xtreamCredentials: json['xtream_credentials'] != null
          ? XtreamCredentialsModel.fromJson(
              json['xtream_credentials'] as Map<String, dynamic>)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'added_at': addedAt.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
      'xtream_credentials': xtreamCredentials?.toJson(),
      'is_active': isActive,
    };
  }

  /// Convert to domain entity
  PlaylistSource toEntity() {
    return PlaylistSource(
      id: id,
      name: name,
      url: url,
      type: _parseSourceType(type),
      addedAt: addedAt,
      lastUpdated: lastUpdated,
      xtreamCredentials: xtreamCredentials?.toEntity(),
      isActive: isActive,
    );
  }

  /// Create from domain entity
  factory PlaylistSourceModel.fromEntity(PlaylistSource entity) {
    return PlaylistSourceModel(
      id: entity.id,
      name: entity.name,
      url: entity.url,
      type: entity.type.name,
      addedAt: entity.addedAt,
      lastUpdated: entity.lastUpdated,
      xtreamCredentials: entity.xtreamCredentials != null
          ? XtreamCredentialsModel.fromEntity(entity.xtreamCredentials!)
          : null,
      isActive: entity.isActive,
    );
  }

  PlaylistSourceType _parseSourceType(String type) {
    switch (type) {
      case 'm3uFile':
        return PlaylistSourceType.m3uFile;
      case 'xtream':
        return PlaylistSourceType.xtream;
      default:
        return PlaylistSourceType.m3uUrl;
    }
  }
}

/// Xtream credentials model
class XtreamCredentialsModel {
  final String host;
  final String username;
  final String password;
  final String? serverInfo;

  const XtreamCredentialsModel({
    required this.host,
    required this.username,
    required this.password,
    this.serverInfo,
  });

  factory XtreamCredentialsModel.fromJson(Map<String, dynamic> json) {
    return XtreamCredentialsModel(
      host: json['host'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      serverInfo: json['server_info'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'username': username,
      'password': password,
      'server_info': serverInfo,
    };
  }

  XtreamCredentials toEntity() {
    return XtreamCredentials(
      host: host,
      username: username,
      password: password,
      serverInfo: serverInfo,
    );
  }

  factory XtreamCredentialsModel.fromEntity(XtreamCredentials entity) {
    return XtreamCredentialsModel(
      host: entity.host,
      username: entity.username,
      password: entity.password,
      serverInfo: entity.serverInfo,
    );
  }
}

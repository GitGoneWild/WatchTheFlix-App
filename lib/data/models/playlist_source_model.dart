import '../../domain/entities/playlist_source.dart';

/// Playlist source model for data layer
class PlaylistSourceModel {
  const PlaylistSourceModel({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.addedAt,
    this.lastUpdated,
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
      isActive: json['is_active'] as bool? ?? true,
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
      isActive: entity.isActive,
    );
  }
  final String id;
  final String name;
  final String url;
  final String type;
  final DateTime addedAt;
  final DateTime? lastUpdated;
  final bool isActive;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'added_at': addedAt.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
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
      isActive: isActive,
    );
  }

  PlaylistSourceType _parseSourceType(String type) {
    switch (type) {
      case 'm3uFile':
        return PlaylistSourceType.m3uFile;
      default:
        return PlaylistSourceType.m3uUrl;
    }
  }
}

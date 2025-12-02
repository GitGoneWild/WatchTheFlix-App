import 'package:equatable/equatable.dart';

/// Playlist source type
enum PlaylistSourceType {
  m3uFile,
  m3uUrl,
}

/// Playlist source entity
class PlaylistSource extends Equatable {
  const PlaylistSource({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.addedAt,
    this.lastUpdated,
    this.isActive = true,
  });
  final String id;
  final String name;
  final String url;
  final PlaylistSourceType type;
  final DateTime addedAt;
  final DateTime? lastUpdated;
  final bool isActive;

  /// Check if this is an M3U source
  bool get isM3U =>
      type == PlaylistSourceType.m3uFile || type == PlaylistSourceType.m3uUrl;

  PlaylistSource copyWith({
    String? id,
    String? name,
    String? url,
    PlaylistSourceType? type,
    DateTime? addedAt,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return PlaylistSource(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      addedAt: addedAt ?? this.addedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        url,
        type,
        addedAt,
        lastUpdated,
        isActive,
      ];
}

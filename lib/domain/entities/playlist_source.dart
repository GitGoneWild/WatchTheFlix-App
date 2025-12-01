import 'package:equatable/equatable.dart';

/// Playlist source type
enum PlaylistSourceType {
  m3uFile,
  m3uUrl,
  xtream,
}

/// Playlist source entity
class PlaylistSource extends Equatable {
  final String id;
  final String name;
  final String url;
  final PlaylistSourceType type;
  final DateTime addedAt;
  final DateTime? lastUpdated;
  final XtreamCredentials? xtreamCredentials;
  final bool isActive;

  const PlaylistSource({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.addedAt,
    this.lastUpdated,
    this.xtreamCredentials,
    this.isActive = true,
  });

  /// Check if this is an Xtream source
  bool get isXtream => type == PlaylistSourceType.xtream;

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
    XtreamCredentials? xtreamCredentials,
    bool? isActive,
  }) {
    return PlaylistSource(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      addedAt: addedAt ?? this.addedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      xtreamCredentials: xtreamCredentials ?? this.xtreamCredentials,
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
        xtreamCredentials,
        isActive,
      ];
}

/// Xtream Codes API credentials
class XtreamCredentials extends Equatable {
  final String host;
  final String username;
  final String password;
  final String? serverInfo;

  const XtreamCredentials({
    required this.host,
    required this.username,
    required this.password,
    this.serverInfo,
  });

  /// Get base URL for API calls
  String get baseUrl {
    final normalizedHost =
        host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    return normalizedHost;
  }

  /// Get authentication query parameters
  String get authParams => 'username=$username&password=$password';

  XtreamCredentials copyWith({
    String? host,
    String? username,
    String? password,
    String? serverInfo,
  }) {
    return XtreamCredentials(
      host: host ?? this.host,
      username: username ?? this.username,
      password: password ?? this.password,
      serverInfo: serverInfo ?? this.serverInfo,
    );
  }

  @override
  List<Object?> get props => [host, username, password, serverInfo];
}

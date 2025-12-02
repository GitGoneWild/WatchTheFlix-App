// Xtream Codes Credentials
// Model for storing Xtream Codes authentication credentials.

import 'package:equatable/equatable.dart';

/// Xtream Codes credentials model
class XtreamCredentials extends Equatable {
  const XtreamCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.port,
  });

  /// Parse server URL and extract components
  factory XtreamCredentials.fromUrl({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    // Extract port if present in URL
    final uri = Uri.parse(serverUrl);
    return XtreamCredentials(
      serverUrl: '${uri.scheme}://${uri.host}',
      username: username,
      password: password,
      port: uri.hasPort ? uri.port : null,
    );
  }

  /// Create from JSON
  factory XtreamCredentials.fromJson(Map<String, dynamic> json) {
    return XtreamCredentials(
      serverUrl: json['serverUrl'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      port: json['port'] as int?,
    );
  }

  final String serverUrl;
  final String username;
  final String password;
  final int? port;

  /// Get the base URL for API calls
  String get baseUrl {
    if (port != null) {
      return '$serverUrl:$port';
    }
    return serverUrl;
  }

  /// Get the API URL with player_api.php endpoint
  String get apiUrl => '$baseUrl/player_api.php';

  /// Get the XMLTV EPG URL
  String get xmltvUrl => '$baseUrl/xmltv.php?username=$username&password=$password';

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'port': port,
    };
  }

  /// Validate credentials
  bool get isValid {
    return serverUrl.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty &&
        (serverUrl.startsWith('http://') || serverUrl.startsWith('https://'));
  }

  /// Copy with method
  XtreamCredentials copyWith({
    String? serverUrl,
    String? username,
    String? password,
    int? port,
  }) {
    return XtreamCredentials(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      port: port ?? this.port,
    );
  }

  @override
  List<Object?> get props => [serverUrl, username, password, port];
}

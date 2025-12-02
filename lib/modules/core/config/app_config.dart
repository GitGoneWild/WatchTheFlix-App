// AppConfig
// Central configuration management for the application.
// Provides environment settings, feature flags, and configuration loading.

/// Application configuration
class AppConfig {
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Singleton instance
  static final AppConfig _instance = AppConfig._internal();

  /// Firebase configuration
  bool firebaseEnabled = false;
  String? firebaseProjectId;
  String? firebaseApiKey;
  String? firebaseAppId;

  /// VPN configuration
  bool vpnDetectionEnabled = true;

  /// Cache configuration
  /// General cache expiration for various app data (channels, categories, etc.)
  Duration cacheExpiration = const Duration(hours: 24);

  /// General EPG cache expiration for URL-based or M3U EPG sources.
  Duration epgCacheExpiration = const Duration(hours: 6);

  /// Network configuration
  Duration defaultTimeout = const Duration(seconds: 30);
  Duration extendedTimeout = const Duration(seconds: 60);
  Duration shortTimeout = const Duration(seconds: 15);
  int maxRetries = 3;

  /// Initialize configuration from environment or storage
  Future<void> initialize({
    bool? firebaseEnabled,
    String? firebaseProjectId,
    String? firebaseApiKey,
    String? firebaseAppId,
    bool? vpnDetectionEnabled,
  }) async {
    if (firebaseEnabled != null) this.firebaseEnabled = firebaseEnabled;
    if (firebaseProjectId != null) this.firebaseProjectId = firebaseProjectId;
    if (firebaseApiKey != null) this.firebaseApiKey = firebaseApiKey;
    if (firebaseAppId != null) this.firebaseAppId = firebaseAppId;
    if (vpnDetectionEnabled != null) {
      this.vpnDetectionEnabled = vpnDetectionEnabled;
    }
  }

  /// Check if Firebase is configured
  bool get isFirebaseConfigured =>
      firebaseEnabled &&
      firebaseProjectId != null &&
      firebaseApiKey != null &&
      firebaseAppId != null;

  /// Get configuration as map (for debugging/logging)
  Map<String, dynamic> toMap() {
    return {
      'firebaseEnabled': firebaseEnabled,
      'firebaseProjectId': firebaseProjectId,
      'vpnDetectionEnabled': vpnDetectionEnabled,
      'cacheExpiration': cacheExpiration.inHours,
    };
  }
}

// AppConfig
// Central configuration management for the application.
// Provides environment settings, feature flags, and configuration loading.

/// Content source strategy for fetching channel data
enum ContentSourceStrategy {
  /// Fetch channels/EPG/VOD live via Xtream API endpoints
  xtreamApiDirect,

  /// Fetch M3U once from Xtream and parse/store channels locally
  xtreamM3uImport,
}

/// Application configuration
class AppConfig {
  /// Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Firebase configuration
  bool firebaseEnabled = false;
  String? firebaseProjectId;
  String? firebaseApiKey;
  String? firebaseAppId;

  /// Content source strategy
  ContentSourceStrategy contentSourceStrategy =
      ContentSourceStrategy.xtreamApiDirect;

  /// VPN configuration
  bool vpnDetectionEnabled = true;

  /// Cache configuration
  Duration cacheExpiration = const Duration(hours: 24);
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
    ContentSourceStrategy? contentSourceStrategy,
    bool? vpnDetectionEnabled,
  }) async {
    if (firebaseEnabled != null) this.firebaseEnabled = firebaseEnabled;
    if (firebaseProjectId != null) this.firebaseProjectId = firebaseProjectId;
    if (firebaseApiKey != null) this.firebaseApiKey = firebaseApiKey;
    if (firebaseAppId != null) this.firebaseAppId = firebaseAppId;
    if (contentSourceStrategy != null) {
      this.contentSourceStrategy = contentSourceStrategy;
    }
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
      'contentSourceStrategy': contentSourceStrategy.name,
      'vpnDetectionEnabled': vpnDetectionEnabled,
      'cacheExpiration': cacheExpiration.inHours,
    };
  }
}

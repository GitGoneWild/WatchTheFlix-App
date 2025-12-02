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
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Singleton instance
  static final AppConfig _instance = AppConfig._internal();

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

  /// Xtream Codes configuration
  bool xtreamEnabled = true;

  /// TTL for Xtream Codes XMLTV EPG cache.
  /// This controls how often the full XMLTV file is re-downloaded from Xtream servers.
  /// Default: 6 hours. Separate from epgCacheExpiration which may be used for other EPG sources.
  Duration xtreamEpgTtl = const Duration(hours: 6);
  bool xtreamEpgAutoRefreshOnStartup = false;

  /// Cache configuration
  /// General cache expiration for various app data (channels, categories, etc.)
  Duration cacheExpiration = const Duration(hours: 24);

  /// General EPG cache expiration for URL-based or M3U EPG sources.
  /// For Xtream-specific EPG caching, see xtreamEpgTtl above.
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
    bool? xtreamEnabled,
    Duration? xtreamEpgTtl,
    bool? xtreamEpgAutoRefreshOnStartup,
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
    if (xtreamEnabled != null) {
      this.xtreamEnabled = xtreamEnabled;
    }
    if (xtreamEpgTtl != null) {
      this.xtreamEpgTtl = xtreamEpgTtl;
    }
    if (xtreamEpgAutoRefreshOnStartup != null) {
      this.xtreamEpgAutoRefreshOnStartup = xtreamEpgAutoRefreshOnStartup;
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
      'xtreamEnabled': xtreamEnabled,
      'xtreamEpgTtl': xtreamEpgTtl.inHours,
      'xtreamEpgAutoRefreshOnStartup': xtreamEpgAutoRefreshOnStartup,
      'cacheExpiration': cacheExpiration.inHours,
    };
  }
}

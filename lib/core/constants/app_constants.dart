/// Application constants
class AppConstants {
  AppConstants._();

  /// App information
  static const String appName = 'WatchTheFlix';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'IPTV Streaming Application';

  /// Storage keys
  static const String keyPlaylistSources = 'playlist_sources';
  static const String keyActivePlaylist = 'active_playlist';
  static const String keyThemeMode = 'theme_mode';
  static const String keyFavorites = 'favorites';
  static const String keyRecentChannels = 'recent_channels';
  static const String keySettings = 'settings';
  static const String keyXtreamCredentials = 'xtream_credentials';

  /// API timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Video player settings
  static const Duration bufferDuration = Duration(seconds: 10);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// UI settings
  static const int gridColumnsPhone = 2;
  static const int gridColumnsTablet = 4;
  static const int gridColumnsDesktop = 6;
  static const double carouselHeight = 200;
  static const double heroHeight = 400;
  static const double cardAspectRatio = 16 / 9;

  /// Pagination
  static const int itemsPerPage = 50;
  static const int maxCachedPages = 10;

  /// Search
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const int minSearchLength = 2;

  /// Cache settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
}

/// Routes
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String addPlaylist = '/add-playlist';
  static const String home = '/home';
  static const String liveTV = '/live-tv';
  static const String movies = '/movies';
  static const String series = '/series';
  static const String player = '/player';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String favorites = '/favorites';
  static const String category = '/category';
  static const String details = '/details';
}

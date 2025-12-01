// StorageService
// Local storage abstraction for profiles, channels, tokens, and settings.
// Provides a consistent storage interface for all modules.

/// Storage result wrapper
class StorageResult<T> {
  final T? data;
  final StorageError? error;

  const StorageResult({this.data, this.error});

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

/// Storage error types
enum StorageErrorType {
  notFound,
  writeError,
  readError,
  serializationError,
  unknown,
}

/// Storage error model
class StorageError {
  final StorageErrorType type;
  final String message;
  final dynamic originalError;

  const StorageError({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'StorageError($type): $message';
}

/// Storage service interface
abstract class IStorageService {
  /// Store a string value
  Future<StorageResult<void>> setString(String key, String value);

  /// Get a string value
  Future<StorageResult<String>> getString(String key);

  /// Store an integer value
  Future<StorageResult<void>> setInt(String key, int value);

  /// Get an integer value
  Future<StorageResult<int>> getInt(String key);

  /// Store a boolean value
  Future<StorageResult<void>> setBool(String key, bool value);

  /// Get a boolean value
  Future<StorageResult<bool>> getBool(String key);

  /// Store a JSON object
  Future<StorageResult<void>> setJson(String key, Map<String, dynamic> value);

  /// Get a JSON object
  Future<StorageResult<Map<String, dynamic>>> getJson(String key);

  /// Store a list of JSON objects
  Future<StorageResult<void>> setJsonList(
      String key, List<Map<String, dynamic>> value);

  /// Get a list of JSON objects
  Future<StorageResult<List<Map<String, dynamic>>>> getJsonList(String key);

  /// Remove a value
  Future<StorageResult<void>> remove(String key);

  /// Check if a key exists
  Future<StorageResult<bool>> containsKey(String key);

  /// Clear all storage
  Future<StorageResult<void>> clear();
}

/// Storage keys for the application
class StorageKeys {
  StorageKeys._();

  // Profile keys
  static const String profiles = 'profiles';
  static const String activeProfileId = 'active_profile_id';

  // Channel keys
  static const String cachedChannels = 'cached_channels';
  static const String favorites = 'favorites';
  static const String recentChannels = 'recent_channels';

  // Settings keys
  static const String settings = 'settings';
  static const String vpnPreference = 'vpn_preference';
  static const String contentSourceStrategy = 'content_source_strategy';

  // Cache keys
  static const String lastRefreshTime = 'last_refresh_time';
  static const String epgCache = 'epg_cache';

  // Auth keys
  static const String xtreamCredentials = 'xtream_credentials';
}

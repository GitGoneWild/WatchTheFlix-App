// FirebaseRemoteConfigService
// Remote configuration service abstraction with Firebase implementation.

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';

/// Remote config service interface
abstract class IRemoteConfigService {
  /// Initialize and fetch remote config
  Future<void> initialize();

  /// Get a boolean value
  bool getBool(String key, {bool defaultValue = false});

  /// Get a string value
  String getString(String key, {String defaultValue = ''});

  /// Get a number value
  double getNumber(String key, {double defaultValue = 0});

  /// Get an integer value
  int getInt(String key, {int defaultValue = 0});

  /// Force fetch new values
  Future<void> fetch();

  /// Check if service is enabled
  bool get isEnabled;
}

/// Firebase remote config service implementation
class FirebaseRemoteConfigService implements IRemoteConfigService {
  final AppConfig _config;
  final Map<String, dynamic> _defaults;
  final Map<String, dynamic> _values = {};

  FirebaseRemoteConfigService({
    AppConfig? config,
    Map<String, dynamic>? defaults,
  })  : _config = config ?? AppConfig(),
        _defaults = defaults ?? {};

  @override
  bool get isEnabled => _config.firebaseEnabled;

  @override
  Future<void> initialize() async {
    if (!isEnabled) {
      moduleLogger.debug(
        'Firebase disabled, using default remote config values',
        tag: 'RemoteConfig',
      );
      return;
    }

    try {
      moduleLogger.info('Initializing remote config', tag: 'RemoteConfig');
      // Firebase implementation would go here
      // await FirebaseRemoteConfig.instance.setDefaults(_defaults);
      // await FirebaseRemoteConfig.instance.fetchAndActivate();
    } catch (e) {
      moduleLogger.error(
        'Failed to initialize remote config',
        tag: 'RemoteConfig',
        error: e,
      );
    }
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    if (!isEnabled) {
      return (_defaults[key] as bool?) ?? defaultValue;
    }

    try {
      // Firebase implementation would go here
      // return FirebaseRemoteConfig.instance.getBool(key);
      return (_values[key] as bool?) ?? (_defaults[key] as bool?) ?? defaultValue;
    } catch (e) {
      return (_defaults[key] as bool?) ?? defaultValue;
    }
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    if (!isEnabled) {
      return (_defaults[key] as String?) ?? defaultValue;
    }

    try {
      // Firebase implementation would go here
      // return FirebaseRemoteConfig.instance.getString(key);
      return (_values[key] as String?) ?? (_defaults[key] as String?) ?? defaultValue;
    } catch (e) {
      return (_defaults[key] as String?) ?? defaultValue;
    }
  }

  @override
  double getNumber(String key, {double defaultValue = 0}) {
    if (!isEnabled) {
      return (_defaults[key] as num?)?.toDouble() ?? defaultValue;
    }

    try {
      // Firebase implementation would go here
      // return FirebaseRemoteConfig.instance.getDouble(key);
      return (_values[key] as num?)?.toDouble() ??
          (_defaults[key] as num?)?.toDouble() ??
          defaultValue;
    } catch (e) {
      return (_defaults[key] as num?)?.toDouble() ?? defaultValue;
    }
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    if (!isEnabled) {
      return (_defaults[key] as int?) ?? defaultValue;
    }

    try {
      // Firebase implementation would go here
      // return FirebaseRemoteConfig.instance.getInt(key);
      return (_values[key] as int?) ?? (_defaults[key] as int?) ?? defaultValue;
    } catch (e) {
      return (_defaults[key] as int?) ?? defaultValue;
    }
  }

  @override
  Future<void> fetch() async {
    if (!isEnabled) return;

    try {
      moduleLogger.info('Fetching remote config', tag: 'RemoteConfig');
      // Firebase implementation would go here
      // await FirebaseRemoteConfig.instance.fetch();
      // await FirebaseRemoteConfig.instance.activate();
    } catch (e) {
      moduleLogger.error(
        'Failed to fetch remote config',
        tag: 'RemoteConfig',
        error: e,
      );
    }
  }
}

/// No-op remote config service using defaults only
class NoOpRemoteConfigService implements IRemoteConfigService {
  final Map<String, dynamic> _defaults;

  NoOpRemoteConfigService({Map<String, dynamic>? defaults})
      : _defaults = defaults ?? {};

  @override
  bool get isEnabled => false;

  @override
  Future<void> initialize() async {}

  @override
  bool getBool(String key, {bool defaultValue = false}) =>
      (_defaults[key] as bool?) ?? defaultValue;

  @override
  String getString(String key, {String defaultValue = ''}) =>
      (_defaults[key] as String?) ?? defaultValue;

  @override
  double getNumber(String key, {double defaultValue = 0}) =>
      (_defaults[key] as num?)?.toDouble() ?? defaultValue;

  @override
  int getInt(String key, {int defaultValue = 0}) =>
      (_defaults[key] as int?) ?? defaultValue;

  @override
  Future<void> fetch() async {}
}

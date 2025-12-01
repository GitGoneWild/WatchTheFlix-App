// FirebaseAnalyticsService
// Analytics service abstraction with Firebase implementation.

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';

/// Analytics service interface
/// Apps can implement this to use Firebase or any other analytics provider
abstract class IAnalyticsService {
  /// Track screen view
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters});

  /// Track custom event
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters});

  /// Set user property
  Future<void> setUserProperty(String name, String value);

  /// Set user ID for analytics
  Future<void> setUserId(String? userId);

  /// Check if analytics is enabled
  bool get isEnabled;
}

/// Firebase analytics service implementation
/// Only functional when Firebase is configured and enabled
class FirebaseAnalyticsService implements IAnalyticsService {
  final AppConfig _config;

  FirebaseAnalyticsService({AppConfig? config}) : _config = config ?? AppConfig();

  @override
  bool get isEnabled => _config.firebaseEnabled;

  @override
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!isEnabled) return;

    try {
      moduleLogger.debug(
        'Track screen: $screenName',
        tag: 'Analytics',
      );
      // Firebase implementation would go here
      // await FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    } catch (e) {
      moduleLogger.warning(
        'Failed to track screen view',
        tag: 'Analytics',
        error: e,
      );
    }
  }

  @override
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!isEnabled) return;

    try {
      moduleLogger.debug(
        'Track event: $eventName',
        tag: 'Analytics',
      );
      // Firebase implementation would go here
      // await FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
    } catch (e) {
      moduleLogger.warning(
        'Failed to track event',
        tag: 'Analytics',
        error: e,
      );
    }
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    if (!isEnabled) return;

    try {
      moduleLogger.debug(
        'Set user property: $name = $value',
        tag: 'Analytics',
      );
      // Firebase implementation would go here
      // await FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
    } catch (e) {
      moduleLogger.warning(
        'Failed to set user property',
        tag: 'Analytics',
        error: e,
      );
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!isEnabled) return;

    try {
      moduleLogger.debug(
        'Set user ID: $userId',
        tag: 'Analytics',
      );
      // Firebase implementation would go here
      // await FirebaseAnalytics.instance.setUserId(id: userId);
    } catch (e) {
      moduleLogger.warning(
        'Failed to set user ID',
        tag: 'Analytics',
        error: e,
      );
    }
  }
}

/// No-op analytics service for when analytics is disabled
class NoOpAnalyticsService implements IAnalyticsService {
  @override
  bool get isEnabled => false;

  @override
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters}) async {}

  @override
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}

  @override
  Future<void> setUserId(String? userId) async {}
}

// FirebaseMessagingService
// Push notification service abstraction with Firebase implementation.

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';

/// Push notification service interface
abstract class IPushNotificationService {
  /// Request notification permission
  Future<bool> requestPermission();

  /// Check if notifications are enabled
  Future<bool> isEnabled();

  /// Get the device token for push notifications
  Future<String?> getToken();

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic);

  /// Handle incoming message when app is in foreground
  void onMessage(void Function(Map<String, dynamic> message) handler);

  /// Handle message that opened the app
  void onMessageOpenedApp(void Function(Map<String, dynamic> message) handler);
}

/// Firebase messaging service implementation
class FirebaseMessagingService implements IPushNotificationService {
  FirebaseMessagingService({AppConfig? config})
      : _config = config ?? AppConfig();
  final AppConfig _config;
  void Function(Map<String, dynamic>)? _onMessageHandler;
  void Function(Map<String, dynamic>)? _onMessageOpenedAppHandler;

  bool get _isEnabled => _config.firebaseEnabled;

  @override
  Future<bool> requestPermission() async {
    if (!_isEnabled) {
      moduleLogger.debug(
        'Firebase disabled, skipping permission request',
        tag: 'Messaging',
      );
      return false;
    }

    try {
      moduleLogger.info('Requesting notification permission', tag: 'Messaging');
      // Firebase implementation would go here
      // final settings = await FirebaseMessaging.instance.requestPermission();
      // return settings.authorizationStatus == AuthorizationStatus.authorized;
      return false;
    } catch (e) {
      moduleLogger.error(
        'Failed to request permission',
        tag: 'Messaging',
        error: e,
      );
      return false;
    }
  }

  @override
  Future<bool> isEnabled() async {
    if (!_isEnabled) return false;

    try {
      // Check notification settings
      // Firebase implementation would go here
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    if (!_isEnabled) return null;

    try {
      moduleLogger.debug('Getting FCM token', tag: 'Messaging');
      // Firebase implementation would go here
      // return await FirebaseMessaging.instance.getToken();
      return null;
    } catch (e) {
      moduleLogger.error(
        'Failed to get token',
        tag: 'Messaging',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (!_isEnabled) return;

    try {
      moduleLogger.info('Subscribing to topic: $topic', tag: 'Messaging');
      // Firebase implementation would go here
      // await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      moduleLogger.error(
        'Failed to subscribe to topic',
        tag: 'Messaging',
        error: e,
      );
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isEnabled) return;

    try {
      moduleLogger.info('Unsubscribing from topic: $topic', tag: 'Messaging');
      // Firebase implementation would go here
      // await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (e) {
      moduleLogger.error(
        'Failed to unsubscribe from topic',
        tag: 'Messaging',
        error: e,
      );
    }
  }

  @override
  void onMessage(void Function(Map<String, dynamic> message) handler) {
    _onMessageHandler = handler;
    // Firebase implementation would go here
    // FirebaseMessaging.onMessage.listen((message) {
    //   handler(message.data);
    // });
  }

  @override
  void onMessageOpenedApp(void Function(Map<String, dynamic> message) handler) {
    _onMessageOpenedAppHandler = handler;
    // Firebase implementation would go here
    // FirebaseMessaging.onMessageOpenedApp.listen((message) {
    //   handler(message.data);
    // });
  }
}

/// No-op messaging service for when Firebase is disabled
class NoOpMessagingService implements IPushNotificationService {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async {}

  @override
  void onMessage(void Function(Map<String, dynamic> message) handler) {}

  @override
  void onMessageOpenedApp(
      void Function(Map<String, dynamic> message) handler) {}
}

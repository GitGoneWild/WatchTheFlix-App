# Firebase Setup

This document explains how to configure Firebase integration in WatchTheFlix.

## Overview

Firebase integration is **optional**. The app builds and runs without Firebase by default. When enabled, Firebase provides:

- **Analytics**: Screen views, events, user properties
- **Messaging**: Push notifications
- **Remote Config**: Feature flags and remote settings

## Module Structure

```
firebase/
├── analytics/
│   └── firebase_analytics_service.dart
├── messaging/
│   └── firebase_messaging_service.dart
├── remote_config/
│   └── firebase_remote_config_service.dart
└── firebase_initializer.dart
```

## Enabling Firebase

### 1. Configure AppConfig

In your app initialization:

```dart
await AppConfig().initialize(
  firebaseEnabled: true,
  firebaseProjectId: 'your-project-id',
  firebaseApiKey: 'your-api-key',
  firebaseAppId: 'your-app-id',
);
```

### 2. Add Firebase Configuration Files

Add platform-specific Firebase configuration:

- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`
- **Web**: Configure in `web/index.html`

### 3. Add Dependencies

If you haven't already, add Firebase packages to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.x.x
  firebase_analytics: ^10.x.x
  firebase_messaging: ^14.x.x
  firebase_remote_config: ^4.x.x
```

### 4. Initialize Firebase

The `FirebaseInitializer` handles safe initialization:

```dart
final initializer = FirebaseInitializer();
final result = await initializer.initialize();

if (result.isInitialized) {
  // Use Firebase services
  final analytics = result.analyticsService;
  final messaging = result.messagingService;
  final remoteConfig = result.remoteConfigService;
} else {
  // Using no-op implementations
  print('Firebase not initialized: ${result.error}');
}
```

## Analytics Service

### Interface

```dart
abstract class IAnalyticsService {
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters});
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters});
  Future<void> setUserProperty(String name, String value);
  Future<void> setUserId(String? userId);
  bool get isEnabled;
}
```

### Usage

```dart
// Track screen view
await analytics.trackScreenView('Home');

// Track event
await analytics.trackEvent('channel_played', parameters: {
  'channel_id': '123',
  'channel_name': 'ESPN',
});

// Set user property
await analytics.setUserProperty('subscription_type', 'premium');

// Set user ID
await analytics.setUserId('user123');
```

## Messaging Service

### Interface

```dart
abstract class IPushNotificationService {
  Future<bool> requestPermission();
  Future<bool> isEnabled();
  Future<String?> getToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  void onMessage(void Function(Map<String, dynamic> message) handler);
  void onMessageOpenedApp(void Function(Map<String, dynamic> message) handler);
}
```

### Usage

```dart
// Request permission
final granted = await messaging.requestPermission();

// Get FCM token
final token = await messaging.getToken();

// Subscribe to topic
await messaging.subscribeToTopic('news');

// Handle foreground messages
messaging.onMessage((message) {
  print('Received message: $message');
});

// Handle message that opened the app
messaging.onMessageOpenedApp((message) {
  // Navigate to relevant screen
});
```

## Remote Config Service

### Interface

```dart
abstract class IRemoteConfigService {
  Future<void> initialize();
  bool getBool(String key, {bool defaultValue = false});
  String getString(String key, {String defaultValue = ''});
  double getNumber(String key, {double defaultValue = 0});
  int getInt(String key, {int defaultValue = 0});
  Future<void> fetch();
  bool get isEnabled;
}
```

### Usage

```dart
// Initialize with defaults
await remoteConfig.initialize();

// Get values (with defaults)
final showAds = remoteConfig.getBool('show_ads', defaultValue: false);
final apiVersion = remoteConfig.getString('api_version', defaultValue: 'v1');
final timeout = remoteConfig.getInt('timeout_seconds', defaultValue: 30);

// Force fetch new values
await remoteConfig.fetch();
```

## No-Op Implementations

When Firebase is disabled, no-op implementations are used:

- `NoOpAnalyticsService`: All methods are safe no-ops
- `NoOpMessagingService`: Returns safe defaults
- `NoOpRemoteConfigService`: Returns provided defaults

This ensures the app works identically whether Firebase is configured or not.

## Environment-Specific Configuration

Configure Firebase differently per environment:

```dart
if (currentEnvironment.environment == Environment.production) {
  await AppConfig().initialize(
    firebaseEnabled: true,
    firebaseProjectId: 'prod-project-id',
    // ...
  );
} else {
  // Development: Firebase disabled or use dev project
  await AppConfig().initialize(
    firebaseEnabled: false,
  );
}
```

## Troubleshooting

### Firebase not initializing

1. Check configuration file locations
2. Verify package versions are compatible
3. Check `firebase_options.dart` is generated
4. Review logs for initialization errors

### Analytics not tracking

1. Verify `firebaseEnabled = true`
2. Check Firebase Console for data (24-48h delay)
3. Use DebugView for real-time testing

### Push notifications not working

1. Request and check permission status
2. Verify FCM token is generated
3. Check topic subscriptions
4. Test with Firebase Console

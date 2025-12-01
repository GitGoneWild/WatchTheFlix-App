// FirebaseInitializer
// Initializes Firebase services when enabled.
// Safely handles cases where Firebase is not configured.

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import 'analytics/firebase_analytics_service.dart';
import 'messaging/firebase_messaging_service.dart';
import 'remote_config/firebase_remote_config_service.dart';

/// Firebase initialization result
class FirebaseInitResult {
  final bool isInitialized;
  final IAnalyticsService analyticsService;
  final IPushNotificationService messagingService;
  final IRemoteConfigService remoteConfigService;
  final String? error;

  const FirebaseInitResult({
    required this.isInitialized,
    required this.analyticsService,
    required this.messagingService,
    required this.remoteConfigService,
    this.error,
  });
}

/// Firebase initializer
class FirebaseInitializer {
  final AppConfig _config;

  FirebaseInitializer({AppConfig? config}) : _config = config ?? AppConfig();

  /// Initialize Firebase services
  /// Returns initialized services (or no-op implementations if Firebase is disabled)
  Future<FirebaseInitResult> initialize() async {
    if (!_config.firebaseEnabled) {
      moduleLogger.info(
        'Firebase is disabled, using no-op implementations',
        tag: 'Firebase',
      );

      return FirebaseInitResult(
        isInitialized: false,
        analyticsService: NoOpAnalyticsService(),
        messagingService: NoOpMessagingService(),
        remoteConfigService: NoOpRemoteConfigService(),
      );
    }

    try {
      moduleLogger.info('Initializing Firebase', tag: 'Firebase');

      // Initialize Firebase core
      // await Firebase.initializeApp();

      // Create service instances
      final analyticsService = FirebaseAnalyticsService(config: _config);
      final messagingService = FirebaseMessagingService(config: _config);
      final remoteConfigService = FirebaseRemoteConfigService(config: _config);

      // Initialize remote config
      await remoteConfigService.initialize();

      moduleLogger.info('Firebase initialized successfully', tag: 'Firebase');

      return FirebaseInitResult(
        isInitialized: true,
        analyticsService: analyticsService,
        messagingService: messagingService,
        remoteConfigService: remoteConfigService,
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Firebase initialization failed',
        tag: 'Firebase',
        error: e,
        stackTrace: stackTrace,
      );

      // Return no-op implementations on failure
      return FirebaseInitResult(
        isInitialized: false,
        analyticsService: NoOpAnalyticsService(),
        messagingService: NoOpMessagingService(),
        remoteConfigService: NoOpRemoteConfigService(),
        error: e.toString(),
      );
    }
  }
}

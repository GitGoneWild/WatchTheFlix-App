// Environment
// Environment-specific configuration for development, staging, and production.

/// Application environment
enum Environment {
  development,
  staging,
  production,
}

/// Environment configuration
class EnvironmentConfig {
  const EnvironmentConfig({
    required this.environment,
    this.apiBaseUrl = '',
    this.enableLogging = true,
    this.enableAnalytics = false,
    this.enableCrashReporting = false,
  });
  final Environment environment;
  final String apiBaseUrl;
  final bool enableLogging;
  final bool enableAnalytics;
  final bool enableCrashReporting;

  /// Development environment configuration
  static const EnvironmentConfig development = EnvironmentConfig(
    environment: Environment.development,
  );

  /// Staging environment configuration
  static const EnvironmentConfig staging = EnvironmentConfig(
    environment: Environment.staging,
    enableAnalytics: true,
    enableCrashReporting: true,
  );

  /// Production environment configuration
  static const EnvironmentConfig production = EnvironmentConfig(
    environment: Environment.production,
    enableLogging: false,
    enableAnalytics: true,
    enableCrashReporting: true,
  );

  /// Check if this is a development environment
  bool get isDevelopment => environment == Environment.development;

  /// Check if this is a production environment
  bool get isProduction => environment == Environment.production;
}

/// Current environment configuration (set at app startup)
EnvironmentConfig currentEnvironment = EnvironmentConfig.development;

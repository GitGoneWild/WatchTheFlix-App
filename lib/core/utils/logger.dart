import 'package:logger/logger.dart';

/// Application logger with enhanced features
/// 
/// Provides centralized logging across the application with:
/// - Configurable log levels
/// - Pretty printing with emojis and timestamps
/// - Optional tags for module identification
/// - Support for external log listeners (e.g., analytics, crash reporting)
class AppLogger {
  AppLogger._();
  
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      errorMethodCount: 8,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      printEmojis: true,
      printTime: true,
    ),
  );

  static final List<LoggerListener> _listeners = [];
  static Level _minLevel = Level.debug;

  /// Set minimum log level (filters logs below this level)
  static void setMinLevel(Level level) {
    _minLevel = level;
  }

  /// Add a listener for log events (e.g., for analytics or crash reporting)
  static void addListener(LoggerListener listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  static void removeListener(LoggerListener listener) {
    _listeners.remove(listener);
  }

  /// Log debug message
  static void debug(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    if (_minLevel.value > Level.debug.value) return;
    final taggedMessage = tag != null ? '[$tag] $message' : message;
    _logger.d(taggedMessage, error: error, stackTrace: stackTrace);
    _notifyListeners(Level.debug, taggedMessage, error, stackTrace, tag);
  }

  /// Log info message
  static void info(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    if (_minLevel.value > Level.info.value) return;
    final taggedMessage = tag != null ? '[$tag] $message' : message;
    _logger.i(taggedMessage, error: error, stackTrace: stackTrace);
    _notifyListeners(Level.info, taggedMessage, error, stackTrace, tag);
  }

  /// Log warning message
  static void warning(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    if (_minLevel.value > Level.warning.value) return;
    final taggedMessage = tag != null ? '[$tag] $message' : message;
    _logger.w(taggedMessage, error: error, stackTrace: stackTrace);
    _notifyListeners(Level.warning, taggedMessage, error, stackTrace, tag);
  }

  /// Log error message
  static void error(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    if (_minLevel.value > Level.error.value) return;
    final taggedMessage = tag != null ? '[$tag] $message' : message;
    _logger.e(taggedMessage, error: error, stackTrace: stackTrace);
    _notifyListeners(Level.error, taggedMessage, error, stackTrace, tag);
  }

  /// Log fatal message
  static void fatal(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    final taggedMessage = tag != null ? '[$tag] $message' : message;
    _logger.f(taggedMessage, error: error, stackTrace: stackTrace);
    _notifyListeners(Level.fatal, taggedMessage, error, stackTrace, tag);
  }

  static void _notifyListeners(
    Level level,
    dynamic message,
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ) {
    for (final listener in _listeners) {
      listener.onLog(
        level,
        message.toString(),
        error: error,
        stackTrace: stackTrace,
        tag: tag,
      );
    }
  }
}

/// Logger listener interface for external logging integrations
/// (e.g., Firebase Analytics, Crashlytics, or custom logging services)
abstract class LoggerListener {
  void onLog(
    Level level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  });
}

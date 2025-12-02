// AppLogger
// Centralized logging service for the application.
// Provides consistent logging across all modules with configurable output.

import '../config/environment.dart';

/// Log level enumeration
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Log entry model
class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.tag,
  });
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final String? tag;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.name.toUpperCase()}] ');
    if (tag != null) buffer.write('[$tag] ');
    buffer.write(message);
    if (error != null) buffer.write(' - Error: $error');
    return buffer.toString();
  }
}

/// Logger listener interface for external logging integrations
abstract class LoggerListener {
  void onLog(LogEntry entry);
}

/// Centralized application logger
class ModuleLogger {
  factory ModuleLogger() => _instance;
  ModuleLogger._internal();
  static final ModuleLogger _instance = ModuleLogger._internal();

  final List<LoggerListener> _listeners = [];
  LogLevel _minLevel = LogLevel.debug;

  /// Set minimum log level
  set minLevel(LogLevel level) => _minLevel = level;

  /// Add a listener for log events
  void addListener(LoggerListener listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(LoggerListener listener) {
    _listeners.remove(listener);
  }

  /// Log a debug message
  void debug(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  void info(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  void warning(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  void error(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      tag: tag,
    );

    // Print to console in development
    if (currentEnvironment.enableLogging) {
      _printToConsole(entry);
    }

    // Notify listeners
    for (final listener in _listeners) {
      listener.onLog(entry);
    }
  }

  void _printToConsole(LogEntry entry) {
    final prefix = _getLevelPrefix(entry.level);
    // ignore: avoid_print
    print('$prefix ${entry.toString()}');
    if (entry.stackTrace != null) {
      // ignore: avoid_print
      print(entry.stackTrace);
    }
  }

  String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}

/// Global logger instance for convenience
final moduleLogger = ModuleLogger();

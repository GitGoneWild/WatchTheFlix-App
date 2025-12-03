// Module Logger Adapter
// This file provides backward compatibility for code using moduleLogger.
// It delegates to the unified AppLogger in core/utils/logger.dart.
// 
// Deprecated: Use AppLogger directly from core/utils/logger.dart instead.

import '../../../core/utils/logger.dart' as core_logger;

/// Centralized application logger (Adapter)
/// 
/// @deprecated Use [core_logger.AppLogger] directly instead.
/// This adapter exists for backward compatibility and will be removed in a future version.
class ModuleLogger {
  factory ModuleLogger() => _instance;
  ModuleLogger._internal();
  static final ModuleLogger _instance = ModuleLogger._internal();

  /// Log a debug message
  void debug(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    core_logger.AppLogger.debug(message, error, stackTrace, tag);
  }

  /// Log an info message
  void info(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    core_logger.AppLogger.info(message, error, stackTrace, tag);
  }

  /// Log a warning message
  void warning(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    core_logger.AppLogger.warning(message, error, stackTrace, tag);
  }

  /// Log an error message
  void error(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    core_logger.AppLogger.error(message, error, stackTrace, tag);
  }
}

/// Global logger instance for convenience
/// 
/// @deprecated Use [core_logger.AppLogger] directly instead.
final moduleLogger = ModuleLogger();

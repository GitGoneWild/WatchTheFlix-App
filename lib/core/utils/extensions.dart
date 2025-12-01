import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform utility class
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on mobile
  static bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if running on desktop
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Check if PiP is supported
  static bool get supportsPiP => isAndroid || isIOS;

  /// Check if running on TV
  static bool get isTV {
    if (kIsWeb) return false;
    // Android TV detection would be done at runtime
    return false;
  }
}

/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if valid URL
  bool get isValidUrl {
    final uri = Uri.tryParse(this);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  /// Check if valid M3U URL
  bool get isM3UUrl {
    return isValidUrl &&
        (toLowerCase().endsWith('.m3u') ||
            toLowerCase().endsWith('.m3u8') ||
            toLowerCase().contains('m3u') ||
            toLowerCase().contains('playlist'));
  }
}

/// Duration extensions
extension DurationExtensions on Duration {
  /// Format duration as HH:MM:SS or MM:SS
  String format() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Format as relative time
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Get element at index or null
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Group by key
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keyFunction(element);
      map.putIfAbsent(key, () => []).add(element);
    }
    return map;
  }
}

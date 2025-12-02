import 'dart:math';

/// Utility class for generating unique IDs
class IdGenerator {
  IdGenerator._();
  static final Random _random = Random.secure();

  /// Generate a unique ID combining timestamp and random characters
  static String generate() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _generateRandomString(8);
    return '${timestamp}_$randomPart';
  }

  /// Generate a random alphanumeric string of specified length
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }
}

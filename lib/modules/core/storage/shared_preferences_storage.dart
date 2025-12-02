// Shared Preferences Storage Service Implementation
// Implementation of IStorageService using SharedPreferences.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

/// SharedPreferences-based storage service implementation
class SharedPreferencesStorage implements IStorageService {
  SharedPreferencesStorage({
    required SharedPreferences sharedPreferences,
  }) : _prefs = sharedPreferences;

  final SharedPreferences _prefs;

  @override
  Future<StorageResult<void>> setString(String key, String value) async {
    try {
      final success = await _prefs.setString(key, value);
      if (success) {
        return const StorageResult();
      }
      return const StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Failed to write string',
        ),
      );
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Error writing string: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<String>> getString(String key) async {
    try {
      final value = _prefs.getString(key);
      if (value == null) {
        return const StorageResult(
          error: StorageError(
            type: StorageErrorType.notFound,
            message: 'Key not found',
          ),
        );
      }
      return StorageResult(data: value);
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.readError,
          message: 'Error reading string: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<void>> setInt(String key, int value) async {
    try {
      final success = await _prefs.setInt(key, value);
      if (success) {
        return const StorageResult();
      }
      return const StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Failed to write int',
        ),
      );
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Error writing int: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<int>> getInt(String key) async {
    try {
      final value = _prefs.getInt(key);
      if (value == null) {
        return const StorageResult(
          error: StorageError(
            type: StorageErrorType.notFound,
            message: 'Key not found',
          ),
        );
      }
      return StorageResult(data: value);
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.readError,
          message: 'Error reading int: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<void>> setBool(String key, bool value) async {
    try {
      final success = await _prefs.setBool(key, value);
      if (success) {
        return const StorageResult();
      }
      return const StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Failed to write bool',
        ),
      );
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Error writing bool: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<bool>> getBool(String key) async {
    try {
      final value = _prefs.getBool(key);
      if (value == null) {
        return const StorageResult(
          error: StorageError(
            type: StorageErrorType.notFound,
            message: 'Key not found',
          ),
        );
      }
      return StorageResult(data: value);
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.readError,
          message: 'Error reading bool: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<void>> setJson(
    String key,
    Map<String, dynamic> value,
  ) async {
    try {
      final jsonString = json.encode(value);
      final success = await _prefs.setString(key, jsonString);
      if (success) {
        return const StorageResult();
      }
      return const StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Failed to write JSON',
        ),
      );
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.serializationError,
          message: 'Error serializing JSON: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<Map<String, dynamic>>> getJson(String key) async {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) {
        return const StorageResult(
          error: StorageError(
            type: StorageErrorType.notFound,
            message: 'Key not found',
          ),
        );
      }
      final data = json.decode(jsonString) as Map<String, dynamic>;
      return StorageResult(data: data);
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.serializationError,
          message: 'Error deserializing JSON: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<void>> setJsonList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    try {
      final jsonString = json.encode(value);
      final success = await _prefs.setString(key, jsonString);
      if (success) {
        return const StorageResult();
      }
      return const StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Failed to write JSON list',
        ),
      );
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.serializationError,
          message: 'Error serializing JSON list: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<List<Map<String, dynamic>>>> getJsonList(
    String key,
  ) async {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) {
        return const StorageResult(
          error: StorageError(
            type: StorageErrorType.notFound,
            message: 'Key not found',
          ),
        );
      }
      final data = json.decode(jsonString) as List<dynamic>;
      final typedData = data.cast<Map<String, dynamic>>();
      return StorageResult(data: typedData);
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.serializationError,
          message: 'Error deserializing JSON list: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<void>> remove(String key) async {
    try {
      final success = await _prefs.remove(key);
      if (success) {
        return const StorageResult();
      }
      return const StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Failed to remove key',
        ),
      );
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Error removing key: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<bool>> containsKey(String key) async {
    try {
      final contains = _prefs.containsKey(key);
      return StorageResult(data: contains);
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.readError,
          message: 'Error checking key: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<StorageResult<void>> clear() async {
    try {
      final success = await _prefs.clear();
      if (success) {
        return const StorageResult();
      }
      return const StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Failed to clear storage',
        ),
      );
    } catch (e) {
      return StorageResult(
        error: StorageError(
          type: StorageErrorType.writeError,
          message: 'Error clearing storage: $e',
          originalError: e,
        ),
      );
    }
  }
}

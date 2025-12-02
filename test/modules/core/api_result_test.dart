import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';

void main() {
  group('ApiResult', () {
    test('should create a success result', () {
      final result = ApiResult.success('test data');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, equals('test data'));
      expect(result.dataOrNull, equals('test data'));
    });

    test('should create a failure result', () {
      final error = ApiError.network('Network error');
      final result = ApiResult<String>.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.error, equals(error));
      expect(result.errorOrNull, equals(error));
    });

    test('should throw when accessing data on failure', () {
      final result = ApiResult<String>.failure(ApiError.network());

      expect(() => result.data, throwsA(isA<StateError>()));
    });

    test('should throw when accessing error on success', () {
      final result = ApiResult.success('test');

      expect(() => result.error, throwsA(isA<StateError>()));
    });

    test('should handle void success result correctly', () {
      // This is the key fix - ApiResult<void> should work correctly
      final result = ApiResult<void>.success(null);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.errorOrNull, isNull);
    });

    test('should handle void failure result correctly', () {
      final error = ApiError.network('Network error');
      final result = ApiResult<void>.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.error, equals(error));
    });

    test('should map success result', () {
      final result = ApiResult.success(10);
      final mapped = result.map((data) => data * 2);

      expect(mapped.isSuccess, isTrue);
      expect(mapped.data, equals(20));
    });

    test('should preserve error on map failure', () {
      final error = ApiError.network();
      final result = ApiResult<int>.failure(error);
      final mapped = result.map((data) => data * 2);

      expect(mapped.isFailure, isTrue);
      expect(mapped.error, equals(error));
    });

    test('should fold success correctly', () {
      final result = ApiResult.success('success');
      final value = result.fold(
        onSuccess: (data) => 'Got: $data',
        onFailure: (error) => 'Error: ${error.message}',
      );

      expect(value, equals('Got: success'));
    });

    test('should fold failure correctly', () {
      final result = ApiResult<String>.failure(ApiError.network('Failed'));
      final value = result.fold(
        onSuccess: (data) => 'Got: $data',
        onFailure: (error) => 'Error: ${error.message}',
      );

      expect(value, equals('Error: Failed'));
    });
  });

  group('ApiError', () {
    test('should create network error', () {
      final error = ApiError.network('Connection failed');

      expect(error.type, equals(ApiErrorType.network));
      expect(error.message, equals('Connection failed'));
    });

    test('should create server error with status code', () {
      final error = ApiError.server('Server error', 500);

      expect(error.type, equals(ApiErrorType.server));
      expect(error.statusCode, equals(500));
    });

    test('should create auth error', () {
      final error = ApiError.auth('Invalid token');

      expect(error.type, equals(ApiErrorType.auth));
      expect(error.message, equals('Invalid token'));
    });

    test('should create timeout error', () {
      final error = ApiError.timeout();

      expect(error.type, equals(ApiErrorType.timeout));
      expect(error.message, isNotEmpty);
    });

    test('should create error from exception', () {
      final error = ApiError.fromException(Exception('Test exception'));

      expect(error.type, equals(ApiErrorType.unknown));
      expect(error.message, contains('Test exception'));
    });
  });
}

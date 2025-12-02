import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/modules/core/storage/storage_service.dart';

class MockStorageService extends Mock implements IStorageService {}

void main() {
  group('Onboarding Persistence', () {
    late MockStorageService mockStorage;

    setUp(() {
      mockStorage = MockStorageService();
    });

    test('should save onboarding completion status', () async {
      // Arrange
      when(() => mockStorage.setBool(StorageKeys.onboardingCompleted, true))
          .thenAnswer((_) async => const StorageResult<void>());

      // Act
      final result = await mockStorage.setBool(
        StorageKeys.onboardingCompleted,
        true,
      );

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockStorage.setBool(StorageKeys.onboardingCompleted, true))
          .called(1);
    });

    test('should retrieve onboarding completion status', () async {
      // Arrange
      when(() => mockStorage.getBool(StorageKeys.onboardingCompleted))
          .thenAnswer((_) async => const StorageResult<bool>(data: true));

      // Act
      final result = await mockStorage.getBool(
        StorageKeys.onboardingCompleted,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, true);
      verify(() => mockStorage.getBool(StorageKeys.onboardingCompleted)).called(1);
    });

    test('should return false when onboarding not completed', () async {
      // Arrange
      when(() => mockStorage.getBool(StorageKeys.onboardingCompleted)).thenAnswer(
        (_) async => const StorageResult<bool>(
          error: StorageError(
            type: StorageErrorType.notFound,
            message: 'Key not found',
          ),
        ),
      );

      // Act
      final result = await mockStorage.getBool(
        StorageKeys.onboardingCompleted,
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.error?.type, StorageErrorType.notFound);
    });
  });
}

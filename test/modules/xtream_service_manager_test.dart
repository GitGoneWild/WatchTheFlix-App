import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';
import 'package:watchtheflix/modules/core/storage/storage_service.dart';
import 'package:watchtheflix/modules/xtreamcodes/auth/xtream_auth_service.dart';
import 'package:watchtheflix/modules/xtreamcodes/auth/xtream_credentials.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/xmltv_parser.dart';
import 'package:watchtheflix/modules/xtreamcodes/xtream_service_manager.dart';

class MockAuthService extends Mock implements IXtreamAuthService {}
class MockStorageService extends Mock implements IStorageService {}
class MockXmltvParser extends Mock implements IXmltvParser {}

void main() {
  group('XtreamServiceManager', () {
    late MockAuthService mockAuthService;
    late MockStorageService mockStorage;
    late MockXmltvParser mockParser;
    late XtreamServiceManager serviceManager;

    setUp(() {
      mockAuthService = MockAuthService();
      mockStorage = MockStorageService();
      mockParser = MockXmltvParser();
      
      serviceManager = XtreamServiceManager(
        authService: mockAuthService,
        storage: mockStorage,
        xmltvParser: mockParser,
      );
    });

    test('should start uninitialized', () {
      expect(serviceManager.isInitialized, false);
    });

    test('should initialize with credentials', () async {
      // Arrange
      final credentials = XtreamCredentials.fromUrl(
        serverUrl: 'http://test.com',
        username: 'test',
        password: 'pass',
      );

      // Act
      await serviceManager.initialize(credentials);

      // Assert
      expect(serviceManager.isInitialized, true);
    });

    test('should restore from saved credentials', () async {
      // Arrange
      final credentials = XtreamCredentials.fromUrl(
        serverUrl: 'http://test.com',
        username: 'test',
        password: 'pass',
      );
      
      when(mockAuthService.loadCredentials())
          .thenAnswer((_) async => ApiResult.success(credentials));

      // Act
      final restored = await serviceManager.tryRestore();

      // Assert
      expect(restored, true);
      expect(serviceManager.isInitialized, true);
    });

    test('should return false when no saved credentials', () async {
      // Arrange
      when(mockAuthService.loadCredentials()).thenAnswer(
        (_) async => ApiResult.failure(
          const ApiError(
            type: ApiErrorType.notFound,
            message: 'No credentials found',
          ),
        ),
      );

      // Act
      final restored = await serviceManager.tryRestore();

      // Assert
      expect(restored, false);
      expect(serviceManager.isInitialized, false);
    });

    test('should clear service and credentials', () async {
      // Arrange
      final credentials = XtreamCredentials.fromUrl(
        serverUrl: 'http://test.com',
        username: 'test',
        password: 'pass',
      );
      
      when(mockAuthService.clearCredentials())
          .thenAnswer((_) async => ApiResult.success(null));

      await serviceManager.initialize(credentials);
      expect(serviceManager.isInitialized, true);

      // Act
      await serviceManager.clear();

      // Assert
      expect(serviceManager.isInitialized, false);
      verify(mockAuthService.clearCredentials()).called(1);
    });
  });
}

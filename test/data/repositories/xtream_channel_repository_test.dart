import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/data/datasources/local/local_storage.dart';
import 'package:watchtheflix/data/models/channel_model.dart';
import 'package:watchtheflix/data/repositories/xtream_channel_repository.dart';
import 'package:watchtheflix/domain/entities/channel.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';
import 'package:watchtheflix/modules/xtreamcodes/account/xtream_api_client.dart';
import 'package:watchtheflix/modules/xtreamcodes/repositories/xtream_live_repository.dart';
import 'package:watchtheflix/modules/xtreamcodes/repositories/xtream_repository_factory.dart';
import 'package:watchtheflix/modules/xtreamcodes/repositories/xtream_vod_repository.dart';
import 'package:watchtheflix/modules/xtreamcodes/xtream_service_manager.dart';

class MockXtreamServiceManager extends Mock implements XtreamServiceManager {}

class MockLocalStorage extends Mock implements LocalStorage {}

class MockXtreamRepositoryFactory extends Mock
    implements XtreamRepositoryFactory {}

class MockXtreamLiveRepository extends Mock implements IXtreamLiveRepository {}

class MockXtreamVodRepository extends Mock implements IXtreamVodRepository {}

class MockXtreamApiClient extends Mock implements XtreamApiClient {}

void main() {
  group('XtreamChannelRepository', () {
    late MockXtreamServiceManager mockServiceManager;
    late MockLocalStorage mockLocalStorage;
    late MockXtreamRepositoryFactory mockRepositoryFactory;
    late MockXtreamLiveRepository mockLiveRepository;
    late MockXtreamVodRepository mockVodRepository;
    late MockXtreamApiClient mockApiClient;
    late XtreamChannelRepository repository;

    setUp(() {
      mockServiceManager = MockXtreamServiceManager();
      mockLocalStorage = MockLocalStorage();
      mockRepositoryFactory = MockXtreamRepositoryFactory();
      mockLiveRepository = MockXtreamLiveRepository();
      mockVodRepository = MockXtreamVodRepository();
      mockApiClient = MockXtreamApiClient();

      repository = XtreamChannelRepository(
        serviceManager: mockServiceManager,
        localStorage: mockLocalStorage,
      );
    });

    setUpAll(() {
      registerFallbackValue(ChannelModel(
        id: 'fallback',
        name: 'fallback',
        streamUrl: 'http://fallback.com',
        type: ContentType.live,
      ));
    });

    group('getLiveChannels', () {
      test('should return empty list when Xtream service is not initialized',
          () async {
        // Arrange
        when(() => mockServiceManager.isInitialized).thenReturn(false);

        // Act
        final result = await repository.getLiveChannels();

        // Assert
        expect(result, isEmpty);
      });

      test('should return channels from Xtream repository when initialized',
          () async {
        // Arrange
        when(() => mockServiceManager.isInitialized).thenReturn(true);
        when(() => mockServiceManager.repositoryFactory)
            .thenReturn(mockRepositoryFactory);
        when(() => mockRepositoryFactory.liveRepository)
            .thenReturn(mockLiveRepository);

        final testChannels = [
          const DomainChannel(
            id: 'test_1',
            name: 'Test Channel 1',
            streamUrl: 'http://test.com/stream1',
            type: ContentType.live,
          ),
          const DomainChannel(
            id: 'test_2',
            name: 'Test Channel 2',
            streamUrl: 'http://test.com/stream2',
            type: ContentType.live,
          ),
        ];

        when(() =>
                mockLiveRepository.getLiveChannels(
                    categoryId: any(named: 'categoryId'),
                    forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => ApiResult.success(testChannels));

        // Act
        final result = await repository.getLiveChannels();

        // Assert
        expect(result.length, equals(2));
        expect(result[0].name, equals('Test Channel 1'));
        expect(result[1].name, equals('Test Channel 2'));
      });

      test('should return empty list when API fails', () async {
        // Arrange
        when(() => mockServiceManager.isInitialized).thenReturn(true);
        when(() => mockServiceManager.repositoryFactory)
            .thenReturn(mockRepositoryFactory);
        when(() => mockRepositoryFactory.liveRepository)
            .thenReturn(mockLiveRepository);

        when(() => mockLiveRepository.getLiveChannels(
              categoryId: any(named: 'categoryId'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => ApiResult.failure(
              const ApiError(
                type: ApiErrorType.network,
                message: 'Network error',
              ),
            ));

        // Act
        final result = await repository.getLiveChannels();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getLiveCategories', () {
      test('should return empty list when Xtream service is not initialized',
          () async {
        // Arrange
        when(() => mockServiceManager.isInitialized).thenReturn(false);

        // Act
        final result = await repository.getLiveCategories();

        // Assert
        expect(result, isEmpty);
      });

      test('should return categories from Xtream repository when initialized',
          () async {
        // Arrange
        when(() => mockServiceManager.isInitialized).thenReturn(true);
        when(() => mockServiceManager.repositoryFactory)
            .thenReturn(mockRepositoryFactory);
        when(() => mockRepositoryFactory.liveRepository)
            .thenReturn(mockLiveRepository);

        final testCategories = [
          const DomainCategory(
            id: 'cat_1',
            name: 'Category 1',
            channelCount: 10,
          ),
          const DomainCategory(
            id: 'cat_2',
            name: 'Category 2',
            channelCount: 5,
          ),
        ];

        when(() => mockLiveRepository.getLiveCategories(
                forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => ApiResult.success(testCategories));

        // Act
        final result = await repository.getLiveCategories();

        // Assert
        expect(result.length, equals(2));
        expect(result[0].name, equals('Category 1'));
        expect(result[1].name, equals('Category 2'));
      });
    });

    group('favorites', () {
      test('should add channel to favorites via local storage', () async {
        // Arrange
        const testChannel = Channel(
          id: 'test_1',
          name: 'Test Channel',
          streamUrl: 'http://test.com/stream',
        );

        when(() => mockLocalStorage.addFavorite(any())).thenAnswer((_) async {});

        // Act
        await repository.addToFavorites(testChannel);

        // Assert
        verify(() => mockLocalStorage.addFavorite(any())).called(1);
      });

      test('should remove channel from favorites via local storage', () async {
        // Arrange
        when(() => mockLocalStorage.removeFavorite(any()))
            .thenAnswer((_) async {});

        // Act
        await repository.removeFromFavorites('test_1');

        // Assert
        verify(() => mockLocalStorage.removeFavorite('test_1')).called(1);
      });
    });
  });
}

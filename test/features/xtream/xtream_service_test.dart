import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/data/datasources/local/local_storage.dart';
import 'package:watchtheflix/data/models/channel_model.dart';
import 'package:watchtheflix/data/models/category_model.dart';
import 'package:watchtheflix/features/xtream/xtream_api_client.dart';
import 'package:watchtheflix/features/xtream/xtream_service.dart';
import 'package:watchtheflix/domain/entities/playlist_source.dart';

class MockXtreamApiClient extends Mock implements XtreamApiClient {}
class MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  group('XtreamService', () {
    late MockXtreamApiClient mockApiClient;
    late MockLocalStorage mockLocalStorage;
    late XtreamService service;
    late XtreamCredentials credentials;

    setUp(() {
      mockApiClient = MockXtreamApiClient();
      mockLocalStorage = MockLocalStorage();
      service = XtreamService(
        apiClient: mockApiClient,
        localStorage: mockLocalStorage,
      );
      credentials = const XtreamCredentials(
        host: 'http://test.server.com:8080',
        username: 'testuser',
        password: 'testpass',
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('Live Channels', () {
      test('should fetch channels from API when cache is empty', () async {
        // Arrange
        final channels = [
          const ChannelModel(id: '1', name: 'Channel 1', streamUrl: 'url1'),
          const ChannelModel(id: '2', name: 'Channel 2', streamUrl: 'url2'),
        ];

        when(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null))
            .thenAnswer((_) async => channels);

        // Act
        final result = await service.getLiveChannels(credentials);

        // Assert
        expect(result.length, equals(2));
        verify(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null)).called(1);
      });

      test('should return cached channels when available', () async {
        // Arrange
        final channels = [
          const ChannelModel(id: '1', name: 'Channel 1', streamUrl: 'url1'),
        ];

        when(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null))
            .thenAnswer((_) async => channels);

        // First call to populate cache
        await service.getLiveChannels(credentials);

        // Act - Second call should use cache
        final result = await service.getLiveChannels(credentials);

        // Assert
        expect(result.length, equals(1));
        // API should only be called once
        verify(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null)).called(1);
      });

      test('should force refresh when requested', () async {
        // Arrange
        final channels = [
          const ChannelModel(id: '1', name: 'Channel 1', streamUrl: 'url1'),
        ];

        when(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null))
            .thenAnswer((_) async => channels);

        // First call
        await service.getLiveChannels(credentials);
        
        // Force refresh
        await service.getLiveChannels(credentials, forceRefresh: true);

        // Assert - API should be called twice
        verify(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null)).called(2);
      });
    });

    group('Categories', () {
      test('should fetch categories from API', () async {
        // Arrange
        final categories = [
          const CategoryModel(id: '1', name: 'Sports'),
          const CategoryModel(id: '2', name: 'News'),
        ];

        when(() => mockApiClient.fetchLiveCategories(credentials))
            .thenAnswer((_) async => categories);

        // Act
        final result = await service.getLiveCategories(credentials);

        // Assert
        expect(result.length, equals(2));
        expect(result[0].name, equals('Sports'));
      });

      test('should fetch movie categories from API', () async {
        // Arrange
        final categories = [
          const CategoryModel(id: '1', name: 'Action'),
          const CategoryModel(id: '2', name: 'Comedy'),
        ];

        when(() => mockApiClient.fetchMovieCategories(credentials))
            .thenAnswer((_) async => categories);

        // Act
        final result = await service.getMovieCategories(credentials);

        // Assert
        expect(result.length, equals(2));
        expect(result[0].name, equals('Action'));
      });

      test('should fetch series categories from API', () async {
        // Arrange
        final categories = [
          const CategoryModel(id: '1', name: 'Drama'),
          const CategoryModel(id: '2', name: 'Thriller'),
        ];

        when(() => mockApiClient.fetchSeriesCategories(credentials))
            .thenAnswer((_) async => categories);

        // Act
        final result = await service.getSeriesCategories(credentials);

        // Assert
        expect(result.length, equals(2));
        expect(result[0].name, equals('Drama'));
      });

      test('should cache movie categories', () async {
        // Arrange
        final categories = [
          const CategoryModel(id: '1', name: 'Action'),
        ];

        when(() => mockApiClient.fetchMovieCategories(credentials))
            .thenAnswer((_) async => categories);

        // First call to populate cache
        await service.getMovieCategories(credentials);

        // Second call should use cache
        final result = await service.getMovieCategories(credentials);

        // Assert
        expect(result.length, equals(1));
        // API should only be called once
        verify(() => mockApiClient.fetchMovieCategories(credentials)).called(1);
      });

      test('should cache series categories', () async {
        // Arrange
        final categories = [
          const CategoryModel(id: '1', name: 'Drama'),
        ];

        when(() => mockApiClient.fetchSeriesCategories(credentials))
            .thenAnswer((_) async => categories);

        // First call to populate cache
        await service.getSeriesCategories(credentials);

        // Second call should use cache
        final result = await service.getSeriesCategories(credentials);

        // Assert
        expect(result.length, equals(1));
        // API should only be called once
        verify(() => mockApiClient.fetchSeriesCategories(credentials)).called(1);
      });
    });

    group('EPG Data', () {
      test('should fetch EPG from API when cache is empty', () async {
        // Arrange
        final epgData = <String, List<EpgEntry>>{
          'channel1': [],
          'channel2': [],
        };

        when(() => mockApiClient.fetchAllEpg(credentials))
            .thenAnswer((_) async => epgData);

        // Act
        final result = await service.getEpg(credentials);

        // Assert
        expect(result.length, equals(2));
        verify(() => mockApiClient.fetchAllEpg(credentials)).called(1);
      });

      test('should cache EPG data', () async {
        // Arrange
        final epgData = <String, List<EpgEntry>>{
          'channel1': [],
        };

        when(() => mockApiClient.fetchAllEpg(credentials))
            .thenAnswer((_) async => epgData);

        // First call to populate cache
        await service.getEpg(credentials);

        // Second call should use cache
        final result = await service.getEpg(credentials);

        // Assert
        expect(result.length, equals(1));
        // API should only be called once
        verify(() => mockApiClient.fetchAllEpg(credentials)).called(1);
      });

      test('should force refresh EPG when requested', () async {
        // Arrange
        final epgData = <String, List<EpgEntry>>{
          'channel1': [],
        };

        when(() => mockApiClient.fetchAllEpg(credentials))
            .thenAnswer((_) async => epgData);

        // First call
        await service.getEpg(credentials);
        
        // Force refresh
        await service.getEpg(credentials, forceRefresh: true);

        // Assert - API should be called twice
        verify(() => mockApiClient.fetchAllEpg(credentials)).called(2);
      });
    });

    group('Full Refresh', () {
      test('should refresh all data types', () async {
        // Arrange
        when(() => mockApiClient.fetchLiveCategories(credentials))
            .thenAnswer((_) async => []);
        when(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null))
            .thenAnswer((_) async => []);
        when(() => mockApiClient.fetchMovies(credentials, categoryId: null))
            .thenAnswer((_) async => []);
        when(() => mockApiClient.fetchSeries(credentials, categoryId: null))
            .thenAnswer((_) async => []);
        when(() => mockApiClient.fetchAllEpg(credentials))
            .thenAnswer((_) async => {});
        when(() => mockLocalStorage.cacheChannels(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await service.fullRefresh(credentials);

        // Assert
        verify(() => mockApiClient.fetchLiveCategories(credentials)).called(1);
        verify(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null)).called(1);
        verify(() => mockApiClient.fetchMovies(credentials, categoryId: null)).called(1);
        verify(() => mockApiClient.fetchSeries(credentials, categoryId: null)).called(1);
        verify(() => mockApiClient.fetchAllEpg(credentials)).called(1);
      });
    });

    group('Cache Management', () {
      test('should clear all caches', () async {
        // Arrange
        final channels = [
          const ChannelModel(id: '1', name: 'Channel 1', streamUrl: 'url1'),
        ];

        when(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null))
            .thenAnswer((_) async => channels);

        // Populate cache
        await service.getLiveChannels(credentials);

        // Clear cache
        service.clearCache();

        // Fetch again
        await service.getLiveChannels(credentials);

        // Assert - API should be called twice (before and after clear)
        verify(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null)).called(2);
      });

      test('should clear cache for specific playlist', () async {
        // Arrange
        final channels = [
          const ChannelModel(id: '1', name: 'Channel 1', streamUrl: 'url1'),
        ];

        when(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null))
            .thenAnswer((_) async => channels);

        // Populate cache
        await service.getLiveChannels(credentials);

        // Clear cache for this playlist
        service.clearCacheForPlaylist(credentials);

        // Fetch again
        await service.getLiveChannels(credentials);

        // Assert - API should be called twice
        verify(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null)).called(2);
      });
    });

    group('Refresh Interval', () {
      test('should update refresh interval', () {
        // Act
        service.refreshInterval = const Duration(hours: 12);

        // Assert
        expect(service.refreshInterval, equals(const Duration(hours: 12)));
      });

      test('should indicate when refresh is needed', () async {
        // Arrange
        final channels = [
          const ChannelModel(id: '1', name: 'Channel 1', streamUrl: 'url1'),
        ];

        when(() => mockApiClient.fetchLiveCategories(credentials))
            .thenAnswer((_) async => []);
        when(() => mockApiClient.fetchLiveChannels(credentials, categoryId: null))
            .thenAnswer((_) async => channels);
        when(() => mockLocalStorage.cacheChannels(any(), any()))
            .thenAnswer((_) async {});

        // Initially needs refresh
        expect(service.needsRefresh(credentials.baseUrl), isTrue);

        // Refresh data
        await service.refreshLiveData(credentials);

        // Should not need refresh anymore
        expect(service.needsRefresh(credentials.baseUrl), isFalse);
      });
    });
  });
}

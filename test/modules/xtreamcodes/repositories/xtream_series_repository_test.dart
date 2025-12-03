import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';
import 'package:watchtheflix/modules/core/storage/storage_service.dart';
import 'package:watchtheflix/modules/xtreamcodes/account/xtream_api_client.dart';
import 'package:watchtheflix/modules/xtreamcodes/models/xtream_api_models.dart';
import 'package:watchtheflix/modules/xtreamcodes/repositories/xtream_series_repository.dart';

class MockXtreamApiClient extends Mock implements XtreamApiClient {}

class MockStorageService extends Mock implements IStorageService {}

void main() {
  group('XtreamSeriesRepository', () {
    late MockXtreamApiClient mockApiClient;
    late MockStorageService mockStorage;
    late XtreamSeriesRepository repository;

    setUp(() {
      mockApiClient = MockXtreamApiClient();
      mockStorage = MockStorageService();

      repository = XtreamSeriesRepository(
        apiClient: mockApiClient,
        storage: mockStorage,
      );
    });

    group('getSeriesCategories', () {
      test('should return categories from API when available', () async {
        // Arrange
        final apiCategories = [
          const XtreamSeriesCategory(categoryId: '1', categoryName: 'Drama'),
          const XtreamSeriesCategory(categoryId: '2', categoryName: 'Comedy'),
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.getSeriesCategories())
            .thenAnswer((_) async => ApiResult.success(apiCategories));
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setInt(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getSeriesCategories();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(2));
        expect(result.data[0].id, equals('1'));
        expect(result.data[0].name, equals('Drama'));
        expect(result.data[1].id, equals('2'));
        expect(result.data[1].name, equals('Comedy'));
      });

      test('should return failure when no categories available', () async {
        // Arrange
        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.getSeriesCategories()).thenAnswer(
          (_) async => ApiResult.failure(
            const ApiError(
              type: ApiErrorType.server,
              message: 'API error',
            ),
          ),
        );

        // Act
        final result = await repository.getSeriesCategories();

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('getSeries', () {
      test('should return series from API', () async {
        // Arrange
        final apiSeries = [
          const XtreamSeries(
            num: '1',
            name: 'Breaking Bad',
            seriesId: '101',
            cover: 'http://test.com/cover.png',
            plot: 'A high school teacher turns to making drugs',
            cast: 'Bryan Cranston',
            director: 'Vince Gilligan',
            genre: 'Drama',
            releaseDate: '2008',
            lastModified: '',
            rating: '9.5',
            categoryId: '1',
          ),
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.getSeries(categoryId: any(named: 'categoryId')))
            .thenAnswer((_) async => ApiResult.success(apiSeries));
        when(() => mockApiClient.getSeriesStreamUrl(any(), any()))
            .thenReturn('http://test.com/stream');
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setInt(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getSeries();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        expect(result.data[0].name, equals('Breaking Bad'));
        expect(result.data[0].categoryId, equals('1'));
      });

      test('should filter series by category ID', () async {
        // Arrange
        final apiSeries = [
          const XtreamSeries(
            num: '1',
            name: 'Drama Series',
            seriesId: '101',
            cover: '',
            plot: '',
            cast: '',
            director: '',
            genre: 'Drama',
            releaseDate: '',
            lastModified: '',
            rating: '',
            categoryId: '1',
          ),
          const XtreamSeries(
            num: '2',
            name: 'Comedy Series',
            seriesId: '102',
            cover: '',
            plot: '',
            cast: '',
            director: '',
            genre: 'Comedy',
            releaseDate: '',
            lastModified: '',
            rating: '',
            categoryId: '2',
          ),
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.getSeries(categoryId: any(named: 'categoryId')))
            .thenAnswer((_) async => ApiResult.success(apiSeries));
        when(() => mockApiClient.getSeriesStreamUrl(any(), any()))
            .thenReturn('http://test.com/stream');
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setInt(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getSeries(categoryId: '1');

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        expect(result.data[0].name, equals('Drama Series'));
      });
    });

    group('getSeriesInfo', () {
      test('should return detailed series info with seasons and episodes', () async {
        // Arrange
        final seriesInfo = XtreamSeriesInfo(
          seasons: [
            const XtreamSeasonInfo(
              airDate: '2008-01-20',
              episodeCount: '7',
              id: '1',
              name: 'Season 1',
              overview: 'First season overview',
              seasonNumber: '1',
            ),
          ],
          info: const XtreamSeriesInfoDetails(
            name: 'Breaking Bad',
            cover: 'http://test.com/cover.png',
            plot: 'A high school teacher turns to making drugs',
            cast: 'Bryan Cranston',
            director: 'Vince Gilligan',
            genre: 'Drama',
            releaseDate: '2008',
            rating: '9.5',
          ),
          episodes: {
            '1': [
              const XtreamEpisode(
                id: '1001',
                episodeNum: '1',
                title: 'Pilot',
                containerExtension: 'mp4',
                info: XtreamEpisodeInfo(
                  name: 'Pilot',
                  overview: 'Episode overview',
                  airDate: '2008-01-20',
                  rating: '9.0',
                ),
              ),
            ],
          },
        );

        when(() => mockApiClient.getSeriesInfo(any()))
            .thenAnswer((_) async => ApiResult.success(seriesInfo));
        when(() => mockApiClient.getSeriesStreamUrl(any(), any()))
            .thenReturn('http://test.com/stream');

        // Act
        final result = await repository.getSeriesInfo('xtream_series_101');

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data.name, equals('Breaking Bad'));
        expect(result.data.seasons.length, equals(1));
        expect(result.data.seasons[0].episodes.length, equals(1));
        expect(result.data.seasons[0].episodes[0].name, equals('Pilot'));
      });

      test('should return failure when series info fetch fails', () async {
        // Arrange
        when(() => mockApiClient.getSeriesInfo(any())).thenAnswer(
          (_) async => ApiResult.failure(
            const ApiError(
              type: ApiErrorType.notFound,
              message: 'Series not found',
            ),
          ),
        );

        // Act
        final result = await repository.getSeriesInfo('xtream_series_999');

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error.message, equals('Series not found'));
      });
    });

    group('Cache Behavior', () {
      test('should return cached data immediately when cache is stale', () async {
        // Arrange
        final cachedSeries = [
          {
            'id': 'xtream_series_101',
            'name': 'Cached Series',
            'categoryId': '1',
          },
        ];

        // Mock stale cache - timestamp from 25 hours ago
        final staleTimestamp = DateTime.now()
            .subtract(const Duration(hours: 25))
            .millisecondsSinceEpoch;

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(cachedSeries));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(staleTimestamp));

        // Mock API response that will happen in background
        when(() => mockApiClient.getSeries(categoryId: any(named: 'categoryId')))
            .thenAnswer((_) async => ApiResult.success([]));
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setInt(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getSeries();

        // Assert
        // Should return cached data immediately
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        expect(result.data[0].name, equals('Cached Series'));

        // Wait a bit to allow background refresh to start
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify that background refresh was initiated
        verify(() => mockApiClient.getSeries(categoryId: any(named: 'categoryId'))).called(1);
      });

      test('should force refresh when forceRefresh is true', () async {
        // Arrange
        final cachedSeries = [
          {
            'id': 'xtream_series_101',
            'name': 'Cached Series',
            'categoryId': '1',
          },
        ];
        final freshApiSeries = [
          const XtreamSeries(
            num: '1',
            name: 'Fresh Series',
            seriesId: '201',
            cover: '',
            plot: '',
            cast: '',
            director: '',
            genre: '',
            releaseDate: '',
            lastModified: '',
            rating: '',
            categoryId: '1',
          ),
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(cachedSeries));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(
                  DateTime.now().millisecondsSinceEpoch,
                ));
        when(() => mockApiClient.getSeries(categoryId: any(named: 'categoryId')))
            .thenAnswer((_) async => ApiResult.success(freshApiSeries));
        when(() => mockApiClient.getSeriesStreamUrl(any(), any()))
            .thenReturn('http://test.com/stream');
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setInt(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getSeries(forceRefresh: true);

        // Assert
        // Should return fresh data from API
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        expect(result.data[0].name, equals('Fresh Series'));

        // API should be called
        verify(() => mockApiClient.getSeries(categoryId: any(named: 'categoryId'))).called(1);
      });
    });

    group('clearCache', () {
      test('should clear all cached data', () async {
        // Arrange
        when(() => mockStorage.remove(any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.clearCache();

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockStorage.remove(any())).called(3); // series, categories, timestamp
      });
    });
  });
}

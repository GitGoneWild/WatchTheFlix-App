import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';
import 'package:watchtheflix/modules/core/storage/storage_service.dart';
import 'package:watchtheflix/modules/xtreamcodes/account/xtream_api_client.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/xtream_epg_repository.dart';
import 'package:watchtheflix/modules/xtreamcodes/models/xtream_api_models.dart';
import 'package:watchtheflix/modules/xtreamcodes/repositories/xtream_live_repository.dart';

class MockXtreamApiClient extends Mock implements XtreamApiClient {}

class MockStorageService extends Mock implements IStorageService {}

class MockXtreamEpgRepository extends Mock implements IXtreamEpgRepository {}

void main() {
  group('XtreamLiveRepository', () {
    late MockXtreamApiClient mockApiClient;
    late MockStorageService mockStorage;
    late MockXtreamEpgRepository mockEpgRepository;
    late XtreamLiveRepository repository;

    setUp(() {
      mockApiClient = MockXtreamApiClient();
      mockStorage = MockStorageService();
      mockEpgRepository = MockXtreamEpgRepository();

      repository = XtreamLiveRepository(
        apiClient: mockApiClient,
        storage: mockStorage,
        epgRepository: mockEpgRepository,
      );
    });

    group('getLiveCategories', () {
      test('should return categories from API when available', () async {
        // Arrange
        final apiCategories = [
          const XtreamLiveCategory(categoryId: '1', categoryName: 'Sports'),
          const XtreamLiveCategory(categoryId: '2', categoryName: 'News'),
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.getLiveCategories())
            .thenAnswer((_) async => ApiResult.success(apiCategories));
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setInt(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getLiveCategories();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(2));
        expect(result.data[0].id, equals('1'));
        expect(result.data[0].name, equals('Sports'));
        expect(result.data[1].id, equals('2'));
        expect(result.data[1].name, equals('News'));
      });

      test('should extract categories from channels when API fails', () async {
        // Arrange
        final apiStreams = [
          const XtreamLiveStream(
            num: '1',
            name: 'ESPN',
            streamType: 'live',
            streamId: '101',
            streamIcon: '',
            epgChannelId: 'espn',
            added: '',
            categoryId: '1',
          ),
          const XtreamLiveStream(
            num: '2',
            name: 'CNN',
            streamType: 'live',
            streamId: '102',
            streamIcon: '',
            epgChannelId: 'cnn',
            added: '',
            categoryId: '2',
          ),
          const XtreamLiveStream(
            num: '3',
            name: 'FOX Sports',
            streamType: 'live',
            streamId: '103',
            streamIcon: '',
            epgChannelId: 'fox',
            added: '',
            categoryId: '1',
          ),
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.getLiveCategories()).thenAnswer(
          (_) async => ApiResult.failure(
            const ApiError(
              type: ApiErrorType.server,
              message: 'Categories API not supported',
            ),
          ),
        );
        when(() => mockApiClient.getLiveStreams(categoryId: any(named: 'categoryId')))
            .thenAnswer((_) async => ApiResult.success(apiStreams));
        when(() => mockApiClient.getLiveStreamUrl(any()))
            .thenReturn('http://test.com/stream');
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setInt(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getLiveCategories();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(2));
        // Categories should be extracted from channel data
        // with channel counts computed correctly
        final cat1 = result.data.firstWhere((c) => c.id == '1');
        final cat2 = result.data.firstWhere((c) => c.id == '2');
        expect(cat1.channelCount, equals(2)); // ESPN, FOX Sports
        expect(cat2.channelCount, equals(1)); // CNN
      });

      test('should return failure when no categories or channels available',
          () async {
        // Arrange
        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.getLiveCategories()).thenAnswer(
          (_) async => ApiResult.failure(
            const ApiError(
              type: ApiErrorType.server,
              message: 'API error',
            ),
          ),
        );
        when(() => mockApiClient.getLiveStreams(categoryId: any(named: 'categoryId')))
            .thenAnswer(
          (_) async => ApiResult.failure(
            const ApiError(
              type: ApiErrorType.server,
              message: 'Streams API error',
            ),
          ),
        );

        // Act
        final result = await repository.getLiveCategories();

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('getLiveChannels', () {
      test('should return channels from API', () async {
        // Arrange
        final apiStreams = [
          const XtreamLiveStream(
            num: '1',
            name: 'Test Channel',
            streamType: 'live',
            streamId: '101',
            streamIcon: 'http://test.com/icon.png',
            epgChannelId: 'test',
            added: '',
            categoryId: '1',
          ),
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.getLiveStreams(categoryId: any(named: 'categoryId')))
            .thenAnswer((_) async => ApiResult.success(apiStreams));
        when(() => mockApiClient.getLiveStreamUrl(any()))
            .thenReturn('http://test.com/stream');
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setInt(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getLiveChannels();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        expect(result.data[0].name, equals('Test Channel'));
        expect(result.data[0].categoryId, equals('1'));
      });

      test('should filter channels by category ID', () async {
        // Arrange
        final apiStreams = [
          const XtreamLiveStream(
            num: '1',
            name: 'Channel Cat 1',
            streamType: 'live',
            streamId: '101',
            streamIcon: '',
            epgChannelId: '',
            added: '',
            categoryId: '1',
          ),
          const XtreamLiveStream(
            num: '2',
            name: 'Channel Cat 2',
            streamType: 'live',
            streamId: '102',
            streamIcon: '',
            epgChannelId: '',
            added: '',
            categoryId: '2',
          ),
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.getLiveStreams(categoryId: any(named: 'categoryId')))
            .thenAnswer((_) async => ApiResult.success(apiStreams));
        when(() => mockApiClient.getLiveStreamUrl(any()))
            .thenReturn('http://test.com/stream');
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setInt(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getLiveChannels(categoryId: '1');

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        expect(result.data[0].name, equals('Channel Cat 1'));
      });

      group('category name enrichment', () {
        void setUpMocksForEnrichment(
          List<XtreamLiveCategory> categories,
          List<XtreamLiveStream> streams,
        ) {
          when(() => mockStorage.getJsonList(any()))
              .thenAnswer((_) async => ApiResult.success(null));
          when(() => mockStorage.getInt(any()))
              .thenAnswer((_) async => ApiResult.success(null));
          when(() => mockApiClient.getLiveCategories())
              .thenAnswer((_) async => ApiResult.success(categories));
          when(() => mockApiClient.getLiveStreams(categoryId: any(named: 'categoryId')))
              .thenAnswer((_) async => ApiResult.success(streams));
          when(() => mockApiClient.getLiveStreamUrl(any()))
              .thenReturn('http://test.com/stream');
          when(() => mockStorage.setJsonList(any(), any()))
              .thenAnswer((_) async => ApiResult.success(null));
          when(() => mockStorage.setInt(any(), any()))
              .thenAnswer((_) async => ApiResult.success(null));
        }

        test('should enrich channels with category names', () async {
          // Arrange
          final apiCategories = [
            const XtreamLiveCategory(categoryId: '1', categoryName: 'Sports'),
            const XtreamLiveCategory(categoryId: '2', categoryName: 'News'),
          ];
          
          final apiStreams = [
            const XtreamLiveStream(
              num: '1',
              name: 'ESPN',
              streamType: 'live',
              streamId: '101',
              streamIcon: '',
              epgChannelId: '',
              added: '',
              categoryId: '1',
            ),
            const XtreamLiveStream(
              num: '2',
              name: 'CNN',
              streamType: 'live',
              streamId: '102',
              streamIcon: '',
              epgChannelId: '',
              added: '',
              categoryId: '2',
            ),
          ];

          setUpMocksForEnrichment(apiCategories, apiStreams);

          // Act
          final result = await repository.getLiveChannels();

          // Assert
          expect(result.isSuccess, isTrue);
          expect(result.data.length, equals(2));
          // Verify that groupTitle is enriched with category names
          expect(result.data[0].groupTitle, equals('Sports'));
          expect(result.data[1].groupTitle, equals('News'));
        });

        test('should handle channels with no matching category gracefully', () async {
          // Arrange
          final apiCategories = [
            const XtreamLiveCategory(categoryId: '1', categoryName: 'Sports'),
          ];
          
          final apiStreams = [
            const XtreamLiveStream(
              num: '1',
              name: 'ESPN',
              streamType: 'live',
              streamId: '101',
              streamIcon: '',
              epgChannelId: '',
              added: '',
              categoryId: '1',
            ),
            const XtreamLiveStream(
              num: '2',
              name: 'Unknown Channel',
              streamType: 'live',
              streamId: '102',
              streamIcon: '',
              epgChannelId: '',
              added: '',
              categoryId: '999', // Category not in API response
            ),
          ];

          setUpMocksForEnrichment(apiCategories, apiStreams);

          // Act
          final result = await repository.getLiveChannels();

          // Assert
          expect(result.isSuccess, isTrue);
          expect(result.data.length, equals(2));
          // Verify that known category is enriched
          expect(result.data[0].groupTitle, equals('Sports'));
          // Verify that unknown category has null groupTitle (not enriched)
          expect(result.data[1].groupTitle, isNull);
        });
      });

      group('Cache Behavior', () {
        test('should return cached data immediately when cache is stale', () async {
          // Arrange
          final cachedChannels = [
            {
              'id': '101',
              'name': 'Cached Channel',
              'streamUrl': 'http://test.com/stream',
              'categoryId': '1',
              'type': 0,
            },
          ];

          // Mock stale cache - timestamp from 25 hours ago
          final staleTimestamp = DateTime.now()
              .subtract(const Duration(hours: 25))
              .millisecondsSinceEpoch;

          when(() => mockStorage.getJsonList(any()))
              .thenAnswer((_) async => ApiResult.success(cachedChannels));
          when(() => mockStorage.getInt(any()))
              .thenAnswer((_) async => ApiResult.success(staleTimestamp));

          // Mock API response that will happen in background
          when(() => mockApiClient.getLiveStreams(categoryId: any(named: 'categoryId')))
              .thenAnswer((_) async => ApiResult.success([]));
          when(() => mockStorage.setJsonList(any(), any()))
              .thenAnswer((_) async => ApiResult.success(null));
          when(() => mockStorage.setInt(any(), any()))
              .thenAnswer((_) async => ApiResult.success(null));

          // Act
          final result = await repository.getLiveChannels();

          // Assert
          // Should return cached data immediately
          expect(result.isSuccess, isTrue);
          expect(result.data.length, equals(1));
          expect(result.data[0].name, equals('Cached Channel'));
          
          // Background refresh should be triggered (fire and forget)
          // Wait a bit to allow background refresh to start
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Verify that background refresh was initiated
          verify(() => mockApiClient.getLiveStreams(categoryId: any(named: 'categoryId'))).called(1);
        });

        test('should force refresh when forceRefresh is true', () async {
          // Arrange
          final cachedChannels = [
            {
              'id': '101',
              'name': 'Cached Channel',
              'streamUrl': 'http://test.com/stream',
              'categoryId': '1',
              'type': 0,
            },
          ];
          final freshApiStreams = [
            const XtreamLiveStream(
              num: '1',
              name: 'Fresh Channel',
              streamType: 'live',
              streamId: '201',
              streamIcon: '',
              epgChannelId: '',
              added: '',
              categoryId: '1',
            ),
          ];

          when(() => mockStorage.getJsonList(any()))
              .thenAnswer((_) async => ApiResult.success(cachedChannels));
          when(() => mockStorage.getInt(any()))
              .thenAnswer((_) async => ApiResult.success(
                    DateTime.now().millisecondsSinceEpoch,
                  ));
          when(() => mockApiClient.getLiveStreams(categoryId: any(named: 'categoryId')))
              .thenAnswer((_) async => ApiResult.success(freshApiStreams));
          when(() => mockApiClient.getLiveStreamUrl(any()))
              .thenReturn('http://test.com/stream');
          when(() => mockStorage.setJsonList(any(), any()))
              .thenAnswer((_) async => ApiResult.success(null));
          when(() => mockStorage.setInt(any(), any()))
              .thenAnswer((_) async => ApiResult.success(null));

          // Act
          final result = await repository.getLiveChannels(forceRefresh: true);

          // Assert
          // Should return fresh data from API
          expect(result.isSuccess, isTrue);
          expect(result.data.length, equals(1));
          expect(result.data[0].name, equals('Fresh Channel'));
          
          // API should be called
          verify(() => mockApiClient.getLiveStreams(categoryId: any(named: 'categoryId'))).called(1);
        });
      });
    });

    group('Background EPG Enrichment', () {
      test('should enrich channels with EPG data in background', () async {
        // Arrange
        final cachedChannels = [
          {
            'id': 'channel_1',
            'name': 'Channel 1',
            'streamUrl': 'http://test.com/stream1',
            'categoryId': '1',
            'type': 'live',
            'metadata': {'epgChannelId': 'epg_1'},
          },
        ];
        
        final epgProgram = EpgProgram(
          channelId: 'epg_1',
          start: DateTime.now(),
          stop: DateTime.now().add(const Duration(hours: 1)),
          title: 'Test Program',
        );

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(cachedChannels));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(
                  DateTime.now().millisecondsSinceEpoch,
                ));
        when(() => mockApiClient.getLiveCategories())
            .thenAnswer((_) async => ApiResult.success([]));
        when(() => mockEpgRepository.getCurrentAndNextProgram(any()))
            .thenAnswer((_) async => ApiResult.success(
                  EpgProgramPair(current: epgProgram, next: null),
                ));

        // Act
        final result = await repository.getLiveChannels();

        // Assert - channels should be returned immediately without EPG
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        
        // Wait for background enrichment to complete
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify EPG repository was called
        verify(() => mockEpgRepository.getCurrentAndNextProgram('epg_1')).called(1);
      });

      test('should handle EPG enrichment failures gracefully', () async {
        // Arrange
        final cachedChannels = [
          {
            'id': 'channel_1',
            'name': 'Channel 1',
            'streamUrl': 'http://test.com/stream1',
            'categoryId': '1',
            'type': 'live',
            'metadata': {'epgChannelId': 'epg_1'},
          },
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(cachedChannels));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(
                  DateTime.now().millisecondsSinceEpoch,
                ));
        when(() => mockApiClient.getLiveCategories())
            .thenAnswer((_) async => ApiResult.success([]));
        when(() => mockEpgRepository.getCurrentAndNextProgram(any()))
            .thenAnswer((_) async => ApiResult.failure(
                  const ApiError(
                    type: ApiErrorType.network,
                    message: 'EPG fetch failed',
                  ),
                ));

        // Act
        final result = await repository.getLiveChannels();

        // Assert - should still return channels even if EPG fails
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        
        // Wait for background enrichment to complete
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify EPG repository was called but failure was handled
        verify(() => mockEpgRepository.getCurrentAndNextProgram('epg_1')).called(1);
      });

      test('should skip channels without EPG IDs', () async {
        // Arrange
        final cachedChannels = [
          {
            'id': 'channel_1',
            'name': 'Channel 1',
            'streamUrl': 'http://test.com/stream1',
            'categoryId': '1',
            'type': 'live',
            'metadata': {}, // No epgChannelId
          },
        ];

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(cachedChannels));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(
                  DateTime.now().millisecondsSinceEpoch,
                ));
        when(() => mockApiClient.getLiveCategories())
            .thenAnswer((_) async => ApiResult.success([]));

        // Act
        final result = await repository.getLiveChannels();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        
        // Wait for background enrichment to complete
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify EPG repository was never called
        verifyNever(() => mockEpgRepository.getCurrentAndNextProgram(any()));
      });

      test('should prevent concurrent EPG enrichment', () async {
        // Arrange
        final cachedChannels = [
          {
            'id': 'channel_1',
            'name': 'Channel 1',
            'streamUrl': 'http://test.com/stream1',
            'categoryId': '1',
            'type': 'live',
            'metadata': {'epgChannelId': 'epg_1'},
          },
        ];
        
        final epgProgram = EpgProgram(
          channelId: 'epg_1',
          start: DateTime.now(),
          stop: DateTime.now().add(const Duration(hours: 1)),
          title: 'Test Program',
        );

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(cachedChannels));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(
                  DateTime.now().millisecondsSinceEpoch,
                ));
        when(() => mockApiClient.getLiveCategories())
            .thenAnswer((_) async => ApiResult.success([]));
        when(() => mockEpgRepository.getCurrentAndNextProgram(any()))
            .thenAnswer((_) async {
          // Simulate slow EPG fetch
          await Future.delayed(const Duration(milliseconds: 100));
          return ApiResult.success(
            EpgProgramPair(current: epgProgram, next: null),
          );
        });

        // Act - Make two rapid calls
        final result1 = await repository.getLiveChannels();
        final result2 = await repository.getLiveChannels();

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        
        // Wait for background enrichment to complete
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Verify EPG repository was called only once (second call skipped)
        verify(() => mockEpgRepository.getCurrentAndNextProgram('epg_1')).called(1);
      });

      test('should not lose channels when enriching full cache', () async {
        // Arrange - Multiple channels with different categories
        final cachedChannels = [
          {
            'id': 'channel_1',
            'name': 'Sports Channel',
            'streamUrl': 'http://test.com/stream1',
            'categoryId': '1',
            'type': 'live',
            'metadata': {'epgChannelId': 'epg_1'},
          },
          {
            'id': 'channel_2',
            'name': 'News Channel',
            'streamUrl': 'http://test.com/stream2',
            'categoryId': '2',
            'type': 'live',
            'metadata': {'epgChannelId': 'epg_2'},
          },
        ];
        
        final epgProgram = EpgProgram(
          channelId: 'epg_1',
          start: DateTime.now(),
          stop: DateTime.now().add(const Duration(hours: 1)),
          title: 'Test Program',
        );

        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(cachedChannels));
        when(() => mockStorage.getInt(any()))
            .thenAnswer((_) async => ApiResult.success(
                  DateTime.now().millisecondsSinceEpoch,
                ));
        when(() => mockApiClient.getLiveCategories())
            .thenAnswer((_) async => ApiResult.success([]));
        when(() => mockEpgRepository.getCurrentAndNextProgram(any()))
            .thenAnswer((_) async => ApiResult.success(
                  EpgProgramPair(current: epgProgram, next: null),
                ));

        // Act - Get channels with category filter
        final result = await repository.getLiveChannels(categoryId: '1');

        // Assert - Should return only filtered channel
        expect(result.isSuccess, isTrue);
        expect(result.data.length, equals(1));
        expect(result.data[0].name, equals('Sports Channel'));
        
        // Wait for background enrichment to complete
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Get all channels again to verify cache integrity
        final allChannelsResult = await repository.getLiveChannels();
        
        // Both channels should still be in cache
        expect(allChannelsResult.isSuccess, isTrue);
        expect(allChannelsResult.data.length, equals(2));
      });
    });
  });
}

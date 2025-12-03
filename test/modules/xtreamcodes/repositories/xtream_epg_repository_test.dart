import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';
import 'package:watchtheflix/modules/core/storage/storage_service.dart';
import 'package:watchtheflix/modules/xtreamcodes/account/xtream_api_client.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/epg_models.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/xmltv_parser.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/xtream_epg_repository.dart';

class MockXtreamApiClient extends Mock implements XtreamApiClient {}

class MockXmltvParser extends Mock implements IXmltvParser {}

class MockStorageService extends Mock implements IStorageService {}

void main() {
  group('XtreamEpgRepository', () {
    late MockXtreamApiClient mockApiClient;
    late MockXmltvParser mockXmltvParser;
    late MockStorageService mockStorage;
    late XtreamEpgRepository repository;

    setUp(() {
      mockApiClient = MockXtreamApiClient();
      mockXmltvParser = MockXmltvParser();
      mockStorage = MockStorageService();

      repository = XtreamEpgRepository(
        apiClient: mockApiClient,
        xmltvParser: mockXmltvParser,
        storage: mockStorage,
      );
    });

    group('Background EPG Refresh', () {
      test('should refresh EPG in background when cache is stale', () async {
        // Arrange
        final xmltvData = XmltvData(
          channels: [
            const XmltvChannel(id: 'ch1', displayName: 'Channel 1'),
          ],
          programs: [
            EpgProgram(
              channelId: 'ch1',
              start: DateTime.now(),
              stop: DateTime.now().add(const Duration(hours: 1)),
              title: 'Test Program',
            ),
          ],
        );

        // Mock cache as stale (old timestamp)
        when(() => mockStorage.getJson(any())).thenAnswer(
          (_) async => ApiResult.success({
            'lastUpdated': DateTime.now()
                .subtract(const Duration(hours: 25))
                .toIso8601String(),
            'programCount': 0,
            'channelCount': 0,
          }),
        );
        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.downloadXmltvEpg())
            .thenAnswer((_) async => ApiResult.success('<xmltv></xmltv>'));
        when(() => mockXmltvParser.parse(any()))
            .thenReturn(ApiResult.success(xmltvData));
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setJson(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        final result = await repository.getEpgForChannel('ch1');

        // Assert - Should return empty result but trigger background refresh
        expect(result.isFailure, isTrue);

        // Wait for background refresh to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify refresh was triggered
        verify(() => mockApiClient.downloadXmltvEpg()).called(1);
        verify(() => mockXmltvParser.parse(any())).called(1);
      });

      test('should handle background refresh failures gracefully', () async {
        // Arrange
        when(() => mockStorage.getJson(any())).thenAnswer(
          (_) async => ApiResult.success({
            'lastUpdated': DateTime.now()
                .subtract(const Duration(hours: 25))
                .toIso8601String(),
            'programCount': 0,
            'channelCount': 0,
          }),
        );
        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.downloadXmltvEpg()).thenAnswer(
          (_) async => ApiResult.failure(
            const ApiError(
              type: ApiErrorType.network,
              message: 'Network error',
            ),
          ),
        );

        // Act
        final result = await repository.getEpgForChannel('ch1');

        // Assert - Should return failure but not crash
        expect(result.isFailure, isTrue);

        // Wait for background refresh to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify refresh was attempted
        verify(() => mockApiClient.downloadXmltvEpg()).called(1);
      });

      test('should not refresh if cache is fresh', () async {
        // Arrange
        final cachedPrograms = [
          {
            'channelId': 'ch1',
            'start': DateTime.now().toIso8601String(),
            'stop': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
            'title': 'Cached Program',
          },
        ];

        // Mock fresh cache (recent timestamp)
        when(() => mockStorage.getJson(any())).thenAnswer(
          (_) async => ApiResult.success({
            'lastUpdated': DateTime.now().toIso8601String(),
            'programCount': 1,
            'channelCount': 1,
          }),
        );
        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(cachedPrograms));

        // Act
        final result = await repository.getEpgForChannel('ch1');

        // Assert - Should return cached data
        expect(result.isSuccess, isTrue);

        // Wait to ensure no background refresh is triggered
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify no API call was made
        verifyNever(() => mockApiClient.downloadXmltvEpg());
      });

      test('should prevent concurrent refresh operations', () async {
        // Arrange
        final xmltvData = XmltvData(
          channels: [
            const XmltvChannel(id: 'ch1', displayName: 'Channel 1'),
          ],
          programs: [
            EpgProgram(
              channelId: 'ch1',
              start: DateTime.now(),
              stop: DateTime.now().add(const Duration(hours: 1)),
              title: 'Test Program',
            ),
          ],
        );

        when(() => mockStorage.getJson(any())).thenAnswer(
          (_) async => ApiResult.success({
            'lastUpdated': DateTime.now()
                .subtract(const Duration(hours: 25))
                .toIso8601String(),
            'programCount': 0,
            'channelCount': 0,
          }),
        );
        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.downloadXmltvEpg()).thenAnswer((_) async {
          // Simulate slow download
          await Future.delayed(const Duration(milliseconds: 100));
          return ApiResult.success('<xmltv></xmltv>');
        });
        when(() => mockXmltvParser.parse(any()))
            .thenReturn(ApiResult.success(xmltvData));
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setJson(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act - Make multiple concurrent calls
        final result1 = repository.getEpgForChannel('ch1');
        final result2 = repository.getEpgForChannel('ch1');
        final result3 = repository.getEpgForChannel('ch1');

        await Future.wait([result1, result2, result3]);

        // Wait for background refresh to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Verify download was called only once
        verify(() => mockApiClient.downloadXmltvEpg()).called(1);
      });

      test('should update cache after successful background refresh', () async {
        // Arrange
        final xmltvData = XmltvData(
          channels: [
            const XmltvChannel(id: 'ch1', displayName: 'Channel 1'),
          ],
          programs: [
            EpgProgram(
              channelId: 'ch1',
              start: DateTime.now(),
              stop: DateTime.now().add(const Duration(hours: 1)),
              title: 'Fresh Program',
            ),
          ],
        );

        when(() => mockStorage.getJson(any())).thenAnswer(
          (_) async => ApiResult.success({
            'lastUpdated': DateTime.now()
                .subtract(const Duration(hours: 25))
                .toIso8601String(),
            'programCount': 0,
            'channelCount': 0,
          }),
        );
        when(() => mockStorage.getJsonList(any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockApiClient.downloadXmltvEpg())
            .thenAnswer((_) async => ApiResult.success('<xmltv></xmltv>'));
        when(() => mockXmltvParser.parse(any()))
            .thenReturn(ApiResult.success(xmltvData));
        when(() => mockStorage.setJsonList(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));
        when(() => mockStorage.setJson(any(), any()))
            .thenAnswer((_) async => ApiResult.success(null));

        // Act
        await repository.getEpgForChannel('ch1');

        // Wait for background refresh to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify cache was updated
        verify(() => mockStorage.setJsonList(any(), any())).called(1);
        verify(() => mockStorage.setJson(any(), any())).called(1);
      });
    });
  });
}

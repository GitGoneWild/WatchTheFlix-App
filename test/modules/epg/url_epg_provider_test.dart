import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/epg/url_epg_provider.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/epg_models.dart';

void main() {
  group('UrlEpgProvider', () {
    late UrlEpgProvider provider;

    setUp(() {
      provider = UrlEpgProvider();
    });

    group('URL validation', () {
      test('should reject empty URL', () async {
        final result = await provider.fetchEpg('');

        expect(result.isFailure, isTrue);
        expect(result.error.type, equals(ApiErrorType.validation));
        expect(result.error.message, contains('cannot be empty'));
      });

      test('should reject URL without scheme', () async {
        final result = await provider.fetchEpg('example.com/epg.xml');

        expect(result.isFailure, isTrue);
        expect(result.error.type, equals(ApiErrorType.validation));
        expect(result.error.message, contains('http://'));
      });

      test('should reject invalid URL format', () async {
        final result = await provider.fetchEpg('not a valid url');

        expect(result.isFailure, isTrue);
        expect(result.error.type, equals(ApiErrorType.validation));
      });

      test('should reject URL without host', () async {
        final result = await provider.fetchEpg('http:///epg.xml');

        expect(result.isFailure, isTrue);
        expect(result.error.type, equals(ApiErrorType.validation));
        expect(result.error.message, contains('valid host'));
      });
    });

    group('validateUrl', () {
      test('should reject empty URL', () async {
        final result = await provider.validateUrl('');

        expect(result.isFailure, isTrue);
        expect(result.error.type, equals(ApiErrorType.validation));
      });

      test('should reject URL without scheme', () async {
        final result = await provider.validateUrl('example.com/epg.xml');

        expect(result.isFailure, isTrue);
        expect(result.error.type, equals(ApiErrorType.validation));
      });

      test('should reject invalid URL', () async {
        final result = await provider.validateUrl('::::invalid');

        expect(result.isFailure, isTrue);
      });
    });
  });

  group('EpgFetchResult', () {
    test('should create success result', () {
      final data = EpgData.empty();
      final result = EpgFetchResult.success(data);

      expect(result.success, isTrue);
      expect(result.data, equals(data));
      expect(result.errorMessage, isNull);
      expect(result.fetchedAt, isNotNull);
    });

    test('should create failure result', () {
      final result = EpgFetchResult.failure('Test error');

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Test error'));
      expect(result.data.isEmpty, isTrue);
    });

    test('should create failure result with cached data', () {
      final cachedData = EpgData(
        channels: const {'ch1': EpgChannel(id: 'ch1', name: 'Channel 1')},
        programs: const {},
        fetchedAt: DateTime.now(),
      );
      final result = EpgFetchResult.failure('Test error', cachedData: cachedData);

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Test error'));
      expect(result.data.channels.length, equals(1));
    });
  });
}

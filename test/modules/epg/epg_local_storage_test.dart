import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/epg/epg_local_storage.dart';
import 'package:watchtheflix/modules/epg/epg_source.dart';

void main() {
  group('EpgStorageMetadata', () {
    group('toJson/fromJson', () {
      test('should serialize and deserialize correctly', () {
        final metadata = EpgStorageMetadata(
          sourceId: 'test-source',
          lastFetchedAt: DateTime(2024, 1, 15, 10, 30),
          channelCount: 50,
          programCount: 500,
          sourceUrl: 'https://example.com/epg.xml',
          sourceType: EpgSourceType.url,
        );

        final json = metadata.toJson();
        final restored = EpgStorageMetadata.fromJson(json);

        expect(restored.sourceId, equals(metadata.sourceId));
        expect(restored.lastFetchedAt, equals(metadata.lastFetchedAt));
        expect(restored.channelCount, equals(metadata.channelCount));
        expect(restored.programCount, equals(metadata.programCount));
        expect(restored.sourceUrl, equals(metadata.sourceUrl));
        expect(restored.sourceType, equals(metadata.sourceType));
      });

      test('should handle null lastFetchedAt', () {
        const metadata = EpgStorageMetadata(
          sourceId: 'test-source',
          channelCount: 10,
          programCount: 100,
        );

        final json = metadata.toJson();
        final restored = EpgStorageMetadata.fromJson(json);

        expect(restored.lastFetchedAt, isNull);
      });

      test('should handle missing fields in JSON', () {
        final json = <String, dynamic>{};
        final metadata = EpgStorageMetadata.fromJson(json);

        expect(metadata.sourceId, equals(''));
        expect(metadata.lastFetchedAt, isNull);
        expect(metadata.channelCount, equals(0));
        expect(metadata.programCount, equals(0));
        expect(metadata.sourceType, equals(EpgSourceType.none));
      });
    });
  });

  group('EpgLocalStorage static methods', () {
    test('generateSourceId should create consistent IDs', () {
      final id1 = EpgLocalStorage.generateSourceId('https://example.com/epg.xml');
      final id2 = EpgLocalStorage.generateSourceId('https://example.com/epg.xml');
      final id3 = EpgLocalStorage.generateSourceId('https://example.com/other.xml');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
      expect(id1, startsWith('url_'));
    });

    test('generateXtreamSourceId should create correct format', () {
      final id = EpgLocalStorage.generateXtreamSourceId('profile-123');

      expect(id, equals('xtream_profile-123'));
    });
  });
}

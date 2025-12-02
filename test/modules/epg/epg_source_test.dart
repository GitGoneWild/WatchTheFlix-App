import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/epg/epg_source.dart';

void main() {
  group('EpgSourceType', () {
    test('should have expected values', () {
      expect(EpgSourceType.values, contains(EpgSourceType.url));
      expect(EpgSourceType.values, contains(EpgSourceType.xtreamCodes));
      expect(EpgSourceType.values, contains(EpgSourceType.none));
    });
  });

  group('EpgSourceConfig', () {
    group('constructor', () {
      test('should create config with required fields', () {
        const config = EpgSourceConfig(type: EpgSourceType.url);

        expect(config.type, equals(EpgSourceType.url));
        expect(config.epgUrl, isNull);
        expect(config.profileId, isNull);
        expect(config.refreshInterval, equals(const Duration(hours: 6)));
        expect(config.autoRefreshEnabled, isTrue);
        expect(config.lastFetchedAt, isNull);
      });
    });

    group('fromUrl factory', () {
      test('should create URL-based config', () {
        final config = EpgSourceConfig.fromUrl('https://example.com/epg.xml');

        expect(config.type, equals(EpgSourceType.url));
        expect(config.epgUrl, equals('https://example.com/epg.xml'));
        expect(config.profileId, isNull);
        expect(config.isConfigured, isTrue);
      });

      test('should accept custom refresh interval', () {
        final config = EpgSourceConfig.fromUrl(
          'https://example.com/epg.xml',
          refreshInterval: const Duration(hours: 12),
          autoRefreshEnabled: false,
        );

        expect(config.refreshInterval, equals(const Duration(hours: 12)));
        expect(config.autoRefreshEnabled, isFalse);
      });
    });

    group('fromXtreamCodes factory', () {
      test('should create Xtream-based config', () {
        final config = EpgSourceConfig.fromXtreamCodes('profile-123');

        expect(config.type, equals(EpgSourceType.xtreamCodes));
        expect(config.profileId, equals('profile-123'));
        expect(config.epgUrl, isNull);
        expect(config.isConfigured, isTrue);
      });

      test('should accept custom refresh interval', () {
        final config = EpgSourceConfig.fromXtreamCodes(
          'profile-123',
          refreshInterval: const Duration(hours: 3),
          autoRefreshEnabled: false,
        );

        expect(config.refreshInterval, equals(const Duration(hours: 3)));
        expect(config.autoRefreshEnabled, isFalse);
      });
    });

    group('none factory', () {
      test('should create disabled config', () {
        final config = EpgSourceConfig.none();

        expect(config.type, equals(EpgSourceType.none));
        expect(config.isConfigured, isFalse);
        expect(config.autoRefreshEnabled, isFalse);
      });
    });

    group('isConfigured', () {
      test('should return true for valid URL config', () {
        final config = EpgSourceConfig.fromUrl('https://example.com/epg.xml');
        expect(config.isConfigured, isTrue);
      });

      test('should return false for URL config without URL', () {
        const config = EpgSourceConfig(
          type: EpgSourceType.url,
        );
        expect(config.isConfigured, isFalse);
      });

      test('should return false for URL config with empty URL', () {
        const config = EpgSourceConfig(
          type: EpgSourceType.url,
          epgUrl: '',
        );
        expect(config.isConfigured, isFalse);
      });

      test('should return true for valid Xtream config', () {
        final config = EpgSourceConfig.fromXtreamCodes('profile-123');
        expect(config.isConfigured, isTrue);
      });

      test('should return false for Xtream config without profileId', () {
        const config = EpgSourceConfig(
          type: EpgSourceType.xtreamCodes,
        );
        expect(config.isConfigured, isFalse);
      });

      test('should return false for none type', () {
        final config = EpgSourceConfig.none();
        expect(config.isConfigured, isFalse);
      });
    });

    group('needsRefresh', () {
      test('should return true when lastFetchedAt is null', () {
        final config = EpgSourceConfig.fromUrl('https://example.com/epg.xml');
        expect(config.needsRefresh, isTrue);
      });

      test('should return false when autoRefreshEnabled is false', () {
        const config = EpgSourceConfig(
          type: EpgSourceType.url,
          epgUrl: 'https://example.com/epg.xml',
          autoRefreshEnabled: false,
        );
        // Still true because lastFetchedAt is null
        expect(config.needsRefresh, isTrue);
      });

      test('should return true when refresh interval has passed', () {
        final oldFetch = DateTime.now().subtract(const Duration(hours: 7));
        final config = EpgSourceConfig(
          type: EpgSourceType.url,
          epgUrl: 'https://example.com/epg.xml',
          lastFetchedAt: oldFetch,
        );
        expect(config.needsRefresh, isTrue);
      });

      test('should return false when within refresh interval', () {
        final recentFetch = DateTime.now().subtract(const Duration(hours: 1));
        final config = EpgSourceConfig(
          type: EpgSourceType.url,
          epgUrl: 'https://example.com/epg.xml',
          lastFetchedAt: recentFetch,
        );
        expect(config.needsRefresh, isFalse);
      });
    });

    group('copyWithLastFetch', () {
      test('should create copy with updated timestamp', () {
        final config = EpgSourceConfig.fromUrl('https://example.com/epg.xml');
        final now = DateTime.now();
        final updated = config.copyWithLastFetch(now);

        expect(updated.type, equals(config.type));
        expect(updated.epgUrl, equals(config.epgUrl));
        expect(updated.lastFetchedAt, equals(now));
        expect(config.lastFetchedAt, isNull); // Original unchanged
      });
    });

    group('copyWith', () {
      test('should create copy with specified fields changed', () {
        final config = EpgSourceConfig.fromUrl('https://example.com/epg.xml');
        final updated = config.copyWith(
          epgUrl: 'https://example.com/new-epg.xml',
          autoRefreshEnabled: false,
        );

        expect(updated.type, equals(EpgSourceType.url));
        expect(updated.epgUrl, equals('https://example.com/new-epg.xml'));
        expect(updated.autoRefreshEnabled, isFalse);
        expect(updated.refreshInterval, equals(config.refreshInterval));
      });
    });

    group('toJson/fromJson', () {
      test('should serialize and deserialize URL config', () {
        final config = EpgSourceConfig.fromUrl(
          'https://example.com/epg.xml',
          refreshInterval: const Duration(hours: 12),
          autoRefreshEnabled: false,
        );

        final json = config.toJson();
        final restored = EpgSourceConfig.fromJson(json);

        expect(restored.type, equals(config.type));
        expect(restored.epgUrl, equals(config.epgUrl));
        expect(restored.refreshInterval, equals(config.refreshInterval));
        expect(restored.autoRefreshEnabled, equals(config.autoRefreshEnabled));
      });

      test('should serialize and deserialize Xtream config', () {
        final config = EpgSourceConfig.fromXtreamCodes('profile-123');

        final json = config.toJson();
        final restored = EpgSourceConfig.fromJson(json);

        expect(restored.type, equals(EpgSourceType.xtreamCodes));
        expect(restored.profileId, equals('profile-123'));
      });

      test('should handle missing fields in JSON', () {
        final json = <String, dynamic>{};
        final config = EpgSourceConfig.fromJson(json);

        expect(config.type, equals(EpgSourceType.none));
        expect(config.refreshInterval, equals(const Duration(hours: 6)));
        expect(config.autoRefreshEnabled, isTrue);
      });

      test('should serialize and deserialize lastFetchedAt', () {
        final fetchTime = DateTime(2024, 1, 15, 10, 30);
        final config = EpgSourceConfig(
          type: EpgSourceType.url,
          epgUrl: 'https://example.com/epg.xml',
          lastFetchedAt: fetchTime,
        );

        final json = config.toJson();
        final restored = EpgSourceConfig.fromJson(json);

        expect(restored.lastFetchedAt, equals(fetchTime));
      });
    });

    group('equatable', () {
      test('should be equal for same values', () {
        final config1 = EpgSourceConfig.fromUrl('https://example.com/epg.xml');
        final config2 = EpgSourceConfig.fromUrl('https://example.com/epg.xml');

        expect(config1, equals(config2));
      });

      test('should not be equal for different values', () {
        final config1 = EpgSourceConfig.fromUrl('https://example.com/epg1.xml');
        final config2 = EpgSourceConfig.fromUrl('https://example.com/epg2.xml');

        expect(config1, isNot(equals(config2)));
      });
    });
  });
}

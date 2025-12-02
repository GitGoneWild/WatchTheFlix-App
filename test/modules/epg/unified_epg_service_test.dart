import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';
import 'package:watchtheflix/modules/epg/epg_source.dart';
import 'package:watchtheflix/modules/epg/unified_epg_service.dart';

void main() {
  group('UnifiedEpgService', () {
    late UnifiedEpgService service;

    setUp(() {
      service = UnifiedEpgService();
    });

    group('initialization', () {
      test('should start unconfigured', () {
        expect(service.isConfigured, isFalse);
        expect(service.hasData, isFalse);
        expect(service.sourceConfig.type, equals(EpgSourceType.none));
      });

      test('should accept initial config', () {
        final config = EpgSourceConfig.fromUrl('https://example.com/epg.xml');
        final serviceWithConfig = UnifiedEpgService(initialConfig: config);

        expect(serviceWithConfig.isConfigured, isTrue);
        expect(serviceWithConfig.sourceConfig.type, equals(EpgSourceType.url));
      });
    });

    group('configureUrl', () {
      test('should configure URL source', () {
        service.configureUrl('https://example.com/epg.xml');

        expect(service.isConfigured, isTrue);
        expect(service.sourceConfig.type, equals(EpgSourceType.url));
        expect(
            service.sourceConfig.epgUrl, equals('https://example.com/epg.xml'));
      });

      test('should accept custom refresh interval', () {
        service.configureUrl(
          'https://example.com/epg.xml',
          refreshInterval: const Duration(hours: 12),
          autoRefresh: false,
        );

        expect(service.sourceConfig.refreshInterval,
            equals(const Duration(hours: 12)));
        expect(service.sourceConfig.autoRefreshEnabled, isFalse);
      });

      test('should clear Xtream credentials when switching to URL', () {
        // First configure Xtream
        const credentials = XtreamCredentialsModel(
          host: 'https://provider.com',
          username: 'user',
          password: 'pass',
        );
        service.configureXtream('profile-1', credentials);
        expect(service.xtreamCredentials, isNotNull);

        // Now configure URL
        service.configureUrl('https://example.com/epg.xml');
        expect(service.xtreamCredentials, isNull);
      });
    });

    group('configureXtream', () {
      test('should configure Xtream source', () {
        const credentials = XtreamCredentialsModel(
          host: 'https://provider.com',
          username: 'user',
          password: 'pass',
        );

        service.configureXtream('profile-1', credentials);

        expect(service.isConfigured, isTrue);
        expect(service.sourceConfig.type, equals(EpgSourceType.xtreamCodes));
        expect(service.sourceConfig.profileId, equals('profile-1'));
        expect(service.xtreamCredentials, equals(credentials));
      });

      test('should accept custom refresh interval', () {
        const credentials = XtreamCredentialsModel(
          host: 'https://provider.com',
          username: 'user',
          password: 'pass',
        );

        service.configureXtream(
          'profile-1',
          credentials,
          refreshInterval: const Duration(hours: 3),
          autoRefresh: false,
        );

        expect(service.sourceConfig.refreshInterval,
            equals(const Duration(hours: 3)));
        expect(service.sourceConfig.autoRefreshEnabled, isFalse);
      });
    });

    group('clearConfiguration', () {
      test('should clear all configuration', () {
        service.configureUrl('https://example.com/epg.xml');
        expect(service.isConfigured, isTrue);

        service.clearConfiguration();

        expect(service.isConfigured, isFalse);
        expect(service.sourceConfig.type, equals(EpgSourceType.none));
        expect(service.xtreamCredentials, isNull);
      });
    });

    group('fetchEpg', () {
      test('should return error when not configured', () async {
        final result = await service.fetchEpg();

        expect(result.isFailure, isTrue);
        expect(result.error.message, contains('not configured'));
      });
    });

    group('getCachedData', () {
      test('should return null when no data cached', () {
        expect(service.getCachedData(), isNull);
      });
    });

    group('needsRefresh', () {
      test('should return true when not configured', () {
        expect(service.needsRefresh, isTrue);
      });

      test('should return true for fresh config without fetch', () {
        service.configureUrl('https://example.com/epg.xml');
        expect(service.needsRefresh, isTrue);
      });
    });

    group('getStatistics', () {
      test('should return empty statistics when not configured', () {
        final stats = service.getStatistics();

        expect(stats['sourceType'], equals('none'));
        expect(stats['isConfigured'], isFalse);
        expect(stats['hasData'], isFalse);
        expect(stats['channelCount'], equals(0));
        expect(stats['programCount'], equals(0));
      });

      test('should return statistics for configured service', () {
        service.configureUrl('https://example.com/epg.xml');
        final stats = service.getStatistics();

        expect(stats['sourceType'], equals('url'));
        expect(stats['isConfigured'], isTrue);
        expect(stats['hasData'], isFalse);
      });
    });

    group('validateUrl', () {
      test('should reject empty URL', () async {
        final result = await service.validateUrl('');

        expect(result.isFailure, isTrue);
      });

      test('should reject invalid URL', () async {
        final result = await service.validateUrl('not a url');

        expect(result.isFailure, isTrue);
      });
    });
  });
}

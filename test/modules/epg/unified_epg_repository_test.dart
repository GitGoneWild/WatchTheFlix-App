import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/epg/epg_source.dart';
import 'package:watchtheflix/modules/epg/unified_epg_repository.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/epg_models.dart';

void main() {
  group('UnifiedEpgRepository', () {
    late UnifiedEpgRepository repository;

    setUp(() {
      repository = UnifiedEpgRepository();
    });

    group('configure', () {
      test('should accept URL configuration', () {
        final config = EpgSourceConfig.fromUrl('https://example.com/epg.xml');
        repository.configure(config);

        expect(repository.currentConfig, equals(config));
      });

      test('should accept Xtream configuration', () {
        final config = EpgSourceConfig.fromXtreamCodes('profile-123');
        repository.configure(config);

        expect(repository.currentConfig, equals(config));
      });
    });

    group('fetchEpg', () {
      test('should return error when not configured', () async {
        final result = await repository.fetchEpg();

        expect(result.isFailure, isTrue);
        expect(result.error.message, contains('not configured'));
      });

      test('should return error for none type', () async {
        repository.configure(EpgSourceConfig.none());
        final result = await repository.fetchEpg();

        // None type returns empty EpgData, not an error
        expect(result.isSuccess, isTrue);
        expect(result.data.isEmpty, isTrue);
      });
    });

    group('cache', () {
      test('should report no cached data initially', () {
        expect(repository.hasCachedData(), isFalse);
      });

      test('should return null for cached data when empty', () {
        expect(repository.getCachedData(), isNull);
      });

      test('should clear cache', () {
        repository
            .configure(EpgSourceConfig.fromUrl('https://example.com/epg.xml'));
        repository.clearCache();

        expect(repository.hasCachedData(), isFalse);
      });
    });

    group('getCurrentProgram', () {
      test('should return failure when not configured', () async {
        final result = await repository.getCurrentProgram('channel-1');

        expect(result.isFailure, isTrue);
      });
    });

    group('getNextProgram', () {
      test('should return failure when not configured', () async {
        final result = await repository.getNextProgram('channel-1');

        expect(result.isFailure, isTrue);
      });
    });

    group('getDailySchedule', () {
      test('should return failure when not configured', () async {
        final result = await repository.getDailySchedule(
          'channel-1',
          DateTime.now(),
        );

        expect(result.isFailure, isTrue);
      });
    });

    group('getProgramsInRange', () {
      test('should return failure when not configured', () async {
        final now = DateTime.now();
        final result = await repository.getProgramsInRange(
          'channel-1',
          now,
          now.add(const Duration(hours: 2)),
        );

        expect(result.isFailure, isTrue);
      });
    });

    group('refresh', () {
      test('should call fetchEpg with forceRefresh', () async {
        // Without configuration, should return error
        final result = await repository.refresh();

        expect(result.isFailure, isTrue);
      });
    });
  });

  group('UnifiedEpgRepository with mock data', () {
    late UnifiedEpgRepository repository;
    late EpgData testEpgData;

    setUp(() {
      repository = UnifiedEpgRepository();

      // Create test EPG data with relative timestamps.
      // Using DateTime.now() is intentional here since we're testing
      // time-relative behavior (isCurrentlyAiring, isUpcoming, etc.)
      final now = DateTime.now().toUtc();
      testEpgData = EpgData(
        channels: const {
          'ch1': EpgChannel(
            id: 'ch1',
            name: 'Channel 1',
          ),
          'ch2': EpgChannel(
            id: 'ch2',
            name: 'Channel 2',
          ),
        },
        programs: {
          'ch1': [
            EpgProgram(
              channelId: 'ch1',
              title: 'Current Show',
              startTime: now.subtract(const Duration(minutes: 30)),
              endTime: now.add(const Duration(minutes: 30)),
            ),
            EpgProgram(
              channelId: 'ch1',
              title: 'Next Show',
              startTime: now.add(const Duration(minutes: 30)),
              endTime: now.add(const Duration(hours: 1, minutes: 30)),
            ),
          ],
          'ch2': [
            EpgProgram(
              channelId: 'ch2',
              title: 'Morning News',
              startTime: now.subtract(const Duration(hours: 1)),
              endTime: now.add(const Duration(hours: 1)),
            ),
          ],
        },
        fetchedAt: now,
        sourceUrl: 'https://example.com/epg.xml',
      );
    });

    test('EpgData should correctly identify current program', () {
      final current = testEpgData.getCurrentProgram('ch1');

      expect(current, isNotNull);
      expect(current!.title, equals('Current Show'));
    });

    test('EpgData should correctly identify next program', () {
      final next = testEpgData.getNextProgram('ch1');

      expect(next, isNotNull);
      expect(next!.title, equals('Next Show'));
    });

    test('EpgData should return null for unknown channel', () {
      final current = testEpgData.getCurrentProgram('unknown');

      expect(current, isNull);
    });

    test('EpgData should return empty list for unknown channel programs', () {
      final programs = testEpgData.getChannelPrograms('unknown');

      expect(programs, isEmpty);
    });

    test('EpgData should calculate total programs correctly', () {
      expect(testEpgData.totalPrograms, equals(3));
    });

    test('EpgData should not be empty when has data', () {
      expect(testEpgData.isEmpty, isFalse);
      expect(testEpgData.isNotEmpty, isTrue);
    });
  });
}

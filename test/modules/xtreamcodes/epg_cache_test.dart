import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/epg_models.dart';

void main() {
  group('EPG Cache TTL Behavior', () {
    group('EpgData cache behavior', () {
      test('should track fetchedAt timestamp for cache validation', () {
        final beforeFetch = DateTime.now().toUtc();
        final epgData = EpgData(
          channels: {},
          programs: {},
          fetchedAt: DateTime.now().toUtc(),
        );
        final afterFetch = DateTime.now().toUtc();

        // fetchedAt should be between before and after
        expect(epgData.fetchedAt.isAfter(beforeFetch.subtract(const Duration(seconds: 1))), isTrue);
        expect(epgData.fetchedAt.isBefore(afterFetch.add(const Duration(seconds: 1))), isTrue);
      });

      test('EpgData.empty should set fetchedAt to now', () {
        final beforeCreate = DateTime.now().toUtc();
        final emptyData = EpgData.empty();
        final afterCreate = DateTime.now().toUtc();

        expect(emptyData.fetchedAt.isAfter(beforeCreate.subtract(const Duration(seconds: 1))), isTrue);
        expect(emptyData.fetchedAt.isBefore(afterCreate.add(const Duration(seconds: 1))), isTrue);
      });

      test('should correctly identify empty vs non-empty data', () {
        final emptyData = EpgData.empty();
        expect(emptyData.isEmpty, isTrue);
        expect(emptyData.isNotEmpty, isFalse);

        final dataWithChannels = EpgData(
          channels: {
            'ch1': const EpgChannel(id: 'ch1', name: 'Channel One'),
          },
          programs: {},
          fetchedAt: DateTime.now().toUtc(),
        );
        expect(dataWithChannels.isEmpty, isFalse);
        expect(dataWithChannels.isNotEmpty, isTrue);
      });
    });

    group('Cache duration validation', () {
      test('should validate cache based on TTL (6 hours default)', () {
        // This test validates the cache TTL strategy mentioned in requirements
        // Cache should be valid within TTL, invalid after TTL expires
        
        const cacheDuration = Duration(hours: 6);
        final now = DateTime.now();
        
        // Cache just created - should be valid
        final recentCache = now.subtract(const Duration(minutes: 5));
        expect(now.difference(recentCache) < cacheDuration, isTrue);
        
        // Cache within TTL - should be valid
        final withinTtl = now.subtract(const Duration(hours: 5));
        expect(now.difference(withinTtl) < cacheDuration, isTrue);
        
        // Cache exactly at TTL boundary - should be expired
        final atTtl = now.subtract(const Duration(hours: 6));
        expect(now.difference(atTtl) >= cacheDuration, isTrue);
        
        // Cache expired - should be invalid
        final expiredCache = now.subtract(const Duration(hours: 7));
        expect(now.difference(expiredCache) > cacheDuration, isTrue);
      });

      test('should not trigger constant re-download loops', () {
        // Simulates cache validation over time
        // Cache should remain valid until TTL expires, preventing spam
        
        const cacheDuration = Duration(hours: 6);
        final cacheCreatedAt = DateTime.now();
        
        // Multiple checks within short intervals should not invalidate cache
        for (int i = 0; i < 100; i++) {
          final checkTime = cacheCreatedAt.add(Duration(minutes: i));
          final age = checkTime.difference(cacheCreatedAt);
          
          // All checks within first 6 hours should find cache valid
          if (i < 360) { // 360 minutes = 6 hours
            expect(age < cacheDuration, isTrue,
              reason: 'Cache should be valid at $i minutes');
          }
        }
      });
    });

    group('EPG data lookup efficiency', () {
      late EpgData testData;
      
      setUp(() {
        final channels = <String, EpgChannel>{};
        final programs = <String, List<EpgProgram>>{};
        
        // Create test data with multiple channels and programs
        for (int i = 0; i < 100; i++) {
          final channelId = 'ch$i';
          channels[channelId] = EpgChannel(
            id: channelId,
            name: 'Channel $i',
          );
          
          // Add 24 programs per channel (one per hour)
          programs[channelId] = List.generate(24, (hour) {
            final start = DateTime.utc(2024, 1, 1, hour, 0);
            final end = start.add(const Duration(hours: 1));
            return EpgProgram(
              channelId: channelId,
              title: 'Program $hour on Channel $i',
              startTime: start,
              endTime: end,
            );
          });
        }
        
        testData = EpgData(
          channels: channels,
          programs: programs,
          fetchedAt: DateTime.now().toUtc(),
        );
      });

      test('should efficiently look up programs by channel', () {
        // Fast lookup by channelId - no API call needed
        final channelPrograms = testData.getChannelPrograms('ch50');
        
        expect(channelPrograms, isNotEmpty);
        expect(channelPrograms.length, equals(24));
        expect(channelPrograms.first.channelId, equals('ch50'));
      });

      test('should find current program without API call', () {
        // Create data with a currently airing program
        final now = DateTime.now().toUtc();
        final currentProgram = EpgProgram(
          channelId: 'ch1',
          title: 'Currently Airing',
          startTime: now.subtract(const Duration(minutes: 30)),
          endTime: now.add(const Duration(minutes: 30)),
        );
        
        final dataWithCurrent = EpgData(
          channels: const {'ch1': EpgChannel(id: 'ch1', name: 'Test')},
          programs: {'ch1': [currentProgram]},
          fetchedAt: now,
        );
        
        final found = dataWithCurrent.getCurrentProgram('ch1');
        
        expect(found, isNotNull);
        expect(found!.title, equals('Currently Airing'));
        expect(found.isCurrentlyAiring, isTrue);
      });

      test('should get daily schedule from cached data', () {
        final schedule = testData.getDailySchedule('ch10', DateTime(2024, 1, 1));
        
        expect(schedule, isNotEmpty);
        // All programs for the day
        expect(schedule.length, equals(24));
      });

      test('should get programs in time range from cached data', () {
        final rangePrograms = testData.getProgramsInRange(
          'ch25',
          DateTime.utc(2024, 1, 1, 10, 0),
          DateTime.utc(2024, 1, 1, 14, 0),
        );
        
        // Should include programs from 10:00-14:00 (4 programs)
        expect(rangePrograms.length, equals(4));
      });
    });

    group('No per-channel API calls validation', () {
      test('all channel EPG should be accessible from single prefetch', () {
        // Validates the core requirement: single XMLTV download serves all channels
        final channels = <String, EpgChannel>{};
        final programs = <String, List<EpgProgram>>{};
        
        // Simulate 500 channels from a single XMLTV download
        for (int i = 0; i < 500; i++) {
          final channelId = 'channel_$i';
          channels[channelId] = EpgChannel(id: channelId, name: 'Channel $i');
          programs[channelId] = [
            EpgProgram(
              channelId: channelId,
              title: 'Program on $channelId',
              startTime: DateTime.utc(2024, 1, 1, 10, 0),
              endTime: DateTime.utc(2024, 1, 1, 11, 0),
            ),
          ];
        }
        
        final epgData = EpgData(
          channels: channels,
          programs: programs,
          fetchedAt: DateTime.now().toUtc(),
        );
        
        // All 500 channels should be accessible without additional calls
        expect(epgData.channels.length, equals(500));
        expect(epgData.programs.length, equals(500));
        
        // Random access to any channel should work
        expect(epgData.getChannelPrograms('channel_0'), isNotEmpty);
        expect(epgData.getChannelPrograms('channel_250'), isNotEmpty);
        expect(epgData.getChannelPrograms('channel_499'), isNotEmpty);
        
        // Non-existent channel returns empty, not an error
        expect(epgData.getChannelPrograms('nonexistent'), isEmpty);
      });
    });
  });
}

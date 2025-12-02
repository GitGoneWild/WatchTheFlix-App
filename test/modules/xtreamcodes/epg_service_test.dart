import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/epg_models.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/epg_service.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';

void main() {
  group('EpgEntry', () {
    group('fromJson', () {
      test('should parse EPG entry with timestamp fields', () {
        final now = DateTime.now();
        final startTimestamp = now.millisecondsSinceEpoch ~/ 1000;
        final endTimestamp = now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

        final json = {
          'epg_id': '12345',
          'title': 'News at 10',
          'description': 'Daily news update',
          'start': startTimestamp,
          'end': endTimestamp,
          'lang': 'en',
        };

        final entry = EpgEntry.fromJson(json);

        expect(entry.channelId, equals('12345'));
        expect(entry.title, equals('News at 10'));
        expect(entry.description, equals('Daily news update'));
        expect(entry.language, equals('en'));
        expect(entry.startTime, isNotNull);
        expect(entry.endTime, isNotNull);
      });

      test('should parse EPG entry with string timestamps', () {
        final now = DateTime.now();
        final startTimestamp = (now.millisecondsSinceEpoch ~/ 1000).toString();
        final endTimestamp = (now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000).toString();

        final json = {
          'channel_id': '999',
          'title': 'Movie',
          'start_timestamp': startTimestamp,
          'stop_timestamp': endTimestamp,
        };

        final entry = EpgEntry.fromJson(json);

        expect(entry.channelId, equals('999'));
        expect(entry.startTime, isNotNull);
        expect(entry.endTime, isNotNull);
      });

      test('should use desc as fallback for description', () {
        final json = {
          'epg_id': '1',
          'title': 'Show',
          'desc': 'Description from desc field',
          'start': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'end': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        };

        final entry = EpgEntry.fromJson(json);

        expect(entry.description, equals('Description from desc field'));
      });

      test('should handle missing optional fields', () {
        final json = {
          'epg_id': '1',
          'title': 'Show',
        };

        final entry = EpgEntry.fromJson(json);

        expect(entry.channelId, equals('1'));
        expect(entry.title, equals('Show'));
        expect(entry.description, isNull);
        expect(entry.language, isNull);
        // Default times should be set
        expect(entry.startTime, isNotNull);
        expect(entry.endTime, isNotNull);
      });
    });

    group('fromEpgProgram', () {
      test('should create EpgEntry from EpgProgram', () {
        final program = EpgProgram(
          channelId: 'ch1',
          title: 'Test Program',
          description: 'Test description',
          startTime: DateTime.utc(2024, 1, 1, 10, 0),
          endTime: DateTime.utc(2024, 1, 1, 11, 0),
          language: 'en',
        );

        final entry = EpgEntry.fromEpgProgram(program);

        expect(entry.channelId, equals('ch1'));
        expect(entry.title, equals('Test Program'));
        expect(entry.description, equals('Test description'));
        expect(entry.startTime, equals(program.startTime));
        expect(entry.endTime, equals(program.endTime));
        expect(entry.language, equals('en'));
      });

      test('should handle EpgProgram with null optional fields', () {
        final program = EpgProgram(
          channelId: 'ch1',
          title: 'Test Program',
          startTime: DateTime.utc(2024, 1, 1, 10, 0),
          endTime: DateTime.utc(2024, 1, 1, 11, 0),
        );

        final entry = EpgEntry.fromEpgProgram(program);

        expect(entry.channelId, equals('ch1'));
        expect(entry.title, equals('Test Program'));
        expect(entry.description, isNull);
        expect(entry.language, isNull);
      });
    });

    group('isCurrentlyAiring', () {
      test('should return true when current time is between start and end', () {
        final now = DateTime.now();
        final entry = EpgEntry(
          channelId: '1',
          title: 'Current Show',
          startTime: now.subtract(const Duration(minutes: 30)),
          endTime: now.add(const Duration(minutes: 30)),
        );

        expect(entry.isCurrentlyAiring, isTrue);
      });

      test('should return false when show has not started', () {
        final now = DateTime.now();
        final entry = EpgEntry(
          channelId: '1',
          title: 'Future Show',
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 2)),
        );

        expect(entry.isCurrentlyAiring, isFalse);
      });

      test('should return false when show has ended', () {
        final now = DateTime.now();
        final entry = EpgEntry(
          channelId: '1',
          title: 'Past Show',
          startTime: now.subtract(const Duration(hours: 2)),
          endTime: now.subtract(const Duration(hours: 1)),
        );

        expect(entry.isCurrentlyAiring, isFalse);
      });
    });

    group('progress', () {
      test('should return 0 when show is not currently airing', () {
        final now = DateTime.now();
        final entry = EpgEntry(
          channelId: '1',
          title: 'Future Show',
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 2)),
        );

        expect(entry.progress, equals(0.0));
      });

      test('should return progress between 0 and 1 when airing', () {
        final now = DateTime.now();
        final entry = EpgEntry(
          channelId: '1',
          title: 'Current Show',
          startTime: now.subtract(const Duration(minutes: 30)),
          endTime: now.add(const Duration(minutes: 30)),
        );

        expect(entry.progress, greaterThan(0.0));
        expect(entry.progress, lessThanOrEqualTo(1.0));
        // Should be approximately 0.5 (halfway through)
        expect(entry.progress, closeTo(0.5, 0.1));
      });
    });

    group('duration', () {
      test('should calculate correct duration', () {
        final entry = EpgEntry(
          channelId: '1',
          title: 'One Hour Show',
          startTime: DateTime(2024, 1, 1, 10, 0),
          endTime: DateTime(2024, 1, 1, 11, 0),
        );

        expect(entry.duration, equals(const Duration(hours: 1)));
      });

      test('should handle 30 minute shows', () {
        final entry = EpgEntry(
          channelId: '1',
          title: 'Half Hour Show',
          startTime: DateTime(2024, 1, 1, 10, 0),
          endTime: DateTime(2024, 1, 1, 10, 30),
        );

        expect(entry.duration, equals(const Duration(minutes: 30)));
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final startTime = DateTime(2024, 1, 1, 10, 0);
        final endTime = DateTime(2024, 1, 1, 11, 0);
        final entry = EpgEntry(
          channelId: '12345',
          title: 'Test Show',
          description: 'Test description',
          startTime: startTime,
          endTime: endTime,
          language: 'en',
        );

        final json = entry.toJson();

        expect(json['channel_id'], equals('12345'));
        expect(json['title'], equals('Test Show'));
        expect(json['description'], equals('Test description'));
        expect(json['start'], equals(startTime.millisecondsSinceEpoch ~/ 1000));
        expect(json['end'], equals(endTime.millisecondsSinceEpoch ~/ 1000));
        expect(json['lang'], equals('en'));
      });
    });

    group('toEpgInfo', () {
      test('should convert to EpgInfo domain model', () {
        final startTime = DateTime(2024, 1, 1, 10, 0);
        final endTime = DateTime(2024, 1, 1, 11, 0);
        final entry = EpgEntry(
          channelId: '1',
          title: 'Test Show',
          description: 'Test description',
          startTime: startTime,
          endTime: endTime,
        );

        final epgInfo = entry.toEpgInfo();

        expect(epgInfo.currentProgram, equals('Test Show'));
        expect(epgInfo.description, equals('Test description'));
        expect(epgInfo.startTime, equals(startTime));
        expect(epgInfo.endTime, equals(endTime));
      });
    });
  });
}

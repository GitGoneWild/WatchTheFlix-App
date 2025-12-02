import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/epg_models.dart';

void main() {
  group('EpgChannel', () {
    test('should create channel with required fields', () {
      const channel = EpgChannel(
        id: 'ch1',
        name: 'Channel One',
      );

      expect(channel.id, equals('ch1'));
      expect(channel.name, equals('Channel One'));
      expect(channel.iconUrl, isNull);
      expect(channel.displayNames, isEmpty);
    });

    test('should create channel with all fields', () {
      const channel = EpgChannel(
        id: 'ch1',
        name: 'Channel One',
        iconUrl: 'https://example.com/logo.png',
        displayNames: ['Channel One', 'Channel 1', 'CH1'],
      );

      expect(channel.id, equals('ch1'));
      expect(channel.name, equals('Channel One'));
      expect(channel.iconUrl, equals('https://example.com/logo.png'));
      expect(channel.displayNames.length, equals(3));
    });

    test('fromXmlData should use first display name as name', () {
      final channel = EpgChannel.fromXmlData(
        id: 'ch1',
        displayNames: const ['First Name', 'Second Name'],
        iconUrl: 'https://example.com/logo.png',
      );

      expect(channel.name, equals('First Name'));
      expect(channel.displayNames.length, equals(2));
    });

    test('fromXmlData should use id when no display names', () {
      final channel = EpgChannel.fromXmlData(
        id: 'ch1',
        displayNames: const [],
      );

      expect(channel.name, equals('ch1'));
    });
  });

  group('EpgProgram', () {
    test('should create program with required fields', () {
      final start = DateTime.utc(2024, 1, 1, 10);
      final end = DateTime.utc(2024, 1, 1, 11);

      final program = EpgProgram(
        channelId: 'ch1',
        title: 'News at 10',
        startTime: start,
        endTime: end,
      );

      expect(program.channelId, equals('ch1'));
      expect(program.title, equals('News at 10'));
      expect(program.startTime, equals(start));
      expect(program.endTime, equals(end));
      expect(program.description, isNull);
    });

    test('should calculate duration correctly', () {
      final program = EpgProgram(
        channelId: 'ch1',
        title: 'One Hour Show',
        startTime: DateTime.utc(2024, 1, 1, 10),
        endTime: DateTime.utc(2024, 1, 1, 11),
      );

      expect(program.duration, equals(const Duration(hours: 1)));
    });

    test('should calculate duration for 30 minute show', () {
      final program = EpgProgram(
        channelId: 'ch1',
        title: 'Half Hour Show',
        startTime: DateTime.utc(2024, 1, 1, 10),
        endTime: DateTime.utc(2024, 1, 1, 10, 30),
      );

      expect(program.duration, equals(const Duration(minutes: 30)));
    });

    test('isUpcoming should return true for future programs', () {
      final futureStart = DateTime.now().toUtc().add(const Duration(hours: 1));
      final futureEnd = futureStart.add(const Duration(hours: 1));

      final program = EpgProgram(
        channelId: 'ch1',
        title: 'Future Show',
        startTime: futureStart,
        endTime: futureEnd,
      );

      expect(program.isUpcoming, isTrue);
      expect(program.isCurrentlyAiring, isFalse);
      expect(program.hasEnded, isFalse);
    });

    test('hasEnded should return true for past programs', () {
      final pastStart =
          DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final pastEnd = pastStart.add(const Duration(hours: 1));

      final program = EpgProgram(
        channelId: 'ch1',
        title: 'Past Show',
        startTime: pastStart,
        endTime: pastEnd,
      );

      expect(program.hasEnded, isTrue);
      expect(program.isCurrentlyAiring, isFalse);
      expect(program.isUpcoming, isFalse);
    });

    test(
        'isCurrentlyAiring should return true when now is between start and end',
        () {
      final now = DateTime.now().toUtc();
      final start = now.subtract(const Duration(minutes: 30));
      final end = now.add(const Duration(minutes: 30));

      final program = EpgProgram(
        channelId: 'ch1',
        title: 'Current Show',
        startTime: start,
        endTime: end,
      );

      expect(program.isCurrentlyAiring, isTrue);
      expect(program.isUpcoming, isFalse);
      expect(program.hasEnded, isFalse);
    });

    test('progress should be 0 for upcoming programs', () {
      final futureStart = DateTime.now().toUtc().add(const Duration(hours: 1));
      final futureEnd = futureStart.add(const Duration(hours: 1));

      final program = EpgProgram(
        channelId: 'ch1',
        title: 'Future Show',
        startTime: futureStart,
        endTime: futureEnd,
      );

      expect(program.progress, equals(0.0));
    });

    test('progress should be 1 for ended programs', () {
      final pastStart =
          DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final pastEnd = pastStart.add(const Duration(hours: 1));

      final program = EpgProgram(
        channelId: 'ch1',
        title: 'Past Show',
        startTime: pastStart,
        endTime: pastEnd,
      );

      expect(program.progress, equals(1.0));
    });

    test('progress should be between 0 and 1 for current programs', () {
      final now = DateTime.now().toUtc();
      final start = now.subtract(const Duration(minutes: 30));
      final end = now.add(const Duration(minutes: 30));

      final program = EpgProgram(
        channelId: 'ch1',
        title: 'Current Show',
        startTime: start,
        endTime: end,
      );

      expect(program.progress, greaterThan(0.0));
      expect(program.progress, lessThanOrEqualTo(1.0));
      expect(program.progress, closeTo(0.5, 0.1));
    });

    test('remainingTime should be zero for ended programs', () {
      final pastStart =
          DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final pastEnd = pastStart.add(const Duration(hours: 1));

      final program = EpgProgram(
        channelId: 'ch1',
        title: 'Past Show',
        startTime: pastStart,
        endTime: pastEnd,
      );

      expect(program.remainingTime, equals(Duration.zero));
    });

    test('timeUntilStart should be zero for current and past programs', () {
      final now = DateTime.now().toUtc();
      final start = now.subtract(const Duration(minutes: 30));
      final end = now.add(const Duration(minutes: 30));

      final program = EpgProgram(
        channelId: 'ch1',
        title: 'Current Show',
        startTime: start,
        endTime: end,
      );

      expect(program.timeUntilStart, equals(Duration.zero));
    });
  });

  group('EpgData', () {
    late EpgData epgData;

    setUp(() {
      final now = DateTime.now().toUtc();

      final channels = {
        'ch1': const EpgChannel(id: 'ch1', name: 'Channel 1'),
        'ch2': const EpgChannel(id: 'ch2', name: 'Channel 2'),
      };

      final programs = {
        'ch1': [
          EpgProgram(
            channelId: 'ch1',
            title: 'Past Show',
            startTime: now.subtract(const Duration(hours: 2)),
            endTime: now.subtract(const Duration(hours: 1)),
          ),
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
        'ch2': <EpgProgram>[],
      };

      epgData = EpgData(
        channels: channels,
        programs: programs,
        fetchedAt: now,
      );
    });

    test('isEmpty should return false when data exists', () {
      expect(epgData.isEmpty, isFalse);
      expect(epgData.isNotEmpty, isTrue);
    });

    test('totalPrograms should count all programs', () {
      expect(epgData.totalPrograms, equals(3));
    });

    test('getChannelPrograms should return programs for channel', () {
      final programs = epgData.getChannelPrograms('ch1');
      expect(programs.length, equals(3));
    });

    test('getChannelPrograms should return empty list for unknown channel', () {
      final programs = epgData.getChannelPrograms('unknown');
      expect(programs, isEmpty);
    });

    test('getCurrentProgram should return currently airing program', () {
      final current = epgData.getCurrentProgram('ch1');
      expect(current, isNotNull);
      expect(current!.title, equals('Current Show'));
    });

    test('getCurrentProgram should return null for empty channel', () {
      final current = epgData.getCurrentProgram('ch2');
      expect(current, isNull);
    });

    test('getNextProgram should return next upcoming program', () {
      final next = epgData.getNextProgram('ch1');
      expect(next, isNotNull);
      expect(next!.title, equals('Next Show'));
    });

    test('empty factory should create empty EpgData', () {
      final empty = EpgData.empty();
      expect(empty.isEmpty, isTrue);
      expect(empty.channels, isEmpty);
      expect(empty.programs, isEmpty);
    });

    test('getProgramsInRange should filter by time', () {
      final now = DateTime.now().toUtc();
      final rangeStart = now.subtract(const Duration(hours: 3));
      final rangeEnd = now.add(const Duration(hours: 3));

      final programs = epgData.getProgramsInRange('ch1', rangeStart, rangeEnd);
      expect(programs.length, equals(3));
    });
  });
}

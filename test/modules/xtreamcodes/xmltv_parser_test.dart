import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/xmltv_parser.dart';

void main() {
  late XmltvParser parser;

  setUp(() {
    parser = XmltvParser();
  });

  group('XmltvParser.isValidXmltv', () {
    test('should return true for valid XMLTV content', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv generator-info-name="test">
</tv>
''';
      expect(parser.isValidXmltv(xmlContent), isTrue);
    });

    test('should return false for non-XMLTV content', () {
      const xmlContent = '<html><body>Not XMLTV</body></html>';
      expect(parser.isValidXmltv(xmlContent), isFalse);
    });

    test('should return false for empty content', () {
      expect(parser.isValidXmltv(''), isFalse);
    });
  });

  group('XmltvParser.parse', () {
    test('should parse empty TV element', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv generator-info-name="test">
</tv>
''';
      final result = parser.parse(xmlContent);

      expect(result.isEmpty, isTrue);
      expect(result.channels, isEmpty);
      expect(result.programs, isEmpty);
    });

    test('should parse channels', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="channel1">
    <display-name>Channel One</display-name>
    <display-name>CH1</display-name>
    <icon src="https://example.com/logo.png" />
  </channel>
  <channel id="channel2">
    <display-name>Channel Two</display-name>
  </channel>
</tv>
''';
      final result = parser.parse(xmlContent);

      expect(result.channels.length, equals(2));
      expect(result.channels['channel1'], isNotNull);
      expect(result.channels['channel1']!.name, equals('Channel One'));
      expect(result.channels['channel1']!.iconUrl, equals('https://example.com/logo.png'));
      expect(result.channels['channel1']!.displayNames.length, equals(2));
      expect(result.channels['channel2']!.name, equals('Channel Two'));
      expect(result.channels['channel2']!.iconUrl, isNull);
    });

    test('should skip channels without id', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel>
    <display-name>No ID Channel</display-name>
  </channel>
  <channel id="valid">
    <display-name>Valid Channel</display-name>
  </channel>
</tv>
''';
      final result = parser.parse(xmlContent);

      expect(result.channels.length, equals(1));
      expect(result.channels['valid'], isNotNull);
    });

    test('should parse programs', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="channel1">
    <display-name>Channel One</display-name>
  </channel>
  <programme start="20240101100000 +0000" stop="20240101110000 +0000" channel="channel1">
    <title lang="en">Morning News</title>
    <desc>Daily morning news update</desc>
    <category>News</category>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      expect(result.programs.length, equals(1));
      expect(result.programs['channel1'], isNotNull);
      expect(result.programs['channel1']!.length, equals(1));

      final program = result.programs['channel1']!.first;
      expect(program.title, equals('Morning News'));
      expect(program.description, equals('Daily morning news update'));
      expect(program.category, equals('News'));
      expect(program.language, equals('en'));
      expect(program.channelId, equals('channel1'));
    });

    test('should parse program times correctly', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240115120000 +0000" stop="20240115130000 +0000" channel="channel1">
    <title>Test Show</title>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      final program = result.programs['channel1']!.first;
      expect(program.startTime, equals(DateTime.utc(2024, 1, 15, 12, 0, 0)));
      expect(program.endTime, equals(DateTime.utc(2024, 1, 15, 13, 0, 0)));
    });

    test('should handle timezone offset in program times', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240115120000 -0500" stop="20240115130000 -0500" channel="channel1">
    <title>Test Show</title>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      final program = result.programs['channel1']!.first;
      // 12:00 -0500 = 17:00 UTC
      expect(program.startTime, equals(DateTime.utc(2024, 1, 15, 17, 0, 0)));
      expect(program.endTime, equals(DateTime.utc(2024, 1, 15, 18, 0, 0)));
    });

    test('should handle positive timezone offset', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240115120000 +0530" stop="20240115130000 +0530" channel="channel1">
    <title>Test Show</title>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      final program = result.programs['channel1']!.first;
      // 12:00 +0530 = 06:30 UTC
      expect(program.startTime, equals(DateTime.utc(2024, 1, 15, 6, 30, 0)));
      expect(program.endTime, equals(DateTime.utc(2024, 1, 15, 7, 30, 0)));
    });

    test('should parse optional program fields', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240101100000 +0000" stop="20240101110000 +0000" channel="channel1">
    <title>Show Title</title>
    <sub-title>Episode Subtitle</sub-title>
    <desc>Program description</desc>
    <category>Drama</category>
    <icon src="https://example.com/poster.jpg" />
    <episode-num system="onscreen">S01E05</episode-num>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      final program = result.programs['channel1']!.first;
      expect(program.title, equals('Show Title'));
      expect(program.subtitle, equals('Episode Subtitle'));
      expect(program.description, equals('Program description'));
      expect(program.category, equals('Drama'));
      expect(program.iconUrl, equals('https://example.com/poster.jpg'));
      expect(program.episodeNumber, equals('S01E05'));
    });

    test('should skip programs without title', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240101100000 +0000" stop="20240101110000 +0000" channel="channel1">
    <desc>No title program</desc>
  </programme>
  <programme start="20240101110000 +0000" stop="20240101120000 +0000" channel="channel1">
    <title>Valid Program</title>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      expect(result.programs['channel1']!.length, equals(1));
      expect(result.programs['channel1']!.first.title, equals('Valid Program'));
    });

    test('should skip programs without required attributes', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme stop="20240101110000 +0000" channel="channel1">
    <title>Missing Start</title>
  </programme>
  <programme start="20240101100000 +0000" channel="channel1">
    <title>Missing Stop</title>
  </programme>
  <programme start="20240101100000 +0000" stop="20240101110000 +0000">
    <title>Missing Channel</title>
  </programme>
  <programme start="20240101110000 +0000" stop="20240101120000 +0000" channel="channel1">
    <title>Valid Program</title>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      expect(result.programs['channel1']!.length, equals(1));
      expect(result.programs['channel1']!.first.title, equals('Valid Program'));
    });

    test('should sort programs by start time', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240101120000 +0000" stop="20240101130000 +0000" channel="channel1">
    <title>Third Show</title>
  </programme>
  <programme start="20240101100000 +0000" stop="20240101110000 +0000" channel="channel1">
    <title>First Show</title>
  </programme>
  <programme start="20240101110000 +0000" stop="20240101120000 +0000" channel="channel1">
    <title>Second Show</title>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      final programs = result.programs['channel1']!;
      expect(programs.length, equals(3));
      expect(programs[0].title, equals('First Show'));
      expect(programs[1].title, equals('Second Show'));
      expect(programs[2].title, equals('Third Show'));
    });

    test('should parse multiple channels with programs', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="ch1">
    <display-name>Channel 1</display-name>
  </channel>
  <channel id="ch2">
    <display-name>Channel 2</display-name>
  </channel>
  <programme start="20240101100000 +0000" stop="20240101110000 +0000" channel="ch1">
    <title>Ch1 Program</title>
  </programme>
  <programme start="20240101100000 +0000" stop="20240101110000 +0000" channel="ch2">
    <title>Ch2 Program</title>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      expect(result.channels.length, equals(2));
      expect(result.programs.length, equals(2));
      expect(result.programs['ch1']!.first.title, equals('Ch1 Program'));
      expect(result.programs['ch2']!.first.title, equals('Ch2 Program'));
    });

    test('should return empty on invalid XML', () {
      const xmlContent = 'this is not valid xml at all';
      final result = parser.parse(xmlContent);

      expect(result.isEmpty, isTrue);
    });

    test('should return empty when no tv element', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<html><body>Not TV</body></html>
''';
      final result = parser.parse(xmlContent);

      expect(result.isEmpty, isTrue);
    });

    test('should set fetchedAt and sourceUrl', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv></tv>
''';
      final beforeParse = DateTime.now().toUtc();
      final result = parser.parse(xmlContent, sourceUrl: 'https://example.com/epg.xml');
      final afterParse = DateTime.now().toUtc();

      expect(result.fetchedAt.isAfter(beforeParse.subtract(const Duration(seconds: 1))), isTrue);
      expect(result.fetchedAt.isBefore(afterParse.add(const Duration(seconds: 1))), isTrue);
      expect(result.sourceUrl, equals('https://example.com/epg.xml'));
    });

    test('should handle datetime without timezone', () {
      const xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <programme start="20240115120000" stop="20240115130000" channel="channel1">
    <title>Test Show</title>
  </programme>
</tv>
''';
      final result = parser.parse(xmlContent);

      final program = result.programs['channel1']!.first;
      // Without timezone, should be treated as local time converted to UTC
      expect(program.startTime.year, equals(2024));
      expect(program.startTime.month, equals(1));
      expect(program.startTime.day, equals(15));
    });
  });
}

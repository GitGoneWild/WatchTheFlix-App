import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/m3u/parsing/m3u_parser.dart';

void main() {
  late M3uParser parser;

  setUp(() {
    parser = M3uParser();
  });

  group('M3uParser', () {
    test('should validate correct M3U content with header', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="channel1" tvg-logo="http://example.com/logo.png" group-title="Sports",Channel 1
http://stream.example.com/channel1.m3u8
''';

      expect(parser.isValid(content), isTrue);
    });

    test('should validate M3U content without header but with EXTINF', () {
      const content = '''
#EXTINF:-1,Channel 1
http://stream.example.com/channel1.m3u8
''';

      expect(parser.isValid(content), isTrue);
    });

    test('should invalidate non-M3U content', () {
      const content = 'This is not M3U content';

      expect(parser.isValid(content), isFalse);
    });

    test('should parse channels from M3U content', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="espn" tvg-logo="http://example.com/espn.png" group-title="Sports",ESPN
http://stream.example.com/espn.m3u8
#EXTINF:-1 tvg-id="cnn" tvg-logo="http://example.com/cnn.png" group-title="News",CNN
http://stream.example.com/cnn.m3u8
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(2));
      
      expect(entries[0].name, equals('ESPN'));
      expect(entries[0].tvgId, equals('espn'));
      expect(entries[0].tvgLogo, equals('http://example.com/espn.png'));
      expect(entries[0].groupTitle, equals('Sports'));
      expect(entries[0].url, equals('http://stream.example.com/espn.m3u8'));
      
      expect(entries[1].name, equals('CNN'));
      expect(entries[1].groupTitle, equals('News'));
    });

    test('should handle channels without optional attributes', () {
      const content = '''
#EXTM3U
#EXTINF:-1,Simple Channel
http://stream.example.com/simple.m3u8
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].name, equals('Simple Channel'));
      expect(entries[0].tvgId, isNull);
      expect(entries[0].tvgLogo, isNull);
      expect(entries[0].groupTitle, isNull);
    });

    test('should detect movie content type from group title', () {
      const content = '''
#EXTM3U
#EXTINF:-1 group-title="Movies",Action Movie
http://stream.example.com/movie.mp4
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].contentType, equals('movie'));
    });

    test('should detect series content type from group title', () {
      const content = '''
#EXTM3U
#EXTINF:-1 group-title="TV Series",Breaking Bad
http://stream.example.com/series.mp4
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].contentType, equals('series'));
    });

    test('should detect movie content type from URL', () {
      const content = '''
#EXTM3U
#EXTINF:-1,Some Content
http://stream.example.com/movie/123.mp4
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].contentType, equals('movie'));
    });

    test('should default to live content type', () {
      const content = '''
#EXTM3U
#EXTINF:-1,Live Channel
http://stream.example.com/live.m3u8
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].contentType, equals('live'));
    });

    test('should handle empty M3U content', () {
      const content = '#EXTM3U\n';

      final entries = parser.parse(content);

      expect(entries, isEmpty);
    });

    test('should parse duration from EXTINF', () {
      const content = '''
#EXTM3U
#EXTINF:120,Two Minute Video
http://stream.example.com/video.mp4
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].duration, equals(120));
    });

    test('should handle negative duration', () {
      const content = '''
#EXTM3U
#EXTINF:-1,Live Stream
http://stream.example.com/live.m3u8
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].duration, equals(-1));
    });

    test('should extract tvg-name attribute', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-name="ESPN HD",ESPN
http://stream.example.com/espn.m3u8
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].tvgName, equals('ESPN HD'));
    });

    test('should skip invalid URLs', () {
      const content = '''
#EXTM3U
#EXTINF:-1,Valid Channel
http://stream.example.com/valid.m3u8
#EXTINF:-1,Invalid Channel
not-a-valid-url
#EXTINF:-1,Another Valid
http://stream.example.com/another.m3u8
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(2));
      expect(entries[0].name, equals('Valid Channel'));
      expect(entries[1].name, equals('Another Valid'));
    });

    test('should handle EXTGRP tag for group override', () {
      const content = '''
#EXTM3U
#EXTINF:-1 group-title="Original",Channel Name
#EXTGRP:Override Group
http://stream.example.com/channel.m3u8
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].groupTitle, equals('Override Group'));
    });

    test('should handle various stream protocols', () {
      const content = '''
#EXTM3U
#EXTINF:-1,HTTP Stream
http://stream.example.com/http.m3u8
#EXTINF:-1,HTTPS Stream
https://stream.example.com/https.m3u8
#EXTINF:-1,RTMP Stream
rtmp://stream.example.com/live/stream
#EXTINF:-1,RTSP Stream
rtsp://stream.example.com/live/stream
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(4));
    });

    test('should store additional attributes in map', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="ch1" custom-attr="custom-value" another-attr="test",Channel
http://stream.example.com/channel.m3u8
''';

      final entries = parser.parse(content);

      expect(entries.length, equals(1));
      expect(entries[0].attributes['custom-attr'], equals('custom-value'));
      expect(entries[0].attributes['another-attr'], equals('test'));
    });

    test('toJson should serialize correctly', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="ch1" tvg-logo="http://logo.com/ch1.png" group-title="Sports",ESPN
http://stream.example.com/espn.m3u8
''';

      final entries = parser.parse(content);
      final json = entries[0].toJson();

      expect(json['name'], equals('ESPN'));
      expect(json['url'], equals('http://stream.example.com/espn.m3u8'));
      expect(json['tvg_id'], equals('ch1'));
      expect(json['tvg_logo'], equals('http://logo.com/ch1.png'));
      expect(json['group_title'], equals('Sports'));
      expect(json['content_type'], equals('live'));
    });
  });
}

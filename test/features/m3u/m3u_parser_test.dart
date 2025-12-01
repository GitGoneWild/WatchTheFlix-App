import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/features/m3u/m3u_parser.dart';

void main() {
  late M3UParserImpl parser;

  setUp(() {
    parser = M3UParserImpl();
  });

  group('M3UParser', () {
    test('should validate correct M3U content', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="channel1" tvg-logo="http://example.com/logo.png" group-title="Sports",Channel 1
http://stream.example.com/channel1.m3u8
''';

      expect(parser.isValid(content), isTrue);
    });

    test('should invalidate incorrect M3U content', () {
      const content = 'This is not M3U content';

      expect(parser.isValid(content), isFalse);
    });

    test('should parse channels from M3U content', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="channel1" tvg-logo="http://example.com/logo1.png" group-title="Sports",ESPN
http://stream.example.com/espn.m3u8
#EXTINF:-1 tvg-id="channel2" tvg-logo="http://example.com/logo2.png" group-title="News",CNN
http://stream.example.com/cnn.m3u8
''';

      final channels = parser.parse(content);

      expect(channels.length, equals(2));
      expect(channels[0].name, equals('ESPN'));
      expect(channels[0].groupTitle, equals('Sports'));
      expect(channels[0].logoUrl, equals('http://example.com/logo1.png'));
      expect(channels[0].streamUrl, equals('http://stream.example.com/espn.m3u8'));
      
      expect(channels[1].name, equals('CNN'));
      expect(channels[1].groupTitle, equals('News'));
    });

    test('should handle channels without optional attributes', () {
      const content = '''
#EXTM3U
#EXTINF:-1,Simple Channel
http://stream.example.com/simple.m3u8
''';

      final channels = parser.parse(content);

      expect(channels.length, equals(1));
      expect(channels[0].name, equals('Simple Channel'));
      expect(channels[0].logoUrl, isNull);
      expect(channels[0].groupTitle, isNull);
    });

    test('should detect movie content type from group title', () {
      const content = '''
#EXTM3U
#EXTINF:-1 group-title="Movies",Action Movie
http://stream.example.com/movie.mp4
''';

      final channels = parser.parse(content);

      expect(channels.length, equals(1));
      expect(channels[0].type, equals('movie'));
    });

    test('should handle empty content', () {
      const content = '#EXTM3U\n';

      final channels = parser.parse(content);

      expect(channels, isEmpty);
    });
  });
}

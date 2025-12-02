import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/domain/entities/category.dart';
import 'package:watchtheflix/domain/entities/channel.dart';
import 'package:watchtheflix/domain/entities/playlist_source.dart';

void main() {
  group('Channel', () {
    test('should create a Channel with required parameters', () {
      const channel = Channel(
        id: '1',
        name: 'Test Channel',
        streamUrl: 'http://stream.example.com/channel.m3u8',
      );

      expect(channel.id, equals('1'));
      expect(channel.name, equals('Test Channel'));
      expect(
          channel.streamUrl, equals('http://stream.example.com/channel.m3u8'));
      expect(channel.type, equals(ContentType.live));
    });

    test('should create a copy with updated values', () {
      const channel = Channel(
        id: '1',
        name: 'Test Channel',
        streamUrl: 'http://stream.example.com/channel.m3u8',
      );

      final updated = channel.copyWith(name: 'Updated Channel');

      expect(updated.name, equals('Updated Channel'));
      expect(updated.id, equals(channel.id));
    });

    test('supports value equality', () {
      const channel1 = Channel(
        id: '1',
        name: 'Test Channel',
        streamUrl: 'http://stream.example.com/channel.m3u8',
      );

      const channel2 = Channel(
        id: '1',
        name: 'Test Channel',
        streamUrl: 'http://stream.example.com/channel.m3u8',
      );

      expect(channel1, equals(channel2));
    });
  });

  group('Category', () {
    test('should create a Category with required parameters', () {
      const category = Category(
        id: '1',
        name: 'Sports',
      );

      expect(category.id, equals('1'));
      expect(category.name, equals('Sports'));
      expect(category.channelCount, equals(0));
    });

    test('should create a copy with updated values', () {
      const category = Category(
        id: '1',
        name: 'Sports',
        channelCount: 10,
      );

      final updated = category.copyWith(channelCount: 20);

      expect(updated.channelCount, equals(20));
      expect(updated.name, equals(category.name));
    });
  });

  group('PlaylistSource', () {
    test('should correctly identify Xtream source', () {
      final playlist = PlaylistSource(
        id: '1',
        name: 'Xtream Playlist',
        url: 'http://xtream.example.com',
        type: PlaylistSourceType.xtream,
        addedAt: DateTime.now(),
        xtreamCredentials: const XtreamCredentials(
          host: 'http://xtream.example.com',
          username: 'user',
          password: 'pass',
        ),
      );

      expect(playlist.isXtream, isTrue);
      expect(playlist.isM3U, isFalse);
    });

    test('should correctly identify M3U source', () {
      final playlist = PlaylistSource(
        id: '1',
        name: 'M3U Playlist',
        url: 'http://example.com/playlist.m3u',
        type: PlaylistSourceType.m3uUrl,
        addedAt: DateTime.now(),
      );

      expect(playlist.isM3U, isTrue);
      expect(playlist.isXtream, isFalse);
    });
  });

  group('XtreamCredentials', () {
    test('should generate correct base URL', () {
      const credentials = XtreamCredentials(
        host: 'http://server.com:8080/',
        username: 'user',
        password: 'pass',
      );

      expect(credentials.baseUrl, equals('http://server.com:8080'));
    });

    test('should generate correct auth params', () {
      const credentials = XtreamCredentials(
        host: 'http://server.com',
        username: 'testuser',
        password: 'testpass',
      );

      expect(credentials.authParams,
          equals('username=testuser&password=testpass'));
    });
  });
}

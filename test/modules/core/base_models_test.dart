import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';

void main() {
  group('DomainChannel', () {
    test('should create with required fields', () {
      const channel = DomainChannel(
        id: '123',
        name: 'Test Channel',
        streamUrl: 'http://stream.example.com/live.m3u8',
      );

      expect(channel.id, equals('123'));
      expect(channel.name, equals('Test Channel'));
      expect(channel.streamUrl, equals('http://stream.example.com/live.m3u8'));
      expect(channel.type, equals(ContentType.live));
    });

    test('should support copyWith', () {
      const original = DomainChannel(
        id: '123',
        name: 'Original',
        streamUrl: 'http://original.com',
        logoUrl: 'http://logo.com/original.png',
      );

      final copied = original.copyWith(
        name: 'Updated',
        logoUrl: 'http://logo.com/updated.png',
      );

      expect(copied.id, equals('123'));
      expect(copied.name, equals('Updated'));
      expect(copied.streamUrl, equals('http://original.com'));
      expect(copied.logoUrl, equals('http://logo.com/updated.png'));
    });

    test('should support equality', () {
      const channel1 = DomainChannel(
        id: '123',
        name: 'Channel',
        streamUrl: 'http://stream.com',
      );
      const channel2 = DomainChannel(
        id: '123',
        name: 'Channel',
        streamUrl: 'http://stream.com',
      );
      const channel3 = DomainChannel(
        id: '456',
        name: 'Channel',
        streamUrl: 'http://stream.com',
      );

      expect(channel1, equals(channel2));
      expect(channel1, isNot(equals(channel3)));
    });
  });

  group('DomainCategory', () {
    test('should create with required fields', () {
      const category = DomainCategory(
        id: '5',
        name: 'Sports',
      );

      expect(category.id, equals('5'));
      expect(category.name, equals('Sports'));
      expect(category.channelCount, equals(0));
    });

    test('should create with optional fields', () {
      const category = DomainCategory(
        id: '5',
        name: 'Sports',
        channelCount: 42,
        iconUrl: 'http://icon.com/sports.png',
        sortOrder: 1,
      );

      expect(category.channelCount, equals(42));
      expect(category.iconUrl, equals('http://icon.com/sports.png'));
      expect(category.sortOrder, equals(1));
    });
  });

  group('VodItem', () {
    test('should create movie item', () {
      const movie = VodItem(
        id: '999',
        name: 'Test Movie',
        streamUrl: 'http://movie.com/stream.mp4',
        posterUrl: 'http://poster.com/movie.jpg',
        rating: 8.5,
        duration: 7200,
      );

      expect(movie.id, equals('999'));
      expect(movie.name, equals('Test Movie'));
      expect(movie.type, equals(ContentType.movie));
      expect(movie.rating, equals(8.5));
      expect(movie.duration, equals(7200));
    });

    test('should support copyWith', () {
      const original = VodItem(
        id: '999',
        name: 'Original',
        streamUrl: 'http://movie.com',
        rating: 5.0,
      );

      final copied = original.copyWith(
        rating: 9.0,
        description: 'A great movie',
      );

      expect(copied.id, equals('999'));
      expect(copied.name, equals('Original'));
      expect(copied.rating, equals(9.0));
      expect(copied.description, equals('A great movie'));
    });
  });

  group('DomainSeries', () {
    test('should create with seasons', () {
      const series = DomainSeries(
        id: '111',
        name: 'Test Series',
        seasons: [
          Season(
            id: '1',
            seasonNumber: 1,
            episodes: [
              Episode(
                id: '101',
                episodeNumber: 1,
                name: 'Pilot',
                streamUrl: 'http://stream.com/s01e01.mp4',
              ),
              Episode(
                id: '102',
                episodeNumber: 2,
                name: 'Second Episode',
                streamUrl: 'http://stream.com/s01e02.mp4',
              ),
            ],
          ),
        ],
      );

      expect(series.id, equals('111'));
      expect(series.name, equals('Test Series'));
      expect(series.seasons, hasLength(1));
      expect(series.seasons[0].episodes, hasLength(2));
      expect(series.totalEpisodes, equals(2));
    });

    test('should calculate totalEpisodes correctly', () {
      const series = DomainSeries(
        id: '111',
        name: 'Multi-Season Series',
        seasons: [
          Season(
            id: '1',
            seasonNumber: 1,
            episodes: [
              Episode(id: '1', episodeNumber: 1, name: 'E1', streamUrl: 'url1'),
              Episode(id: '2', episodeNumber: 2, name: 'E2', streamUrl: 'url2'),
              Episode(id: '3', episodeNumber: 3, name: 'E3', streamUrl: 'url3'),
            ],
          ),
          Season(
            id: '2',
            seasonNumber: 2,
            episodes: [
              Episode(id: '4', episodeNumber: 1, name: 'E1', streamUrl: 'url4'),
              Episode(id: '5', episodeNumber: 2, name: 'E2', streamUrl: 'url5'),
            ],
          ),
        ],
      );

      expect(series.totalEpisodes, equals(5));
    });
  });

  group('EpgInfo', () {
    test('should create with all fields', () {
      final startTime = DateTime(2024, 1, 1, 10);
      final endTime = DateTime(2024, 1, 1, 11);

      final epgInfo = EpgInfo(
        currentProgram: 'News at 10',
        nextProgram: 'Weather',
        startTime: startTime,
        endTime: endTime,
        description: 'Daily news update',
      );

      expect(epgInfo.currentProgram, equals('News at 10'));
      expect(epgInfo.nextProgram, equals('Weather'));
      expect(epgInfo.startTime, equals(startTime));
      expect(epgInfo.endTime, equals(endTime));
    });

    test('should calculate progress correctly', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 30));
      final endTime = now.add(const Duration(minutes: 30));

      final epgInfo = EpgInfo(
        currentProgram: 'Current Show',
        startTime: startTime,
        endTime: endTime,
      );

      // Should be approximately 50% progress
      expect(epgInfo.progress, closeTo(0.5, 0.1));
    });

    test('should return 0 progress for future show', () {
      final now = DateTime.now();
      final startTime = now.add(const Duration(hours: 1));
      final endTime = now.add(const Duration(hours: 2));

      final epgInfo = EpgInfo(
        currentProgram: 'Future Show',
        startTime: startTime,
        endTime: endTime,
      );

      expect(epgInfo.progress, equals(0.0));
    });

    test('should return 1 progress for past show', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 2));
      final endTime = now.subtract(const Duration(hours: 1));

      final epgInfo = EpgInfo(
        currentProgram: 'Past Show',
        startTime: startTime,
        endTime: endTime,
      );

      expect(epgInfo.progress, equals(1.0));
    });

    test('should return 0 progress when times are null', () {
      const epgInfo = EpgInfo(
        currentProgram: 'Show',
      );

      expect(epgInfo.progress, equals(0.0));
    });
  });

  group('Profile', () {
    test('should create Xtream profile', () {
      const credentials = XtreamCredentialsModel(
        host: 'http://example.com',
        username: 'user',
        password: 'pass',
      );

      final profile = Profile(
        id: '1',
        name: 'My Xtream',
        type: ProfileType.xtream,
        xtreamCredentials: credentials,
        createdAt: DateTime(2024, 1),
      );

      expect(profile.isXtream, isTrue);
      expect(profile.isM3U, isFalse);
      expect(profile.xtreamCredentials, isNotNull);
    });

    test('should create M3U URL profile', () {
      final profile = Profile(
        id: '2',
        name: 'My M3U',
        type: ProfileType.m3uUrl,
        url: 'http://example.com/playlist.m3u',
        createdAt: DateTime(2024, 1),
      );

      expect(profile.isXtream, isFalse);
      expect(profile.isM3U, isTrue);
      expect(profile.url, equals('http://example.com/playlist.m3u'));
    });

    test('should create M3U file profile', () {
      final profile = Profile(
        id: '3',
        name: 'Local M3U',
        type: ProfileType.m3uFile,
        url: '/path/to/file.m3u',
        createdAt: DateTime(2024, 1),
      );

      expect(profile.isXtream, isFalse);
      expect(profile.isM3U, isTrue);
    });
  });

  group('ContentType', () {
    test('should have all expected values', () {
      expect(ContentType.values, contains(ContentType.live));
      expect(ContentType.values, contains(ContentType.movie));
      expect(ContentType.values, contains(ContentType.series));
    });
  });

  group('ProfileType', () {
    test('should have all expected values', () {
      expect(ProfileType.values, contains(ProfileType.m3uFile));
      expect(ProfileType.values, contains(ProfileType.m3uUrl));
      expect(ProfileType.values, contains(ProfileType.xtream));
    });
  });
}

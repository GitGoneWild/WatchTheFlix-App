import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/xtreamcodes/storage/xtream_hive_models.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/epg_models.dart';

void main() {
  group('HiveChannel', () {
    test('should convert to domain model correctly', () {
      final hiveChannel = HiveChannel(
        id: 'ch1',
        name: 'Test Channel',
        streamUrl: 'http://example.com/stream/1',
        logoUrl: 'http://example.com/logo.png',
        groupTitle: 'Sports',
        categoryId: 'cat1',
        metadata: {'quality': 'HD'},
      );

      final domain = hiveChannel.toDomain();

      expect(domain.id, equals('ch1'));
      expect(domain.name, equals('Test Channel'));
      expect(domain.streamUrl, equals('http://example.com/stream/1'));
      expect(domain.logoUrl, equals('http://example.com/logo.png'));
      expect(domain.groupTitle, equals('Sports'));
      expect(domain.categoryId, equals('cat1'));
      expect(domain.type, equals(ContentType.live));
      expect(domain.metadata, equals({'quality': 'HD'}));
    });

    test('should create from domain model correctly', () {
      const domain = DomainChannel(
        id: 'ch2',
        name: 'News Channel',
        streamUrl: 'http://example.com/stream/2',
        logoUrl: 'http://example.com/news.png',
        groupTitle: 'News',
        categoryId: 'cat2',
      );

      final hiveChannel = HiveChannel.fromDomain(domain);

      expect(hiveChannel.id, equals('ch2'));
      expect(hiveChannel.name, equals('News Channel'));
      expect(hiveChannel.streamUrl, equals('http://example.com/stream/2'));
      expect(hiveChannel.type, equals(HiveContentType.live));
    });
  });

  group('HiveCategory', () {
    test('should convert to domain model correctly', () {
      final hiveCategory = HiveCategory(
        id: 'cat1',
        name: 'Sports',
        channelCount: 50,
        iconUrl: 'http://example.com/sports.png',
        sortOrder: 1,
        categoryType: 'live',
      );

      final domain = hiveCategory.toDomain();

      expect(domain.id, equals('cat1'));
      expect(domain.name, equals('Sports'));
      expect(domain.channelCount, equals(50));
      expect(domain.iconUrl, equals('http://example.com/sports.png'));
      expect(domain.sortOrder, equals(1));
    });

    test('should create from domain model correctly', () {
      const domain = DomainCategory(
        id: 'cat2',
        name: 'Movies',
        channelCount: 100,
        iconUrl: 'http://example.com/movies.png',
        sortOrder: 2,
      );

      final hiveCategory = HiveCategory.fromDomain(domain, 'movie');

      expect(hiveCategory.id, equals('cat2'));
      expect(hiveCategory.name, equals('Movies'));
      expect(hiveCategory.channelCount, equals(100));
      expect(hiveCategory.categoryType, equals('movie'));
    });
  });

  group('HiveVodItem', () {
    test('should convert to domain model correctly', () {
      final hiveMovie = HiveVodItem(
        id: 'mov1',
        name: 'Test Movie',
        streamUrl: 'http://example.com/movie/1.mp4',
        posterUrl: 'http://example.com/poster.jpg',
        backdropUrl: 'http://example.com/backdrop.jpg',
        description: 'A great movie',
        categoryId: 'cat1',
        genre: 'Action',
        releaseDate: '2024-01-01',
        rating: 8.5,
        duration: 7200,
      );

      final domain = hiveMovie.toDomain();

      expect(domain.id, equals('mov1'));
      expect(domain.name, equals('Test Movie'));
      expect(domain.streamUrl, equals('http://example.com/movie/1.mp4'));
      expect(domain.posterUrl, equals('http://example.com/poster.jpg'));
      expect(domain.description, equals('A great movie'));
      expect(domain.genre, equals('Action'));
      expect(domain.rating, equals(8.5));
      expect(domain.duration, equals(7200));
      expect(domain.type, equals(ContentType.movie));
    });

    test('should create from domain model correctly', () {
      const domain = VodItem(
        id: 'mov2',
        name: 'Another Movie',
        streamUrl: 'http://example.com/movie/2.mp4',
        posterUrl: 'http://example.com/poster2.jpg',
        rating: 7.0,
      );

      final hiveMovie = HiveVodItem.fromDomain(domain);

      expect(hiveMovie.id, equals('mov2'));
      expect(hiveMovie.name, equals('Another Movie'));
      expect(hiveMovie.streamUrl, equals('http://example.com/movie/2.mp4'));
      expect(hiveMovie.rating, equals(7.0));
    });
  });

  group('HiveSeries', () {
    test('should convert to domain model with seasons and episodes', () {
      final hiveEpisode = HiveEpisode(
        id: 'ep1',
        episodeNumber: 1,
        name: 'Pilot',
        streamUrl: 'http://example.com/series/1/1.mp4',
        description: 'The first episode',
        duration: 3600,
      );

      final hiveSeason = HiveSeason(
        id: 's1',
        seasonNumber: 1,
        name: 'Season 1',
        episodes: [hiveEpisode],
      );

      final hiveSeries = HiveSeries(
        id: 'ser1',
        name: 'Test Series',
        posterUrl: 'http://example.com/series.jpg',
        description: 'A great series',
        categoryId: 'cat1',
        genre: 'Drama',
        rating: 9.0,
        seasons: [hiveSeason],
      );

      final domain = hiveSeries.toDomain();

      expect(domain.id, equals('ser1'));
      expect(domain.name, equals('Test Series'));
      expect(domain.rating, equals(9.0));
      expect(domain.seasons.length, equals(1));
      expect(domain.seasons[0].seasonNumber, equals(1));
      expect(domain.seasons[0].episodes.length, equals(1));
      expect(domain.seasons[0].episodes[0].name, equals('Pilot'));
      expect(domain.totalEpisodes, equals(1));
    });
  });

  group('HiveEpgProgram', () {
    test('should convert to domain model correctly', () {
      final startTime = DateTime(2024, 1, 1, 20);
      final endTime = DateTime(2024, 1, 1, 21);

      final hiveProgram = HiveEpgProgram(
        channelId: 'ch1',
        title: 'Evening News',
        description: 'Daily news update',
        startTime: startTime,
        endTime: endTime,
        category: 'News',
        language: 'en',
      );

      final domain = hiveProgram.toDomain();

      expect(domain.channelId, equals('ch1'));
      expect(domain.title, equals('Evening News'));
      expect(domain.description, equals('Daily news update'));
      expect(domain.startTime, equals(startTime));
      expect(domain.endTime, equals(endTime));
      expect(domain.category, equals('News'));
      expect(domain.language, equals('en'));
    });

    test('should create from domain model correctly', () {
      final startTime = DateTime(2024, 1, 1, 22);
      final endTime = DateTime(2024, 1, 1, 23);

      final domain = EpgProgram(
        channelId: 'ch2',
        title: 'Late Show',
        description: 'Late night entertainment',
        startTime: startTime,
        endTime: endTime,
        category: 'Entertainment',
      );

      final hiveProgram = HiveEpgProgram.fromDomain(domain);

      expect(hiveProgram.channelId, equals('ch2'));
      expect(hiveProgram.title, equals('Late Show'));
      expect(hiveProgram.startTime, equals(startTime));
      expect(hiveProgram.endTime, equals(endTime));
    });
  });

  group('HiveSyncStatus', () {
    test('should correctly check if channel refresh is needed', () {
      final status = HiveSyncStatus(
        profileId: 'profile1',
        lastChannelSync: DateTime.now().subtract(const Duration(hours: 2)),
      );

      // Should need refresh with 1 hour TTL
      expect(status.needsChannelRefresh(const Duration(hours: 1)), isTrue);

      // Should not need refresh with 3 hour TTL
      expect(status.needsChannelRefresh(const Duration(hours: 3)), isFalse);
    });

    test('should correctly check if movie refresh is needed', () {
      final status = HiveSyncStatus(
        profileId: 'profile1',
      );

      // Should always need refresh if never synced
      expect(status.needsMovieRefresh(const Duration(hours: 4)), isTrue);
    });

    test('should correctly check if EPG refresh is needed', () {
      final status = HiveSyncStatus(
        profileId: 'profile1',
        lastEpgSync: DateTime.now().subtract(const Duration(hours: 8)),
      );

      // Should need refresh with 6 hour TTL
      expect(status.needsEpgRefresh(const Duration(hours: 6)), isTrue);
    });

    test('should update sync timestamps correctly', () {
      final status = HiveSyncStatus(profileId: 'profile1');

      expect(status.lastChannelSync, isNull);
      expect(status.channelCount, isNull);

      status.updateChannelSync(100);

      expect(status.lastChannelSync, isNotNull);
      expect(status.channelCount, equals(100));
    });

    test('should mark initial sync complete', () {
      final status = HiveSyncStatus(profileId: 'profile1');

      expect(status.isInitialSyncComplete, isFalse);

      status.markInitialSyncComplete();

      expect(status.isInitialSyncComplete, isTrue);
    });
  });

  group('HiveContentType', () {
    test('should convert to domain ContentType correctly', () {
      expect(HiveContentType.live.toDomain(), equals(ContentType.live));
      expect(HiveContentType.movie.toDomain(), equals(ContentType.movie));
      expect(HiveContentType.series.toDomain(), equals(ContentType.series));
    });

    test('should create from domain ContentType correctly', () {
      expect(
        HiveContentTypeExtension.fromDomain(ContentType.live),
        equals(HiveContentType.live),
      );
      expect(
        HiveContentTypeExtension.fromDomain(ContentType.movie),
        equals(HiveContentType.movie),
      );
      expect(
        HiveContentTypeExtension.fromDomain(ContentType.series),
        equals(HiveContentType.series),
      );
    });
  });
}

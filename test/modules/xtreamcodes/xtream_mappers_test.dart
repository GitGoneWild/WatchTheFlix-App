import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';
import 'package:watchtheflix/modules/xtreamcodes/mappers/xtream_to_domain_mappers.dart';

void main() {
  group('XtreamToDomainMappers', () {
    group('mapChannel', () {
      test('should map channel from Xtream response', () {
        final json = {
          'stream_id': '12345',
          'name': 'ESPN',
          'stream_icon': 'http://logo.com/espn.png',
          'category_id': '5',
          'category_name': 'Sports',
        };

        final channel = XtreamToDomainMappers.mapChannel(
          json,
          'http://stream.com/live/user/pass/12345.m3u8',
        );

        expect(channel.id, equals('12345'));
        expect(channel.name, equals('ESPN'));
        expect(channel.logoUrl, equals('http://logo.com/espn.png'));
        expect(channel.categoryId, equals('5'));
        expect(channel.groupTitle, equals('Sports'));
        expect(channel.streamUrl,
            equals('http://stream.com/live/user/pass/12345.m3u8'));
        expect(channel.type, equals(ContentType.live));
      });

      test('should handle missing optional fields', () {
        final json = {
          'stream_id': '123',
          'name': 'Channel',
        };

        final channel = XtreamToDomainMappers.mapChannel(json, 'http://url');

        expect(channel.id, equals('123'));
        expect(channel.name, equals('Channel'));
        expect(channel.logoUrl, isNull);
        expect(channel.categoryId, isNull);
      });

      test('should use num as fallback for stream_id', () {
        final json = {
          'num': '999',
          'name': 'Channel',
        };

        final channel = XtreamToDomainMappers.mapChannel(json, 'http://url');

        expect(channel.id, equals('999'));
      });
    });

    group('mapCategory', () {
      test('should map category from Xtream response', () {
        final json = {
          'category_id': '5',
          'category_name': 'Sports',
        };

        final category = XtreamToDomainMappers.mapCategory(json);

        expect(category.id, equals('5'));
        expect(category.name, equals('Sports'));
      });

      test('should handle channel count', () {
        final json = {
          'category_id': '5',
          'category_name': 'Sports',
          'num': '42',
        };

        final category = XtreamToDomainMappers.mapCategory(json);

        expect(category.channelCount, equals(42));
      });
    });

    group('mapMovie', () {
      test('should map movie from Xtream response', () {
        final json = {
          'stream_id': '67890',
          'name': 'Inception',
          'stream_icon': 'http://poster.com/inception.jpg',
          'cover_big': 'http://backdrop.com/inception.jpg',
          'plot': 'A mind-bending thriller',
          'category_id': '10',
          'genre': 'Sci-Fi, Thriller',
          'releaseDate': '2010',
          'rating': '8.8',
          'duration_secs': 8880,
        };

        final movie = XtreamToDomainMappers.mapMovie(
          json,
          'http://stream.com/movie/user/pass/67890.mp4',
        );

        expect(movie.id, equals('67890'));
        expect(movie.name, equals('Inception'));
        expect(movie.posterUrl, equals('http://poster.com/inception.jpg'));
        expect(movie.backdropUrl, equals('http://backdrop.com/inception.jpg'));
        expect(movie.description, equals('A mind-bending thriller'));
        expect(movie.categoryId, equals('10'));
        expect(movie.genre, equals('Sci-Fi, Thriller'));
        expect(movie.releaseDate, equals('2010'));
        expect(movie.rating, equals(8.8));
        expect(movie.duration, equals(8880));
        expect(movie.type, equals(ContentType.movie));
      });

      test('should handle rating as int', () {
        final json = {
          'stream_id': '1',
          'name': 'Movie',
          'rating': 8,
        };

        final movie = XtreamToDomainMappers.mapMovie(json, 'http://url');

        expect(movie.rating, equals(8.0));
      });
    });

    group('mapSeries', () {
      test('should map series from Xtream response', () {
        final json = {
          'series_id': '54321',
          'name': 'Breaking Bad',
          'cover': 'http://poster.com/bb.jpg',
          'backdrop_path': ['http://backdrop.com/bb.jpg'],
          'plot': 'A chemistry teacher turned drug lord',
          'category_id': '15',
          'genre': 'Drama, Crime',
          'releaseDate': '2008',
          'rating': '9.5',
        };

        final series = XtreamToDomainMappers.mapSeries(json);

        expect(series.id, equals('54321'));
        expect(series.name, equals('Breaking Bad'));
        expect(series.posterUrl, equals('http://poster.com/bb.jpg'));
        expect(series.backdropUrl, equals('http://backdrop.com/bb.jpg'));
        expect(
            series.description, equals('A chemistry teacher turned drug lord'));
        expect(series.rating, equals(9.5));
      });

      test('should handle backdrop_path as string', () {
        final json = {
          'series_id': '1',
          'name': 'Series',
          'backdrop_path': 'http://backdrop.com/image.jpg',
        };

        final series = XtreamToDomainMappers.mapSeries(json);

        expect(series.backdropUrl, equals('http://backdrop.com/image.jpg'));
      });

      test('should handle empty backdrop_path array', () {
        final json = {
          'series_id': '1',
          'name': 'Series',
          'backdrop_path': <String>[],
        };

        final series = XtreamToDomainMappers.mapSeries(json);

        expect(series.backdropUrl, isNull);
      });
    });

    group('mapEpisode', () {
      test('should map episode from Xtream response', () {
        final json = {
          'id': '999',
          'episode_num': 5,
          'title': 'Pilot Episode',
          'info': {
            'plot': 'The beginning of the story',
            'movie_image': 'http://thumb.com/ep5.jpg',
            'duration_secs': 3600,
            'releasedate': '2008-01-20',
          },
        };

        final episode = XtreamToDomainMappers.mapEpisode(
          json,
          'http://stream.com/series/user/pass/999.mp4',
        );

        expect(episode.id, equals('999'));
        expect(episode.episodeNumber, equals(5));
        expect(episode.name, equals('Pilot Episode'));
        expect(episode.description, equals('The beginning of the story'));
        expect(episode.thumbnailUrl, equals('http://thumb.com/ep5.jpg'));
        expect(episode.duration, equals(3600));
        expect(episode.airDate, equals('2008-01-20'));
      });

      test('should use name as fallback for title', () {
        final json = {
          'id': '1',
          'episode_num': 1,
          'name': 'Episode Name',
        };

        final episode = XtreamToDomainMappers.mapEpisode(json, 'http://url');

        expect(episode.name, equals('Episode Name'));
      });
    });

    group('mapEpgEntry', () {
      test('should map EPG entry from Xtream response', () {
        final now = DateTime.now();
        final startTimestamp = now.millisecondsSinceEpoch ~/ 1000;
        final endTimestamp =
            now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

        final json = {
          'title': 'News at 10',
          'description': 'Daily news update',
          'start': startTimestamp,
          'end': endTimestamp,
        };

        final epgInfo = XtreamToDomainMappers.mapEpgEntry(json);

        expect(epgInfo.currentProgram, equals('News at 10'));
        expect(epgInfo.description, equals('Daily news update'));
        expect(epgInfo.startTime, isNotNull);
        expect(epgInfo.endTime, isNotNull);
      });

      test('should handle string timestamps', () {
        final now = DateTime.now();
        final startTimestamp = (now.millisecondsSinceEpoch ~/ 1000).toString();
        final endTimestamp =
            (now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000)
                .toString();

        final json = {
          'title': 'Show',
          'start_timestamp': startTimestamp,
          'stop_timestamp': endTimestamp,
        };

        final epgInfo = XtreamToDomainMappers.mapEpgEntry(json);

        expect(epgInfo.startTime, isNotNull);
        expect(epgInfo.endTime, isNotNull);
      });
    });
  });
}

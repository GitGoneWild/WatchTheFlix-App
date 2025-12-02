import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/xtreamcodes/repositories/xtream_repository_base.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';

void main() {
  group('XtreamRepositoryBase', () {
    late TestRepository repository;

    setUp(() {
      repository = TestRepository();
    });

    group('buildUrl', () {
      test('should build correct URL without action', () {
        final credentials = XtreamCredentialsModel(
          host: 'http://server.example.com:8080',
          username: 'testuser',
          password: 'testpass',
        );

        final url = repository.buildUrl(credentials, '');

        expect(url, contains('http://server.example.com:8080/player_api.php'));
        expect(url, contains('username=testuser'));
        expect(url, contains('password=testpass'));
      });

      test('should build correct URL with action', () {
        final credentials = XtreamCredentialsModel(
          host: 'http://server.example.com:8080',
          username: 'testuser',
          password: 'testpass',
        );

        final url = repository.buildUrl(credentials, 'get_live_categories');

        expect(url, contains('&action=get_live_categories'));
      });

      test('should encode special characters in username', () {
        final credentials = XtreamCredentialsModel(
          host: 'http://server.example.com',
          username: 'test@user',
          password: 'test pass',
        );

        final url = repository.buildUrl(credentials, '');

        expect(url, contains('username=test%40user'));
        expect(url, contains('password=test%20pass'));
      });

      test('should handle trailing slash in host', () {
        final credentials = XtreamCredentialsModel(
          host: 'http://server.example.com/',
          username: 'user',
          password: 'pass',
        );

        final url = repository.buildUrl(credentials, '');

        expect(url, startsWith('http://server.example.com/player_api.php'));
        expect(url, isNot(contains('//player_api.php')));
      });
    });

    group('buildLiveStreamUrl', () {
      test('should build correct live stream URL', () {
        final credentials = XtreamCredentialsModel(
          host: 'http://server.example.com',
          username: 'user',
          password: 'pass',
        );

        final url = repository.buildLiveStreamUrl(credentials, '12345');

        expect(url, equals('http://server.example.com/live/user/pass/12345.m3u8'));
      });

      test('should use custom format', () {
        final credentials = XtreamCredentialsModel(
          host: 'http://server.example.com',
          username: 'user',
          password: 'pass',
        );

        final url = repository.buildLiveStreamUrl(credentials, '12345', format: 'ts');

        expect(url, endsWith('/12345.ts'));
      });
    });

    group('buildMovieStreamUrl', () {
      test('should build correct movie stream URL', () {
        final credentials = XtreamCredentialsModel(
          host: 'http://server.example.com',
          username: 'user',
          password: 'pass',
        );

        final url = repository.buildMovieStreamUrl(credentials, '67890');

        expect(url, equals('http://server.example.com/movie/user/pass/67890.mp4'));
      });

      test('should use custom extension', () {
        final credentials = XtreamCredentialsModel(
          host: 'http://server.example.com',
          username: 'user',
          password: 'pass',
        );

        final url = repository.buildMovieStreamUrl(credentials, '67890', extension: 'mkv');

        expect(url, endsWith('/67890.mkv'));
      });
    });

    group('buildSeriesStreamUrl', () {
      test('should build correct series stream URL', () {
        final credentials = XtreamCredentialsModel(
          host: 'http://server.example.com',
          username: 'user',
          password: 'pass',
        );

        final url = repository.buildSeriesStreamUrl(credentials, '11111');

        expect(url, equals('http://server.example.com/series/user/pass/11111.mp4'));
      });
    });

    group('handleApiError', () {
      test('should return timeout error for timeout exceptions', () {
        final error = repository.handleApiError('timeout error', 'Test operation');

        expect(error.type, equals(ApiErrorType.timeout));
      });

      test('should return network error for connection errors', () {
        final error = repository.handleApiError('connection failed', 'Test operation');

        expect(error.type, equals(ApiErrorType.network));
      });

      test('should return auth error for 401 errors', () {
        final error = repository.handleApiError('401 unauthorized', 'Test operation');

        expect(error.type, equals(ApiErrorType.auth));
      });

      test('should return not found error for 404 errors', () {
        final error = repository.handleApiError('404 not found', 'Test operation');

        expect(error.type, equals(ApiErrorType.notFound));
      });

      test('should return server error for 500 errors', () {
        final error = repository.handleApiError('500 server error', 'Test operation');

        expect(error.type, equals(ApiErrorType.server));
      });

      test('should return unknown error for other cases', () {
        final error = repository.handleApiError('some random error', 'Test operation');

        expect(error.type, equals(ApiErrorType.unknown));
      });
    });

    group('safeParseList', () {
      test('should return empty list for null', () {
        final result = repository.safeParseList(null);

        expect(result, isEmpty);
      });

      test('should parse valid list', () {
        final data = [
          {'id': '1', 'name': 'Item 1'},
          {'id': '2', 'name': 'Item 2'},
        ];

        final result = repository.safeParseList(data);

        expect(result, hasLength(2));
        expect(result[0]['id'], equals('1'));
        expect(result[1]['name'], equals('Item 2'));
      });

      test('should return empty list for map (error response)', () {
        final data = {'error': 'Some error message'};

        final result = repository.safeParseList(data);

        expect(result, isEmpty);
      });

      test('should filter out non-map items from list', () {
        final data = [
          {'id': '1'},
          'invalid',
          {'id': '2'},
          123,
        ];

        final result = repository.safeParseList(data);

        expect(result, hasLength(2));
      });
    });

    group('parseRating', () {
      test('should return null for null input', () {
        expect(repository.parseRating(null), isNull);
      });

      test('should parse double value', () {
        expect(repository.parseRating(8.5), equals(8.5));
      });

      test('should parse int value and convert to double', () {
        expect(repository.parseRating(8), equals(8.0));
      });

      test('should parse string value', () {
        expect(repository.parseRating('8.5'), equals(8.5));
      });

      test('should return null for invalid string', () {
        expect(repository.parseRating('not a number'), isNull);
      });
    });

    group('parseInt', () {
      test('should return default value for null', () {
        expect(repository.parseInt(null), equals(0));
        expect(repository.parseInt(null, defaultValue: 10), equals(10));
      });

      test('should parse int value', () {
        expect(repository.parseInt(42), equals(42));
      });

      test('should parse string value', () {
        expect(repository.parseInt('42'), equals(42));
      });

      test('should return default value for invalid string', () {
        expect(repository.parseInt('invalid'), equals(0));
        expect(repository.parseInt('invalid', defaultValue: 5), equals(5));
      });
    });
  });
}

/// Test implementation of XtreamRepositoryBase
class TestRepository extends XtreamRepositoryBase {}

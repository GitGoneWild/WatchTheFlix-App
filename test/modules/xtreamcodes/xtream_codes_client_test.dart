import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';
import 'package:watchtheflix/modules/xtreamcodes/xtream_codes_client.dart';

void main() {
  group('XtreamCodesClient', () {
    group('Factory constructor', () {
      test('should create instance with default configuration', () {
        // This test verifies the factory constructor creates a valid instance
        // without throwing exceptions
        final client = XtreamCodesClient();

        expect(client, isNotNull);
      });
    });

    group('Stream URL generation', () {
      late XtreamCodesClient client;
      late XtreamCredentialsModel credentials;

      setUp(() {
        client = XtreamCodesClient();
        credentials = const XtreamCredentialsModel(
          host: 'http://server.example.com:8080',
          username: 'testuser',
          password: 'testpass',
        );
      });

      test('getLiveStreamUrl should generate correct URL with default format',
          () {
        final url = client.getLiveStreamUrl(credentials, '12345');

        expect(
            url,
            equals(
                'http://server.example.com:8080/live/testuser/testpass/12345.m3u8'));
      });

      test('getLiveStreamUrl should generate correct URL with custom format',
          () {
        final url = client.getLiveStreamUrl(credentials, '12345', format: 'ts');

        expect(url, endsWith('/12345.ts'));
      });

      test(
          'getMovieStreamUrl should generate correct URL with default extension',
          () {
        final url = client.getMovieStreamUrl(credentials, '67890');

        expect(
            url,
            equals(
                'http://server.example.com:8080/movie/testuser/testpass/67890.mp4'));
      });

      test(
          'getMovieStreamUrl should generate correct URL with custom extension',
          () {
        final url =
            client.getMovieStreamUrl(credentials, '67890', extension: 'mkv');

        expect(url, endsWith('/67890.mkv'));
      });

      test(
          'getSeriesStreamUrl should generate correct URL with default extension',
          () {
        final url = client.getSeriesStreamUrl(credentials, '11111');

        expect(
            url,
            equals(
                'http://server.example.com:8080/series/testuser/testpass/11111.mp4'));
      });

      test(
          'getSeriesStreamUrl should generate correct URL with custom extension',
          () {
        final url =
            client.getSeriesStreamUrl(credentials, '11111', extension: 'avi');

        expect(url, endsWith('/11111.avi'));
      });
    });

    group('Credentials handling', () {
      test('should handle credentials with trailing slash in host', () {
        final client = XtreamCodesClient();
        const credentials = XtreamCredentialsModel(
          host: 'http://server.example.com:8080/',
          username: 'user',
          password: 'pass',
        );

        final url = client.getLiveStreamUrl(credentials, '123');

        // Should not have double slashes
        expect(url, isNot(contains('//live')));
      });

      test('should handle special characters in credentials', () {
        final client = XtreamCodesClient();
        const credentials = XtreamCredentialsModel(
          host: 'http://server.example.com',
          username: 'user@domain.com',
          password: 'p@ss w0rd!',
        );

        // The stream URL includes credentials in path, which should work as-is
        final url = client.getLiveStreamUrl(credentials, '123');

        expect(url, contains('user@domain.com'));
        expect(url, contains('p@ss w0rd!'));
      });
    });

    group('XtreamCredentialsModel', () {
      test('baseUrl should normalize host', () {
        const credentialsWithSlash = XtreamCredentialsModel(
          host: 'http://example.com/',
          username: 'user',
          password: 'pass',
        );

        const credentialsWithoutSlash = XtreamCredentialsModel(
          host: 'http://example.com',
          username: 'user',
          password: 'pass',
        );

        expect(credentialsWithSlash.baseUrl, equals('http://example.com'));
        expect(credentialsWithoutSlash.baseUrl, equals('http://example.com'));
      });

      test('authParams should format correctly', () {
        const credentials = XtreamCredentialsModel(
          host: 'http://example.com',
          username: 'myuser',
          password: 'mypass',
        );

        expect(
            credentials.authParams, equals('username=myuser&password=mypass'));
      });

      test('should support serialization roundtrip', () {
        const original = XtreamCredentialsModel(
          host: 'http://example.com:8080',
          username: 'testuser',
          password: 'testpass',
          serverInfo: 'Server Info',
        );

        final json = original.toJson();
        final restored = XtreamCredentialsModel.fromJson(json);

        expect(restored.host, equals(original.host));
        expect(restored.username, equals(original.username));
        expect(restored.password, equals(original.password));
        expect(restored.serverInfo, equals(original.serverInfo));
      });
    });
  });
}

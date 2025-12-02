import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:watchtheflix/data/datasources/remote/api_client.dart';
import 'package:watchtheflix/features/xtream/xtream_api_client.dart';
import 'package:watchtheflix/domain/entities/playlist_source.dart';

class MockApiClient extends Mock implements ApiClient {}

// Register fallback values for Options
class FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOptions());
  });

  group('XtreamApiClient', () {
    late MockApiClient mockApiClient;
    late XtreamApiClientImpl xtreamClient;
    late XtreamCredentials credentials;

    setUp(() {
      mockApiClient = MockApiClient();
      xtreamClient = XtreamApiClientImpl(apiClient: mockApiClient);
      credentials = const XtreamCredentials(
        host: 'http://test.server.com:8080',
        username: 'testuser',
        password: 'testpass',
      );
    });

    group('Login', () {
      test('should return XtreamLoginResponse on successful login', () async {
        // Arrange
        final responseData = {
          'user_info': {
            'username': 'testuser',
            'password': 'testpass',
            'message': 'Welcome',
            'auth': 1,
            'status': 'Active',
            'exp_date': '2025-12-31',
            'is_trial': '0',
            'active_cons': '1',
            'max_connections': '2',
          },
          'server_info': {
            'allowed_output_formats': ['m3u8', 'ts'],
          },
        };

        when(
          () => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            requestOptions: RequestOptions(),
          ),
        );

        // Act
        final result = await xtreamClient.login(credentials);

        // Assert
        expect(result.isAuthenticated, isTrue);
        expect(result.username, equals('testuser'));
        expect(result.status, equals('Active'));
      });

      test('should throw AuthException when auth fails', () async {
        // Arrange
        final responseData = {
          'user_info': {
            'username': 'testuser',
            'password': 'testpass',
            'message': 'Invalid credentials',
            'auth': 0,
            'status': 'Disabled',
          },
          'server_info': {},
        };

        when(
          () => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            requestOptions: RequestOptions(),
          ),
        );

        // Act & Assert
        expect(
          () => xtreamClient.login(credentials),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Stream URLs', () {
      test('should generate correct live stream URL', () {
        // Act
        final url = xtreamClient.getLiveStreamUrl(
          credentials,
          '12345',
        );

        // Assert
        expect(
          url,
          equals(
            'http://test.server.com:8080/live/testuser/testpass/12345.m3u8',
          ),
        );
      });

      test('should generate correct movie stream URL', () {
        // Act
        final url = xtreamClient.getMovieStreamUrl(
          credentials,
          '54321',
        );

        // Assert
        expect(
          url,
          equals(
            'http://test.server.com:8080/movie/testuser/testpass/54321.mp4',
          ),
        );
      });

      test('should generate correct series stream URL', () {
        // Act
        final url = xtreamClient.getSeriesStreamUrl(
          credentials,
          '99999',
          extension: 'mkv',
        );

        // Assert
        expect(
          url,
          equals(
            'http://test.server.com:8080/series/testuser/testpass/99999.mkv',
          ),
        );
      });
    });

    group('Fetch Live Channels', () {
      test('should return list of channels', () async {
        // Arrange
        final responseData = [
          {
            'stream_id': '1',
            'name': 'Channel 1',
            'stream_icon': 'http://logo1.png',
            'category_id': '10',
          },
          {
            'stream_id': '2',
            'name': 'Channel 2',
            'stream_icon': 'http://logo2.png',
            'category_id': '10',
          },
        ];

        when(
          () => mockApiClient.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            requestOptions: RequestOptions(),
          ),
        );

        // Act
        final result = await xtreamClient.fetchLiveChannels(credentials);

        // Assert
        expect(result.length, equals(2));
        expect(result[0].id, equals('1'));
        expect(result[0].name, equals('Channel 1'));
        expect(result[1].id, equals('2'));
      });

      test('should filter channels by category', () async {
        // Arrange
        final responseData = [
          {
            'stream_id': '1',
            'name': 'Sports Channel',
            'stream_icon': 'http://logo1.png',
            'category_id': '5',
          },
        ];

        when(
          () => mockApiClient.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            requestOptions: RequestOptions(),
          ),
        );

        // Act
        final result = await xtreamClient.fetchLiveChannels(
          credentials,
          categoryId: '5',
        );

        // Assert
        expect(result.length, equals(1));
        expect(result[0].categoryId, equals('5'));
      });
    });

    group('Fetch Live Categories', () {
      test('should return list of categories', () async {
        // Arrange
        final responseData = [
          {
            'category_id': '1',
            'category_name': 'Sports',
          },
          {
            'category_id': '2',
            'category_name': 'News',
          },
          {
            'category_id': '3',
            'category_name': 'Entertainment',
          },
        ];

        when(
          () => mockApiClient.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: responseData,
            requestOptions: RequestOptions(),
          ),
        );

        // Act
        final result = await xtreamClient.fetchLiveCategories(credentials);

        // Assert
        expect(result.length, equals(3));
        expect(result[0].id, equals('1'));
        expect(result[0].name, equals('Sports'));
      });
    });
  });

  group('EpgEntry', () {
    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'epg_id': '123',
        'title': 'Test Program',
        'description': 'Test description',
        'start': '2025-12-01T10:00:00Z',
        'end': '2025-12-01T11:00:00Z',
        'lang': 'en',
      };

      // Act
      final entry = EpgEntry.fromJson(json);

      // Assert
      expect(entry.channelId, equals('123'));
      expect(entry.title, equals('Test Program'));
      expect(entry.description, equals('Test description'));
      expect(entry.language, equals('en'));
    });

    test('should handle Unix timestamp format', () {
      // Arrange
      final now = DateTime.now();
      final startTimestamp =
          now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch ~/
              1000;
      final endTimestamp =
          now.add(const Duration(minutes: 30)).millisecondsSinceEpoch ~/ 1000;

      final json = {
        'epg_id': '456',
        'title': 'Live Program',
        'start_timestamp': startTimestamp,
        'stop_timestamp': endTimestamp,
      };

      // Act
      final entry = EpgEntry.fromJson(json);

      // Assert
      expect(entry.isCurrentlyAiring, isTrue);
      expect(entry.progress, greaterThan(0));
      expect(entry.progress, lessThan(1));
    });

    test('should calculate progress correctly', () {
      // Arrange
      final now = DateTime.now();
      final entry = EpgEntry(
        channelId: '789',
        title: 'Test',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 30)),
      );

      // Act & Assert
      expect(entry.isCurrentlyAiring, isTrue);
      expect(entry.progress, closeTo(0.5, 0.1));
    });
  });

  group('XtreamLoginResponse', () {
    test('should parse server response correctly', () {
      // Arrange
      final json = {
        'user_info': {
          'username': 'user123',
          'password': 'pass456',
          'message': 'Welcome back',
          'auth': 1,
          'status': 'Active',
          'exp_date': '1735689600',
          'is_trial': '1',
          'active_cons': '2',
          'max_connections': '5',
        },
        'server_info': {
          'allowed_output_formats': ['m3u8', 'ts', 'rtmp'],
        },
      };

      // Act
      final response = XtreamLoginResponse.fromJson(json, 'http://server.com');

      // Assert
      expect(response.isAuthenticated, isTrue);
      expect(response.username, equals('user123'));
      expect(response.status, equals('Active'));
      expect(response.isTrial, isTrue);
      expect(response.activeConnections, equals(2));
      expect(response.maxConnections, equals(5));
      expect(response.allowedOutputFormats, contains('m3u8'));
    });
  });
}

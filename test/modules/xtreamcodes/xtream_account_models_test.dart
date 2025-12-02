import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/xtreamcodes/account/xtream_account_models.dart';

void main() {
  group('XtreamUserInfo', () {
    test('should parse from JSON correctly', () {
      final json = {
        'username': 'testuser',
        'password': 'testpass',
        'message': 'Welcome to World 8K',
        'auth': 1,
        'status': 'Active',
        'exp_date': '1769360699',
        'is_trial': '0',
        'active_cons': '0',
        'created_at': '1735232698',
        'max_connections': '1',
        'allowed_output_formats': ['m3u8', 'ts', 'rtmp'],
      };

      final userInfo = XtreamUserInfo.fromJson(json);

      expect(userInfo.username, equals('testuser'));
      expect(userInfo.password, equals('testpass'));
      expect(userInfo.message, equals('Welcome to World 8K'));
      expect(userInfo.isAuthenticated, isTrue);
      expect(userInfo.status, equals('Active'));
      expect(userInfo.isTrial, isFalse);
      expect(userInfo.activeConnections, equals(0));
      expect(userInfo.maxConnections, equals(1));
      expect(userInfo.allowedOutputFormats, contains('m3u8'));
      expect(userInfo.allowedOutputFormats, contains('ts'));
      expect(userInfo.allowedOutputFormats, contains('rtmp'));
    });

    test('should detect active account status', () {
      final userInfo = XtreamUserInfo.fromJson(const {
        'auth': 1,
        'status': 'Active',
        'is_trial': '0',
      });

      expect(userInfo.accountStatus, equals(AccountStatus.active));
      expect(userInfo.accountStatus.isGood, isTrue);
      expect(userInfo.accountStatus.displayName, equals('Active'));
    });

    test('should detect trial account status', () {
      final userInfo = XtreamUserInfo.fromJson(const {
        'auth': 1,
        'status': 'Active',
        'is_trial': '1',
      });

      expect(userInfo.accountStatus, equals(AccountStatus.trial));
      expect(userInfo.accountStatus.isWarning, isTrue);
    });

    test('should detect expired account', () {
      // Unix timestamp in the past
      final pastTimestamp = (DateTime.now()
                  .subtract(const Duration(days: 30))
                  .millisecondsSinceEpoch ~/
              1000)
          .toString();

      final userInfo = XtreamUserInfo.fromJson({
        'auth': 1,
        'status': 'Expired',
        'exp_date': pastTimestamp,
      });

      expect(userInfo.isExpired, isTrue);
    });

    test('should calculate days until expiry', () {
      // Unix timestamp 30 days in the future
      final futureTimestamp = (DateTime.now()
                  .add(const Duration(days: 30))
                  .millisecondsSinceEpoch ~/
              1000)
          .toString();

      final userInfo = XtreamUserInfo.fromJson({
        'auth': 1,
        'status': 'Active',
        'exp_date': futureTimestamp,
      });

      // Allow 1 day tolerance due to time differences
      expect(userInfo.daysUntilExpiry, greaterThanOrEqualTo(29));
      expect(userInfo.daysUntilExpiry, lessThanOrEqualTo(31));
    });

    test('should handle missing optional fields', () {
      final userInfo = XtreamUserInfo.fromJson(const {
        'auth': 1,
        'status': 'Active',
      });

      expect(userInfo.username, isEmpty);
      expect(userInfo.message, isEmpty);
      expect(userInfo.expDate, isNull);
      expect(userInfo.createdAt, isNull);
      expect(userInfo.allowedOutputFormats, isEmpty);
    });
  });

  group('XtreamServerInfo', () {
    test('should parse from JSON correctly', () {
      final json = {
        'url': 'server.example.com',
        'port': '80',
        'https_port': '443',
        'server_protocol': 'http',
        'rtmp_port': '25462',
        'timezone': 'Europe/Amsterdam',
        'timestamp_now': 1764602228,
        'time_now': '2025-12-01 16:17:08',
        'process': true,
      };

      final serverInfo = XtreamServerInfo.fromJson(json);

      expect(serverInfo.url, equals('server.example.com'));
      expect(serverInfo.port, equals('80'));
      expect(serverInfo.httpsPort, equals('443'));
      expect(serverInfo.serverProtocol, equals('http'));
      expect(serverInfo.rtmpPort, equals('25462'));
      expect(serverInfo.timezone, equals('Europe/Amsterdam'));
      expect(serverInfo.timeNow, equals('2025-12-01 16:17:08'));
      expect(serverInfo.process, isTrue);
    });

    test('should generate correct full URL', () {
      final serverInfo = XtreamServerInfo.fromJson(const {
        'url': 'server.example.com',
        'port': '8080',
        'https_port': '443',
        'server_protocol': 'http',
      });

      expect(serverInfo.fullUrl, equals('http://server.example.com:8080'));
    });

    test('should omit default ports in full URL', () {
      final httpServer = XtreamServerInfo.fromJson(const {
        'url': 'server.example.com',
        'port': '80',
        'server_protocol': 'http',
      });

      expect(httpServer.fullUrl, equals('http://server.example.com'));

      final httpsServer = XtreamServerInfo.fromJson(const {
        'url': 'server.example.com',
        'https_port': '443',
        'server_protocol': 'https',
      });

      expect(httpsServer.fullUrl, equals('https://server.example.com'));
    });

    test('should detect HTTPS availability', () {
      final serverWithHttps = XtreamServerInfo.fromJson(const {
        'https_port': '443',
      });

      final serverWithoutHttps = XtreamServerInfo.fromJson(const {
        'https_port': '0',
      });

      expect(serverWithHttps.hasHttps, isTrue);
      expect(serverWithoutHttps.hasHttps, isFalse);
    });

    test('should detect RTMP availability', () {
      final serverWithRtmp = XtreamServerInfo.fromJson(const {
        'rtmp_port': '25462',
      });

      final serverWithoutRtmp = XtreamServerInfo.fromJson(const {
        'rtmp_port': '',
      });

      expect(serverWithRtmp.hasRtmp, isTrue);
      expect(serverWithoutRtmp.hasRtmp, isFalse);
    });
  });

  group('XtreamAccountOverview', () {
    test('should parse complete response', () {
      final json = {
        'user_info': {
          'username': 'testuser',
          'password': 'testpass',
          'message': 'Welcome',
          'auth': 1,
          'status': 'Active',
          'exp_date': '1769360699',
          'is_trial': '0',
          'active_cons': '0',
          'created_at': '1735232698',
          'max_connections': '1',
          'allowed_output_formats': ['m3u8', 'ts', 'rtmp'],
        },
        'server_info': {
          'url': 'server.example.com',
          'port': '80',
          'https_port': '443',
          'server_protocol': 'http',
          'rtmp_port': '25462',
          'timezone': 'Europe/Amsterdam',
          'timestamp_now': 1764602228,
          'time_now': '2025-12-01 16:17:08',
          'process': true,
        },
      };

      final overview = XtreamAccountOverview.fromJson(json);

      expect(overview.isAuthenticated, isTrue);
      expect(overview.userInfo.username, equals('testuser'));
      expect(overview.serverInfo.url, equals('server.example.com'));
      expect(overview.status, equals(AccountStatus.active));
    });

    test('should handle empty user_info and server_info', () {
      final overview = XtreamAccountOverview.fromJson(const {});

      expect(overview.isAuthenticated, isFalse);
      expect(overview.userInfo.username, isEmpty);
      expect(overview.serverInfo.url, isEmpty);
    });
  });

  group('AccountStatus', () {
    test('should have correct display names', () {
      expect(AccountStatus.active.displayName, equals('Active'));
      expect(AccountStatus.trial.displayName, equals('Trial'));
      expect(AccountStatus.expired.displayName, equals('Expired'));
      expect(AccountStatus.disabled.displayName, equals('Disabled'));
    });

    test('should have correct status flags', () {
      expect(AccountStatus.active.isGood, isTrue);
      expect(AccountStatus.trial.isWarning, isTrue);
      expect(AccountStatus.expired.isBad, isTrue);
      expect(AccountStatus.disabled.isBad, isTrue);
    });
  });
}

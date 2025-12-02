import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/xtreamcodes/auth/xtream_auth_service.dart';
import 'package:watchtheflix/modules/xtreamcodes/account/xtream_account_models.dart';
import 'package:watchtheflix/modules/core/models/base_models.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';

void main() {
  group('XtreamAuthService', () {
    group('XtreamAuthError', () {
      test('should create invalidCredentials error', () {
        final error = XtreamAuthError.invalidCredentials();

        expect(error.authErrorType, equals(AuthErrorType.invalidCredentials));
        expect(error.message, equals('Invalid username or password'));
        expect(error.type, equals(ApiErrorType.auth));
      });

      test('should create invalidCredentials error with custom message', () {
        final error = XtreamAuthError.invalidCredentials('Custom message');

        expect(error.message, equals('Custom message'));
      });

      test('should create serverUnreachable error', () {
        final error = XtreamAuthError.serverUnreachable();

        expect(error.authErrorType, equals(AuthErrorType.serverUnreachable));
        expect(error.message, equals('Server is unreachable'));
      });

      test('should create accountExpired error', () {
        final error = XtreamAuthError.accountExpired();

        expect(error.authErrorType, equals(AuthErrorType.accountExpired));
        expect(error.message, equals('Account has expired'));
      });

      test('should create accountDisabled error', () {
        final error = XtreamAuthError.accountDisabled();

        expect(error.authErrorType, equals(AuthErrorType.accountDisabled));
        expect(error.message, equals('Account is disabled'));
      });
    });

    group('XtreamAuthResult', () {
      test('should create success result', () {
        final accountInfo = XtreamAccountOverview(
          userInfo: XtreamUserInfo(
            username: 'test',
            password: 'pass',
            message: 'Welcome',
            auth: 1,
            status: 'Active',
          ),
          serverInfo: XtreamServerInfo(
            url: 'server.example.com',
            port: '80',
            httpsPort: '443',
            serverProtocol: 'http',
            rtmpPort: '',
            timezone: 'UTC',
            timeNow: 'now',
          ),
        );

        final result = XtreamAuthResult.success(accountInfo);

        expect(result.isAuthenticated, isTrue);
        expect(result.accountInfo, isNotNull);
        expect(result.accountInfo!.userInfo.username, equals('test'));
        expect(result.error, isNull);
      });

      test('should create failure result', () {
        final error = XtreamAuthError.invalidCredentials();

        final result = XtreamAuthResult.failure(error);

        expect(result.isAuthenticated, isFalse);
        expect(result.accountInfo, isNull);
        expect(result.error, isNotNull);
        expect(result.error!.authErrorType, equals(AuthErrorType.invalidCredentials));
      });
    });
  });

  group('AuthErrorType', () {
    test('should have all expected values', () {
      expect(AuthErrorType.values, contains(AuthErrorType.invalidCredentials));
      expect(AuthErrorType.values, contains(AuthErrorType.serverUnreachable));
      expect(AuthErrorType.values, contains(AuthErrorType.accountExpired));
      expect(AuthErrorType.values, contains(AuthErrorType.accountDisabled));
      expect(AuthErrorType.values, contains(AuthErrorType.networkError));
      expect(AuthErrorType.values, contains(AuthErrorType.unknown));
    });
  });

  group('XtreamCredentialsModel', () {
    test('should create with required fields', () {
      const credentials = XtreamCredentialsModel(
        host: 'http://server.example.com:8080',
        username: 'testuser',
        password: 'testpass',
      );

      expect(credentials.host, equals('http://server.example.com:8080'));
      expect(credentials.username, equals('testuser'));
      expect(credentials.password, equals('testpass'));
      expect(credentials.serverInfo, isNull);
    });

    test('should normalize baseUrl by removing trailing slash', () {
      const credentials = XtreamCredentialsModel(
        host: 'http://server.example.com:8080/',
        username: 'user',
        password: 'pass',
      );

      expect(credentials.baseUrl, equals('http://server.example.com:8080'));
    });

    test('should generate correct authParams', () {
      const credentials = XtreamCredentialsModel(
        host: 'http://server.example.com',
        username: 'myuser',
        password: 'mypass',
      );

      expect(credentials.authParams, equals('username=myuser&password=mypass'));
    });

    test('should serialize to JSON correctly', () {
      const credentials = XtreamCredentialsModel(
        host: 'http://server.example.com',
        username: 'user',
        password: 'pass',
        serverInfo: 'Some info',
      );

      final json = credentials.toJson();

      expect(json['host'], equals('http://server.example.com'));
      expect(json['username'], equals('user'));
      expect(json['password'], equals('pass'));
      expect(json['serverInfo'], equals('Some info'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'host': 'http://server.example.com',
        'username': 'user',
        'password': 'pass',
        'serverInfo': 'Some info',
      };

      final credentials = XtreamCredentialsModel.fromJson(json);

      expect(credentials.host, equals('http://server.example.com'));
      expect(credentials.username, equals('user'));
      expect(credentials.password, equals('pass'));
      expect(credentials.serverInfo, equals('Some info'));
    });

    test('should support equality comparison', () {
      const credentials1 = XtreamCredentialsModel(
        host: 'http://server.example.com',
        username: 'user',
        password: 'pass',
      );
      const credentials2 = XtreamCredentialsModel(
        host: 'http://server.example.com',
        username: 'user',
        password: 'pass',
      );
      const credentials3 = XtreamCredentialsModel(
        host: 'http://different.com',
        username: 'user',
        password: 'pass',
      );

      expect(credentials1, equals(credentials2));
      expect(credentials1, isNot(equals(credentials3)));
    });
  });
}

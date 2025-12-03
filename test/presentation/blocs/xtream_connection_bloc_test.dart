import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/modules/core/models/api_result.dart';
import 'package:watchtheflix/modules/core/storage/storage_service.dart';
import 'package:watchtheflix/modules/xtreamcodes/auth/xtream_auth_service.dart';
import 'package:watchtheflix/modules/xtreamcodes/auth/xtream_credentials.dart';
import 'package:watchtheflix/modules/xtreamcodes/epg/xmltv_parser.dart';
import 'package:watchtheflix/modules/xtreamcodes/xtream_service_manager.dart';
import 'package:watchtheflix/presentation/blocs/xtream_connection/xtream_connection_bloc.dart';
import 'package:watchtheflix/presentation/blocs/xtream_connection/xtream_connection_event.dart';
import 'package:watchtheflix/presentation/blocs/xtream_connection/xtream_connection_state.dart';

class MockXtreamAuthService extends Mock implements IXtreamAuthService {}

class MockStorageService extends Mock implements IStorageService {}

class MockXmltvParser extends Mock implements IXmltvParser {}

class FakeXtreamCredentials extends Fake implements XtreamCredentials {}

void main() {
  late MockXtreamAuthService mockAuthService;
  late MockStorageService mockStorage;
  late MockXmltvParser mockXmltvParser;
  late XtreamServiceManager serviceManager;

  setUpAll(() {
    registerFallbackValue(FakeXtreamCredentials());
  });

  setUp(() {
    mockAuthService = MockXtreamAuthService();
    mockStorage = MockStorageService();
    mockXmltvParser = MockXmltvParser();

    serviceManager = XtreamServiceManager(
      authService: mockAuthService,
      storage: mockStorage,
      xmltvParser: mockXmltvParser,
    );
  });

  group('XtreamConnectionBloc', () {
    final testCredentials = XtreamCredentials.fromUrl(
      serverUrl: 'http://test.com:8080',
      username: 'testuser',
      password: 'testpass',
    );

    group('Initial state', () {
      test('should start with XtreamConnectionInitial', () {
        final bloc = XtreamConnectionBloc(
          authService: mockAuthService,
          serviceManager: serviceManager,
        );

        expect(bloc.state, const XtreamConnectionInitial());
        bloc.close();
      });
    });

    group('XtreamConnectionStarted', () {
      blocTest<XtreamConnectionBloc, XtreamConnectionState>(
        'emits validation error when credentials are invalid',
        setUp: () {
          when(() => mockAuthService.validateCredentials(any())).thenReturn(
            ApiResult.failure(
              const ApiError(
                type: ApiErrorType.validation,
                message: 'Server URL is required',
              ),
            ),
          );
        },
        build: () => XtreamConnectionBloc(
          authService: mockAuthService,
          serviceManager: serviceManager,
        ),
        act: (bloc) => bloc.add(XtreamConnectionStarted(
          credentials: testCredentials,
        )),
        expect: () => [
          isA<XtreamConnectionInProgress>().having(
            (s) => s.currentStep,
            'currentStep',
            ConnectionStep.validatingCredentials,
          ),
          isA<XtreamConnectionError>().having(
            (s) => s.errorType,
            'errorType',
            ConnectionErrorType.invalidCredentials,
          ),
        ],
      );
    });

    group('XtreamConnectionReset', () {
      blocTest<XtreamConnectionBloc, XtreamConnectionState>(
        'emits XtreamConnectionInitial when reset',
        build: () => XtreamConnectionBloc(
          authService: mockAuthService,
          serviceManager: serviceManager,
        ),
        act: (bloc) => bloc.add(const XtreamConnectionReset()),
        expect: () => [const XtreamConnectionInitial()],
      );
    });

    group('ConnectionStep extension', () {
      test('idle step has correct title', () {
        expect(ConnectionStep.idle.title, 'Preparing...');
      });

      test('testingConnection step has correct title', () {
        expect(ConnectionStep.testingConnection.title, 'Testing Connection');
      });

      test('authenticating step has correct title', () {
        expect(ConnectionStep.authenticating.title, 'Authenticating');
      });

      test('fetchingChannels step has correct title', () {
        expect(ConnectionStep.fetchingChannels.title, 'Getting Live Channels');
      });

      test('fetchingMovies step has correct title', () {
        expect(ConnectionStep.fetchingMovies.title, 'Loading Movies');
      });

      test('fetchingSeries step has correct title', () {
        expect(ConnectionStep.fetchingSeries.title, 'Loading Series');
      });

      test('updatingEpg step has correct title', () {
        expect(ConnectionStep.updatingEpg.title, 'Updating EPG');
      });

      test('completed step has correct title', () {
        expect(ConnectionStep.completed.title, 'Setup Complete!');
      });

      test('all steps have descriptions', () {
        for (final step in ConnectionStep.values) {
          expect(step.description, isNotEmpty);
        }
      });

      test('all steps have icons', () {
        for (final step in ConnectionStep.values) {
          expect(step.icon, isNotNull);
        }
      });
    });

    group('XtreamConnectionInProgress state', () {
      test('copyWith creates new state with updated values', () {
        const original = XtreamConnectionInProgress(
          currentStep: ConnectionStep.testingConnection,
          progress: 0.2,
          message: 'Testing...',
          channelsLoaded: 0,
          moviesLoaded: 0,
          seriesLoaded: 0,
        );

        final updated = original.copyWith(
          currentStep: ConnectionStep.fetchingChannels,
          progress: 0.4,
          channelsLoaded: 10,
        );

        expect(updated.currentStep, ConnectionStep.fetchingChannels);
        expect(updated.progress, 0.4);
        expect(updated.message, 'Testing...');
        expect(updated.channelsLoaded, 10);
        expect(updated.moviesLoaded, 0);
        expect(updated.seriesLoaded, 0);
      });

      test('props returns all properties', () {
        const state = XtreamConnectionInProgress(
          currentStep: ConnectionStep.testingConnection,
          progress: 0.5,
          message: 'Test message',
          channelsLoaded: 10,
          moviesLoaded: 20,
          seriesLoaded: 30,
        );

        expect(state.props, [
          ConnectionStep.testingConnection,
          0.5,
          'Test message',
          10,
          20,
          30,
        ]);
      });
    });

    group('XtreamConnectionSuccess state', () {
      test('props returns loaded counts', () {
        const state = XtreamConnectionSuccess(
          channelsLoaded: 10,
          moviesLoaded: 20,
          seriesLoaded: 30,
        );

        expect(state.props, [10, 20, 30]);
      });

      test('default values are zero', () {
        const state = XtreamConnectionSuccess();

        expect(state.channelsLoaded, 0);
        expect(state.moviesLoaded, 0);
        expect(state.seriesLoaded, 0);
      });
    });

    group('XtreamConnectionError state', () {
      test('props returns all properties', () {
        const state = XtreamConnectionError(
          message: 'Error message',
          failedStep: ConnectionStep.authenticating,
          errorType: ConnectionErrorType.authenticationFailed,
          canRetry: false,
        );

        expect(state.props, [
          'Error message',
          ConnectionStep.authenticating,
          ConnectionErrorType.authenticationFailed,
          false,
        ]);
      });

      test('default canRetry is true', () {
        const state = XtreamConnectionError(
          message: 'Error',
          failedStep: ConnectionStep.testingConnection,
        );

        expect(state.canRetry, true);
        expect(state.errorType, ConnectionErrorType.unknown);
      });
    });

    group('ConnectionErrorType', () {
      test('has all expected error types', () {
        expect(ConnectionErrorType.values, [
          ConnectionErrorType.invalidCredentials,
          ConnectionErrorType.networkError,
          ConnectionErrorType.serverError,
          ConnectionErrorType.authenticationFailed,
          ConnectionErrorType.accountExpired,
          ConnectionErrorType.timeout,
          ConnectionErrorType.unknown,
        ]);
      });
    });
  });
}

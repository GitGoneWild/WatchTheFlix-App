import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/core/errors/exceptions.dart';
import 'package:watchtheflix/domain/entities/playlist_source.dart';
import 'package:watchtheflix/features/xtream/xtream_api_client.dart';
import 'package:watchtheflix/features/xtream/xtream_service.dart';
import 'package:watchtheflix/data/models/category_model.dart';
import 'package:watchtheflix/data/models/channel_model.dart';
import 'package:watchtheflix/data/models/movie_model.dart';
import 'package:watchtheflix/data/models/series_model.dart';
import 'package:watchtheflix/presentation/blocs/xtream_onboarding/xtream_onboarding_bloc.dart';

class MockXtreamApiClient extends Mock implements XtreamApiClient {}

class MockXtreamService extends Mock implements XtreamService {}

void main() {
  group('XtreamOnboardingBloc', () {
    late MockXtreamApiClient mockApiClient;
    late MockXtreamService mockXtreamService;
    late XtreamCredentials credentials;

    setUp(() {
      mockApiClient = MockXtreamApiClient();
      mockXtreamService = MockXtreamService();
      credentials = const XtreamCredentials(
        host: 'http://test.server.com:8080',
        username: 'testuser',
        password: 'testpass',
      );
    });

    test('initial state is XtreamOnboardingInitial', () {
      final bloc = XtreamOnboardingBloc(
        apiClient: mockApiClient,
        xtreamService: mockXtreamService,
      );
      expect(bloc.state, const XtreamOnboardingInitial());
      bloc.close();
    });

    group('StartOnboardingEvent', () {
      blocTest<XtreamOnboardingBloc, XtreamOnboardingState>(
        'emits [InProgress, ...steps..., Completed] when onboarding succeeds',
        setUp: () {
          when(() => mockApiClient.login(credentials)).thenAnswer(
            (_) async => XtreamLoginResponse(
              username: 'testuser',
              password: 'testpass',
              message: 'OK',
              auth: 1,
              status: 'Active',
              serverUrl: 'http://test.server.com:8080',
            ),
          );
          when(() => mockXtreamService.getLiveCategories(credentials,
              forceRefresh: true)).thenAnswer(
            (_) async => [
              const CategoryModel(id: '1', name: 'Sports'),
              const CategoryModel(id: '2', name: 'News'),
            ],
          );
          when(() => mockXtreamService.getMovieCategories(credentials,
              forceRefresh: true)).thenAnswer(
            (_) async => [
              const CategoryModel(id: '1', name: 'Action'),
            ],
          );
          when(() => mockXtreamService.getSeriesCategories(credentials,
              forceRefresh: true)).thenAnswer(
            (_) async => [
              const CategoryModel(id: '1', name: 'Drama'),
            ],
          );
          when(() => mockXtreamService.getLiveChannels(credentials,
              forceRefresh: true)).thenAnswer(
            (_) async => [
              const ChannelModel(id: '1', name: 'Channel 1', streamUrl: 'url1'),
              const ChannelModel(id: '2', name: 'Channel 2', streamUrl: 'url2'),
            ],
          );
          when(() =>
                  mockXtreamService.getMovies(credentials, forceRefresh: true))
              .thenAnswer(
            (_) async => [
              const MovieModel(id: '1', name: 'Movie 1', streamUrl: 'url1'),
            ],
          );
          when(() =>
                  mockXtreamService.getSeries(credentials, forceRefresh: true))
              .thenAnswer(
            (_) async => [
              const SeriesModel(id: '1', name: 'Series 1'),
            ],
          );
          when(() => mockXtreamService.getEpg(credentials, forceRefresh: true))
              .thenAnswer((_) async => {});
        },
        build: () => XtreamOnboardingBloc(
          apiClient: mockApiClient,
          xtreamService: mockXtreamService,
        ),
        act: (bloc) => bloc.add(
          StartOnboardingEvent(
            credentials: credentials,
            playlistName: 'Test Playlist',
          ),
        ),
        expect: () => [
          isA<XtreamOnboardingInProgress>().having(
              (s) => s.currentStep, 'step', OnboardingStep.authenticating),
          isA<XtreamOnboardingInProgress>().having((s) => s.currentStep, 'step',
              OnboardingStep.fetchingLiveCategories),
          isA<XtreamOnboardingInProgress>().having((s) => s.currentStep, 'step',
              OnboardingStep.fetchingLiveChannels),
          isA<XtreamOnboardingInProgress>().having(
              (s) => s.currentStep, 'step', OnboardingStep.fetchingMovies),
          isA<XtreamOnboardingInProgress>().having(
              (s) => s.currentStep, 'step', OnboardingStep.fetchingSeries),
          isA<XtreamOnboardingInProgress>()
              .having((s) => s.currentStep, 'step', OnboardingStep.fetchingEpg),
          isA<XtreamOnboardingCompleted>(),
        ],
        verify: (_) {
          verify(() => mockApiClient.login(credentials)).called(1);
          verify(() => mockXtreamService.getLiveCategories(credentials,
              forceRefresh: true)).called(1);
          verify(() => mockXtreamService.getMovieCategories(credentials,
              forceRefresh: true)).called(1);
          verify(() => mockXtreamService.getSeriesCategories(credentials,
              forceRefresh: true)).called(1);
          verify(() => mockXtreamService.getLiveChannels(credentials,
              forceRefresh: true)).called(1);
          verify(() =>
                  mockXtreamService.getMovies(credentials, forceRefresh: true))
              .called(1);
          verify(() =>
                  mockXtreamService.getSeries(credentials, forceRefresh: true))
              .called(1);
          verify(() =>
                  mockXtreamService.getEpg(credentials, forceRefresh: true))
              .called(1);
        },
      );

      blocTest<XtreamOnboardingBloc, XtreamOnboardingState>(
        'emits [InProgress, ...steps..., Completed] when series fetching fails (bypassed)',
        setUp: () {
          when(() => mockApiClient.login(credentials)).thenAnswer(
            (_) async => XtreamLoginResponse(
              username: 'testuser',
              password: 'testpass',
              message: 'OK',
              auth: 1,
              status: 'Active',
              serverUrl: 'http://test.server.com:8080',
            ),
          );
          when(() => mockXtreamService.getLiveCategories(credentials,
              forceRefresh: true)).thenAnswer(
            (_) async => [
              const CategoryModel(id: '1', name: 'Sports'),
            ],
          );
          when(() => mockXtreamService.getMovieCategories(credentials,
              forceRefresh: true)).thenAnswer(
            (_) async => [
              const CategoryModel(id: '1', name: 'Action'),
            ],
          );
          // Series categories fail - should be bypassed
          when(() =>
              mockXtreamService.getSeriesCategories(credentials,
                  forceRefresh: true)).thenThrow(Exception(
              'type \'List\' is not a subtype of type \'String?\' in type cast'));
          when(() => mockXtreamService.getLiveChannels(credentials,
              forceRefresh: true)).thenAnswer(
            (_) async => [
              const ChannelModel(id: '1', name: 'Channel 1', streamUrl: 'url1'),
            ],
          );
          when(() =>
                  mockXtreamService.getMovies(credentials, forceRefresh: true))
              .thenAnswer(
            (_) async => [
              const MovieModel(id: '1', name: 'Movie 1', streamUrl: 'url1'),
            ],
          );
          // Series fetch fails - should be bypassed
          when(() =>
              mockXtreamService.getSeries(credentials,
                  forceRefresh: true)).thenThrow(Exception(
              'type \'List\' is not a subtype of type \'String?\' in type cast'));
          when(() => mockXtreamService.getEpg(credentials, forceRefresh: true))
              .thenAnswer((_) async => {});
        },
        build: () => XtreamOnboardingBloc(
          apiClient: mockApiClient,
          xtreamService: mockXtreamService,
        ),
        act: (bloc) => bloc.add(
          StartOnboardingEvent(
            credentials: credentials,
            playlistName: 'Test Playlist',
          ),
        ),
        expect: () => [
          isA<XtreamOnboardingInProgress>().having(
              (s) => s.currentStep, 'step', OnboardingStep.authenticating),
          isA<XtreamOnboardingInProgress>().having((s) => s.currentStep, 'step',
              OnboardingStep.fetchingLiveCategories),
          isA<XtreamOnboardingInProgress>().having((s) => s.currentStep, 'step',
              OnboardingStep.fetchingLiveChannels),
          isA<XtreamOnboardingInProgress>().having(
              (s) => s.currentStep, 'step', OnboardingStep.fetchingMovies),
          isA<XtreamOnboardingInProgress>().having(
              (s) => s.currentStep, 'step', OnboardingStep.fetchingSeries),
          isA<XtreamOnboardingInProgress>()
              .having((s) => s.currentStep, 'step', OnboardingStep.fetchingEpg),
          isA<XtreamOnboardingCompleted>(),
        ],
      );

      blocTest<XtreamOnboardingBloc, XtreamOnboardingState>(
        'emits [InProgress, Error] when authentication fails',
        setUp: () {
          when(() => mockApiClient.login(credentials)).thenAnswer(
            (_) async => XtreamLoginResponse(
              username: 'testuser',
              password: 'testpass',
              message: 'Invalid credentials',
              auth: 0,
              status: 'Expired',
              serverUrl: 'http://test.server.com:8080',
            ),
          );
        },
        build: () => XtreamOnboardingBloc(
          apiClient: mockApiClient,
          xtreamService: mockXtreamService,
        ),
        act: (bloc) => bloc.add(
          StartOnboardingEvent(
            credentials: credentials,
            playlistName: 'Test Playlist',
          ),
        ),
        expect: () => [
          isA<XtreamOnboardingInProgress>().having(
              (s) => s.currentStep, 'step', OnboardingStep.authenticating),
          isA<XtreamOnboardingError>()
              .having((s) => s.failedStep, 'failedStep',
                  OnboardingStep.authenticating)
              .having((s) => s.canRetry, 'canRetry', true),
        ],
      );

      blocTest<XtreamOnboardingBloc, XtreamOnboardingState>(
        'emits [InProgress, Error] when network error occurs',
        setUp: () {
          when(() => mockApiClient.login(credentials))
              .thenThrow(const NetworkException(message: 'Connection refused'));
        },
        build: () => XtreamOnboardingBloc(
          apiClient: mockApiClient,
          xtreamService: mockXtreamService,
        ),
        act: (bloc) => bloc.add(
          StartOnboardingEvent(
            credentials: credentials,
            playlistName: 'Test Playlist',
          ),
        ),
        expect: () => [
          isA<XtreamOnboardingInProgress>().having(
              (s) => s.currentStep, 'step', OnboardingStep.authenticating),
          isA<XtreamOnboardingError>()
              .having((s) => s.message, 'message', contains('Network error')),
        ],
      );
    });

    group('RetryOnboardingEvent', () {
      blocTest<XtreamOnboardingBloc, XtreamOnboardingState>(
        'retries onboarding after failure',
        setUp: () {
          var callCount = 0;
          when(() => mockApiClient.login(credentials)).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw Exception('First attempt failed');
            }
            return XtreamLoginResponse(
              username: 'testuser',
              password: 'testpass',
              message: 'OK',
              auth: 1,
              status: 'Active',
              serverUrl: 'http://test.server.com:8080',
            );
          });
          when(() => mockXtreamService.getLiveCategories(credentials,
              forceRefresh: true)).thenAnswer((_) async => []);
          when(() => mockXtreamService.getMovieCategories(credentials,
              forceRefresh: true)).thenAnswer((_) async => []);
          when(() => mockXtreamService.getSeriesCategories(credentials,
              forceRefresh: true)).thenAnswer((_) async => []);
          when(() => mockXtreamService.getLiveChannels(credentials,
              forceRefresh: true)).thenAnswer((_) async => []);
          when(() =>
                  mockXtreamService.getMovies(credentials, forceRefresh: true))
              .thenAnswer((_) async => []);
          when(() =>
                  mockXtreamService.getSeries(credentials, forceRefresh: true))
              .thenAnswer((_) async => []);
          when(() => mockXtreamService.getEpg(credentials, forceRefresh: true))
              .thenAnswer((_) async => {});
        },
        build: () => XtreamOnboardingBloc(
          apiClient: mockApiClient,
          xtreamService: mockXtreamService,
        ),
        act: (bloc) async {
          bloc.add(
            StartOnboardingEvent(
              credentials: credentials,
              playlistName: 'Test Playlist',
            ),
          );
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const RetryOnboardingEvent());
        },
        skip: 2, // Skip the first error state
        expect: () => [
          isA<XtreamOnboardingInProgress>(),
          isA<XtreamOnboardingInProgress>(),
          isA<XtreamOnboardingInProgress>(),
          isA<XtreamOnboardingInProgress>(),
          isA<XtreamOnboardingInProgress>(),
          isA<XtreamOnboardingInProgress>(),
          isA<XtreamOnboardingCompleted>(),
        ],
      );
    });

    group('CancelOnboardingEvent', () {
      blocTest<XtreamOnboardingBloc, XtreamOnboardingState>(
        'resets state to initial when cancelled',
        build: () => XtreamOnboardingBloc(
          apiClient: mockApiClient,
          xtreamService: mockXtreamService,
        ),
        act: (bloc) => bloc.add(const CancelOnboardingEvent()),
        expect: () => [const XtreamOnboardingInitial()],
      );
    });

    group('OnboardingStep', () {
      test('displayName returns correct values', () {
        expect(
          OnboardingStep.authenticating.displayName,
          'Authenticating...',
        );
        expect(
          OnboardingStep.fetchingLiveChannels.displayName,
          'Fetching Live TV Channels...',
        );
        expect(OnboardingStep.completed.displayName, 'Completed!');
      });

      test('progressPercentage returns correct values', () {
        expect(OnboardingStep.authenticating.progressPercentage, 0.0);
        expect(OnboardingStep.fetchingMovies.progressPercentage, 0.5);
        expect(OnboardingStep.completed.progressPercentage, 1.0);
      });
    });
  });
}

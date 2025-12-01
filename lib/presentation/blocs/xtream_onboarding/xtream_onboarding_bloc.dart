import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/playlist_source.dart';
import '../../../features/xtream/xtream_api_client.dart';
import '../../../features/xtream/xtream_service.dart';

// Onboarding step enum
enum OnboardingStep {
  authenticating,
  fetchingLiveCategories,
  fetchingLiveChannels,
  fetchingMovieCategories,
  fetchingMovies,
  fetchingSeriesCategories,
  fetchingSeries,
  fetchingEpg,
  completed,
}

extension OnboardingStepExtension on OnboardingStep {
  String get displayName {
    switch (this) {
      case OnboardingStep.authenticating:
        return 'Authenticating...';
      case OnboardingStep.fetchingLiveCategories:
        return 'Fetching Live TV Categories...';
      case OnboardingStep.fetchingLiveChannels:
        return 'Fetching Live TV Channels...';
      case OnboardingStep.fetchingMovieCategories:
        return 'Fetching Movie Categories...';
      case OnboardingStep.fetchingMovies:
        return 'Fetching Movies...';
      case OnboardingStep.fetchingSeriesCategories:
        return 'Fetching Series Categories...';
      case OnboardingStep.fetchingSeries:
        return 'Fetching Series...';
      case OnboardingStep.fetchingEpg:
        return 'Fetching EPG Data...';
      case OnboardingStep.completed:
        return 'Completed!';
    }
  }

  double get progressPercentage {
    switch (this) {
      case OnboardingStep.authenticating:
        return 0.0;
      case OnboardingStep.fetchingLiveCategories:
        return 0.125;
      case OnboardingStep.fetchingLiveChannels:
        return 0.25;
      case OnboardingStep.fetchingMovieCategories:
        return 0.375;
      case OnboardingStep.fetchingMovies:
        return 0.5;
      case OnboardingStep.fetchingSeriesCategories:
        return 0.625;
      case OnboardingStep.fetchingSeries:
        return 0.75;
      case OnboardingStep.fetchingEpg:
        return 0.875;
      case OnboardingStep.completed:
        return 1.0;
    }
  }
}

// Events
abstract class XtreamOnboardingEvent extends Equatable {
  const XtreamOnboardingEvent();

  @override
  List<Object?> get props => [];
}

class StartOnboardingEvent extends XtreamOnboardingEvent {
  final XtreamCredentials credentials;
  final String playlistName;

  const StartOnboardingEvent({
    required this.credentials,
    required this.playlistName,
  });

  @override
  List<Object?> get props => [credentials, playlistName];
}

class RetryOnboardingEvent extends XtreamOnboardingEvent {
  const RetryOnboardingEvent();
}

class CancelOnboardingEvent extends XtreamOnboardingEvent {
  const CancelOnboardingEvent();
}

// States
abstract class XtreamOnboardingState extends Equatable {
  const XtreamOnboardingState();

  @override
  List<Object?> get props => [];
}

class XtreamOnboardingInitial extends XtreamOnboardingState {
  const XtreamOnboardingInitial();
}

class XtreamOnboardingInProgress extends XtreamOnboardingState {
  final OnboardingStep currentStep;
  final String statusMessage;
  final int itemsLoaded;
  final String? currentItemName;
  final List<OnboardingStepResult> completedSteps;

  const XtreamOnboardingInProgress({
    required this.currentStep,
    required this.statusMessage,
    this.itemsLoaded = 0,
    this.currentItemName,
    this.completedSteps = const [],
  });

  double get progress => currentStep.progressPercentage;

  @override
  List<Object?> get props => [
        currentStep,
        statusMessage,
        itemsLoaded,
        currentItemName,
        completedSteps,
      ];
}

class XtreamOnboardingCompleted extends XtreamOnboardingState {
  final OnboardingResult result;

  const XtreamOnboardingCompleted(this.result);

  @override
  List<Object?> get props => [result];
}

class XtreamOnboardingError extends XtreamOnboardingState {
  final String message;
  final OnboardingStep failedStep;
  final bool canRetry;

  const XtreamOnboardingError({
    required this.message,
    required this.failedStep,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, failedStep, canRetry];
}

// Data classes
class OnboardingStepResult extends Equatable {
  final OnboardingStep step;
  final bool success;
  final int itemCount;
  final String? errorMessage;

  const OnboardingStepResult({
    required this.step,
    required this.success,
    this.itemCount = 0,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [step, success, itemCount, errorMessage];
}

class OnboardingResult extends Equatable {
  final int liveCategories;
  final int liveChannels;
  final int movieCategories;
  final int movies;
  final int seriesCategories;
  final int series;
  final int epgChannels;
  final DateTime completedAt;

  const OnboardingResult({
    required this.liveCategories,
    required this.liveChannels,
    required this.movieCategories,
    required this.movies,
    required this.seriesCategories,
    required this.series,
    required this.epgChannels,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [
        liveCategories,
        liveChannels,
        movieCategories,
        movies,
        seriesCategories,
        series,
        epgChannels,
        completedAt,
      ];
}

// BLoC
class XtreamOnboardingBloc
    extends Bloc<XtreamOnboardingEvent, XtreamOnboardingState> {
  final XtreamApiClient _apiClient;
  final XtreamService _xtreamService;

  XtreamCredentials? _currentCredentials;
  String? _currentPlaylistName;

  XtreamOnboardingBloc({
    required XtreamApiClient apiClient,
    required XtreamService xtreamService,
  })  : _apiClient = apiClient,
        _xtreamService = xtreamService,
        super(const XtreamOnboardingInitial()) {
    on<StartOnboardingEvent>(_onStartOnboarding);
    on<RetryOnboardingEvent>(_onRetryOnboarding);
    on<CancelOnboardingEvent>(_onCancelOnboarding);
  }

  Future<void> _onStartOnboarding(
    StartOnboardingEvent event,
    Emitter<XtreamOnboardingState> emit,
  ) async {
    _currentCredentials = event.credentials;
    _currentPlaylistName = event.playlistName;

    await _performOnboarding(emit);
  }

  Future<void> _onRetryOnboarding(
    RetryOnboardingEvent event,
    Emitter<XtreamOnboardingState> emit,
  ) async {
    if (_currentCredentials != null) {
      await _performOnboarding(emit);
    }
  }

  Future<void> _onCancelOnboarding(
    CancelOnboardingEvent event,
    Emitter<XtreamOnboardingState> emit,
  ) async {
    emit(const XtreamOnboardingInitial());
    _currentCredentials = null;
    _currentPlaylistName = null;
  }

  /// Delay between API requests to avoid rate limiting (in milliseconds)
  static const int _requestDelayMs = 100;

  /// Helper method to add a small delay between API requests
  Future<void> _rateLimitDelay() async {
    await Future.delayed(const Duration(milliseconds: _requestDelayMs));
  }

  Future<void> _performOnboarding(Emitter<XtreamOnboardingState> emit) async {
    final credentials = _currentCredentials!;
    final completedSteps = <OnboardingStepResult>[];

    int liveCategories = 0;
    int liveChannels = 0;
    int movieCategories = 0;
    int movies = 0;
    int seriesCategories = 0;
    int series = 0;
    int epgChannels = 0;

    try {
      // Step 1: Authenticate
      emit(XtreamOnboardingInProgress(
        currentStep: OnboardingStep.authenticating,
        statusMessage: 'Verifying credentials...',
        completedSteps: completedSteps,
      ));

      AppLogger.info('Starting Xtream onboarding for ${credentials.username}');

      final loginResponse = await _apiClient.login(credentials);
      if (!loginResponse.isAuthenticated) {
        throw Exception('Authentication failed: ${loginResponse.message}');
      }

      completedSteps.add(const OnboardingStepResult(
        step: OnboardingStep.authenticating,
        success: true,
        itemCount: 1,
      ));

      AppLogger.info('Authentication successful');

      // Step 2: Fetch all categories in parallel (smart batching)
      // This reduces 3 sequential API calls to 3 parallel calls
      emit(XtreamOnboardingInProgress(
        currentStep: OnboardingStep.fetchingLiveCategories,
        statusMessage: 'Loading all categories...',
        completedSteps: List.from(completedSteps),
      ));

      await _rateLimitDelay();
      
      // Fetch all three category types in parallel using XtreamService
      // The service caches the results for later use
      final categoriesResults = await Future.wait([
        _xtreamService.getLiveCategories(credentials, forceRefresh: true),
        _xtreamService.getMovieCategories(credentials, forceRefresh: true),
        _xtreamService.getSeriesCategories(credentials, forceRefresh: true),
      ]);

      final liveCategoriesList = categoriesResults[0];
      final movieCategoriesList = categoriesResults[1];
      final seriesCategoriesList = categoriesResults[2];

      liveCategories = liveCategoriesList.length;
      movieCategories = movieCategoriesList.length;
      seriesCategories = seriesCategoriesList.length;

      completedSteps.add(OnboardingStepResult(
        step: OnboardingStep.fetchingLiveCategories,
        success: true,
        itemCount: liveCategories,
      ));

      AppLogger.info('Loaded $liveCategories live categories');

      // Mark movie and series categories as completed too
      completedSteps.add(OnboardingStepResult(
        step: OnboardingStep.fetchingMovieCategories,
        success: true,
        itemCount: movieCategories,
      ));

      AppLogger.info('Loaded $movieCategories movie categories');

      completedSteps.add(OnboardingStepResult(
        step: OnboardingStep.fetchingSeriesCategories,
        success: true,
        itemCount: seriesCategories,
      ));

      AppLogger.info('Loaded $seriesCategories series categories');

      // Step 3: Fetch Live Channels
      emit(XtreamOnboardingInProgress(
        currentStep: OnboardingStep.fetchingLiveChannels,
        statusMessage: 'Loading Live TV channels...',
        completedSteps: List.from(completedSteps),
      ));

      await _rateLimitDelay();

      // Use XtreamService which caches the results
      final liveChannelsList = await _xtreamService.getLiveChannels(
        credentials,
        forceRefresh: true,
      );
      liveChannels = liveChannelsList.length;

      completedSteps.add(OnboardingStepResult(
        step: OnboardingStep.fetchingLiveChannels,
        success: true,
        itemCount: liveChannels,
      ));

      AppLogger.info('Loaded $liveChannels live channels');

      // Step 4: Fetch Movies
      emit(XtreamOnboardingInProgress(
        currentStep: OnboardingStep.fetchingMovies,
        statusMessage: 'Loading movies...',
        completedSteps: List.from(completedSteps),
      ));

      await _rateLimitDelay();

      // Use XtreamService which caches the results
      final moviesList = await _xtreamService.getMovies(
        credentials,
        forceRefresh: true,
      );
      movies = moviesList.length;

      completedSteps.add(OnboardingStepResult(
        step: OnboardingStep.fetchingMovies,
        success: true,
        itemCount: movies,
      ));

      AppLogger.info('Loaded $movies movies');

      // Step 5: Fetch Series
      emit(XtreamOnboardingInProgress(
        currentStep: OnboardingStep.fetchingSeries,
        statusMessage: 'Loading series...',
        completedSteps: List.from(completedSteps),
      ));

      await _rateLimitDelay();

      // Use XtreamService which caches the results
      final seriesList = await _xtreamService.getSeries(
        credentials,
        forceRefresh: true,
      );
      series = seriesList.length;

      completedSteps.add(OnboardingStepResult(
        step: OnboardingStep.fetchingSeries,
        success: true,
        itemCount: series,
      ));

      AppLogger.info('Loaded $series series');

      // Step 6: Fetch EPG (optional, may fail on some providers)
      emit(XtreamOnboardingInProgress(
        currentStep: OnboardingStep.fetchingEpg,
        statusMessage: 'Loading EPG data...',
        completedSteps: List.from(completedSteps),
      ));

      await _rateLimitDelay();

      try {
        // Use XtreamService for EPG - it fetches and caches the results
        final epgData = await _xtreamService.getEpg(
          credentials,
          forceRefresh: true,
        );
        epgChannels = epgData.length;
        completedSteps.add(OnboardingStepResult(
          step: OnboardingStep.fetchingEpg,
          success: true,
          itemCount: epgChannels,
        ));
        AppLogger.info('Loaded EPG for $epgChannels channels');
      } catch (e) {
        // EPG is optional, log but don't fail
        AppLogger.warning('EPG data not available: $e');
        completedSteps.add(OnboardingStepResult(
          step: OnboardingStep.fetchingEpg,
          success: false,
          itemCount: 0,
          errorMessage: 'EPG data not available',
        ));
      }

      // Note: We no longer call fullRefresh() here because all data
      // has already been fetched and cached via XtreamService methods above.
      // This eliminates 5 duplicate API calls that were previously made.

      // Complete
      final result = OnboardingResult(
        liveCategories: liveCategories,
        liveChannels: liveChannels,
        movieCategories: movieCategories,
        movies: movies,
        seriesCategories: seriesCategories,
        series: series,
        epgChannels: epgChannels,
        completedAt: DateTime.now(),
      );

      AppLogger.info(
        'Xtream onboarding completed: '
        '$liveChannels channels, $movies movies, $series series',
      );

      emit(XtreamOnboardingCompleted(result));
    } catch (e, stackTrace) {
      final currentStep = _getCurrentStep(completedSteps);
      AppLogger.error(
        'Xtream onboarding failed at step: ${currentStep.displayName}',
        e,
        stackTrace,
      );

      emit(XtreamOnboardingError(
        message: _formatErrorMessage(e),
        failedStep: currentStep,
        canRetry: true,
      ));
    }
  }

  OnboardingStep _getCurrentStep(List<OnboardingStepResult> completedSteps) {
    if (completedSteps.isEmpty) return OnboardingStep.authenticating;

    final lastCompleted = completedSteps.last.step;
    final stepIndex = OnboardingStep.values.indexOf(lastCompleted);

    if (stepIndex < OnboardingStep.values.length - 1) {
      return OnboardingStep.values[stepIndex + 1];
    }

    return OnboardingStep.completed;
  }

  String _formatErrorMessage(dynamic error) {
    // Check for specific exception types first
    if (error is NetworkException) {
      return 'Network error. Please check your internet connection.';
    }
    if (error is AuthException) {
      return 'Invalid credentials. Please check your username and password.';
    }
    if (error is ServerException) {
      final statusCode = error.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return 'Access denied. Please verify your subscription is active.';
      }
      return error.message;
    }
    if (error is AppException) {
      return error.message;
    }
    if (error is SocketException) {
      return 'Network error. Please check your internet connection.';
    }
    if (error is TimeoutException) {
      return 'Connection timed out. The server may be slow or unreachable.';
    }

    // Fallback to string matching for unknown exceptions
    final message = error.toString();
    if (message.contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    }
    if (message.contains('TimeoutException')) {
      return 'Connection timed out. The server may be slow or unreachable.';
    }
    // Return a cleaned up message
    return message.replaceAll('Exception: ', '');
  }
}

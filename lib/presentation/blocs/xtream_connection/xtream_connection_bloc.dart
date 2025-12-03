// Xtream Connection BLoC
// Business logic component for Xtream connection progress.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../modules/core/logging/app_logger.dart';
import '../../../modules/core/models/api_result.dart';
import '../../../modules/xtreamcodes/account/xtream_api_client.dart';
import '../../../modules/xtreamcodes/auth/xtream_auth_service.dart';
import '../../../modules/xtreamcodes/auth/xtream_credentials.dart';
import '../../../modules/xtreamcodes/xtream_service_manager.dart';
import 'xtream_connection_event.dart';
import 'xtream_connection_state.dart';

/// Xtream connection progress BLoC
class XtreamConnectionBloc
    extends Bloc<XtreamConnectionEvent, XtreamConnectionState> {
  XtreamConnectionBloc({
    required IXtreamAuthService authService,
    required XtreamServiceManager serviceManager,
  })  : _authService = authService,
        _serviceManager = serviceManager,
        super(const XtreamConnectionInitial()) {
    on<XtreamConnectionStarted>(_onConnectionStarted);
    on<XtreamConnectionRetry>(_onConnectionRetry);
    on<XtreamConnectionReset>(_onConnectionReset);
  }

  final IXtreamAuthService _authService;
  final XtreamServiceManager _serviceManager;

  /// Track loaded content counts
  int _channelsLoaded = 0;
  int _moviesLoaded = 0;
  int _seriesLoaded = 0;

  /// Handle connection started
  Future<void> _onConnectionStarted(
    XtreamConnectionStarted event,
    Emitter<XtreamConnectionState> emit,
  ) async {
    await _performConnection(event.credentials, emit);
  }

  /// Handle connection retry
  Future<void> _onConnectionRetry(
    XtreamConnectionRetry event,
    Emitter<XtreamConnectionState> emit,
  ) async {
    // Reset counts on retry
    _channelsLoaded = 0;
    _moviesLoaded = 0;
    _seriesLoaded = 0;
    await _performConnection(event.credentials, emit);
  }

  /// Perform the connection process
  Future<void> _performConnection(
    XtreamCredentials credentials,
    Emitter<XtreamConnectionState> emit,
  ) async {
    try {
      moduleLogger.info(
        'Starting Xtream connection process',
        tag: 'XtreamConnection',
      );

      // Step 1: Validate credentials format
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.validatingCredentials,
        progress: 0.05,
        message: 'Validating your credentials...',
      ));

      final validation = _authService.validateCredentials(credentials);
      if (validation.isFailure) {
        moduleLogger.error(
          'Credentials validation failed',
          tag: 'XtreamConnection',
          error: validation.error,
        );
        emit(XtreamConnectionError(
          message: validation.error.message,
          failedStep: ConnectionStep.validatingCredentials,
          errorType: ConnectionErrorType.invalidCredentials,
          canRetry: false,
        ));
        return;
      }

      // Step 2: Test connection
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.testingConnection,
        progress: 0.1,
        message: 'Testing connection to server...',
      ));

      final apiClient = XtreamApiClient(credentials: credentials);

      // Step 3: Authenticate
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.authenticating,
        progress: 0.15,
        message: 'Authenticating with server...',
      ));

      final authResult = await apiClient.authenticate();

      if (authResult.isFailure) {
        moduleLogger.error(
          'Authentication failed',
          tag: 'XtreamConnection',
          error: authResult.error,
        );

        final errorType = _mapApiErrorToConnectionError(authResult.error);
        emit(XtreamConnectionError(
          message: _getErrorMessage(authResult.error, errorType),
          failedStep: ConnectionStep.authenticating,
          errorType: errorType,
          canRetry: errorType != ConnectionErrorType.authenticationFailed &&
              errorType != ConnectionErrorType.accountExpired,
        ));
        return;
      }

      // Null check for authResult.data
      final authResponse = authResult.data;
      // ignore: unnecessary_null_comparison
      if (authResponse == null) {
        emit(const XtreamConnectionError(
          message: 'Invalid authentication response from server.',
          failedStep: ConnectionStep.authenticating,
          errorType: ConnectionErrorType.serverError,
        ));
        return;
      }

      // Check if account is active
      if (!authResponse.userInfo.isActive) {
        moduleLogger.warning(
          'Account is not active',
          tag: 'XtreamConnection',
        );
        emit(const XtreamConnectionError(
          message: 'Your account is not active or has expired. '
              'Please contact your IPTV provider.',
          failedStep: ConnectionStep.authenticating,
          errorType: ConnectionErrorType.accountExpired,
          canRetry: false,
        ));
        return;
      }

      // Step 4: Save credentials
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.savingCredentials,
        progress: 0.25,
        message: 'Saving your credentials...',
      ));

      final saveResult = await _authService.saveCredentials(credentials);
      if (saveResult.isFailure) {
        emit(XtreamConnectionError(
          message: 'Failed to save credentials: ${saveResult.error.message}',
          failedStep: ConnectionStep.savingCredentials,
          errorType: _mapApiErrorToConnectionError(saveResult.error),
        ));
        return;
      }

      // Initialize service manager
      await _serviceManager.initialize(credentials);

      // Step 5: Start fetching content progressively (non-blocking approach)
      // Fetch first batch of channels to show immediate results
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingChannels,
        progress: 0.3,
        message: 'Loading live TV channels...',
      ));

      // Start all content fetches in parallel for faster loading
      final channelsFuture = apiClient.getLiveStreams();
      final moviesFuture = apiClient.getVodStreams();
      final seriesFuture = apiClient.getSeries();

      // Wait for channels first (most important for IPTV)
      final liveStreamsResult = await channelsFuture;
      if (liveStreamsResult.isSuccess) {
        _channelsLoaded = liveStreamsResult.data.length;
        moduleLogger.info(
          'Successfully fetched $_channelsLoaded live channels',
          tag: 'XtreamConnection',
        );
      } else {
        moduleLogger.warning(
          'Failed to fetch live channels',
          tag: 'XtreamConnection',
          error: liveStreamsResult.error,
        );
        // Continue even if channels fail - user may only want VOD
      }

      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingChannels,
        progress: 0.45,
        message: 'Live channels loaded! Loading movies...',
        channelsLoaded: _channelsLoaded,
      ));

      // Check movies progress
      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingMovies,
        progress: 0.5,
        message: 'Loading movies catalog...',
        channelsLoaded: _channelsLoaded,
      ));

      final vodStreamsResult = await moviesFuture;
      if (vodStreamsResult.isSuccess) {
        _moviesLoaded = vodStreamsResult.data.length;
        moduleLogger.info(
          'Successfully fetched $_moviesLoaded movies',
          tag: 'XtreamConnection',
        );
      } else {
        moduleLogger.warning(
          'Failed to fetch movies',
          tag: 'XtreamConnection',
          error: vodStreamsResult.error,
        );
        // Continue even if movies fail - user may only want live TV
      }

      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingMovies,
        progress: 0.65,
        message: 'Movies loaded! Loading series...',
        channelsLoaded: _channelsLoaded,
        moviesLoaded: _moviesLoaded,
      ));

      // Check series progress
      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingSeries,
        progress: 0.7,
        message: 'Loading TV series catalog...',
        channelsLoaded: _channelsLoaded,
        moviesLoaded: _moviesLoaded,
      ));

      final seriesResult = await seriesFuture;
      if (seriesResult.isSuccess) {
        _seriesLoaded = seriesResult.data.length;
        moduleLogger.info(
          'Successfully fetched $_seriesLoaded series',
          tag: 'XtreamConnection',
        );
      } else {
        moduleLogger.warning(
          'Failed to fetch series',
          tag: 'XtreamConnection',
          error: seriesResult.error,
        );
        // Continue even if series fail - user may not need them
      }

      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingSeries,
        progress: 0.85,
        message: 'All content loaded! Preparing EPG...',
        channelsLoaded: _channelsLoaded,
        moviesLoaded: _moviesLoaded,
        seriesLoaded: _seriesLoaded,
      ));

      // Step 8: Start EPG refresh in background (non-blocking)
      // EPG will continue loading in the background while user explores content
      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.updatingEpg,
        progress: 0.95,
        message: 'Starting EPG in background... Ready to watch!',
        channelsLoaded: _channelsLoaded,
        moviesLoaded: _moviesLoaded,
        seriesLoaded: _seriesLoaded,
      ));

      // Start EPG refresh in background - fire and forget
      _refreshEpgInBackground();

      // Step 9: Completed - User can now navigate immediately
      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.completed,
        progress: 1.0,
        message: 'All set! EPG updating in background...',
        channelsLoaded: _channelsLoaded,
        moviesLoaded: _moviesLoaded,
        seriesLoaded: _seriesLoaded,
      ));

      // Small delay before showing success
      await Future.delayed(const Duration(milliseconds: 500));

      moduleLogger.info(
        'Xtream connection completed successfully',
        tag: 'XtreamConnection',
      );
      emit(XtreamConnectionSuccess(
        channelsLoaded: _channelsLoaded,
        moviesLoaded: _moviesLoaded,
        seriesLoaded: _seriesLoaded,
      ));
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Unexpected error during connection',
        tag: 'XtreamConnection',
        error: e,
        stackTrace: stackTrace,
      );
      emit(XtreamConnectionError(
        message: 'An unexpected error occurred. Please try again.',
        failedStep: ConnectionStep.testingConnection,
        errorType: ConnectionErrorType.unknown,
        canRetry: true,
      ));
    }
  }

  /// Refresh EPG data in background without blocking UI navigation
  /// This is the only operation that should run in background after setup
  void _refreshEpgInBackground() {
    // Only run if service is initialized
    if (!_serviceManager.isInitialized) {
      moduleLogger.warning(
        'Service manager not initialized, skipping background EPG refresh',
        tag: 'XtreamConnection',
      );
      return;
    }

    // Fire and forget - don't await, let it run in background
    _serviceManager.repositoryFactory.epgRepository.refreshEpg().then(
      (result) {
        if (result.isSuccess) {
          moduleLogger.info(
            'Background: EPG refreshed successfully',
            tag: 'XtreamConnection',
          );
        } else {
          moduleLogger.warning(
            'Background: EPG refresh failed, will retry later',
            tag: 'XtreamConnection',
            error: result.error,
          );
        }
      },
    ).catchError((error, stackTrace) {
      moduleLogger.error(
        'Background: Error during EPG refresh',
        tag: 'XtreamConnection',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  /// Map API error to connection error type
  ConnectionErrorType _mapApiErrorToConnectionError(ApiError error) {
    switch (error.type) {
      case ApiErrorType.network:
        return ConnectionErrorType.networkError;
      case ApiErrorType.server:
        return ConnectionErrorType.serverError;
      case ApiErrorType.auth:
        return ConnectionErrorType.authenticationFailed;
      case ApiErrorType.timeout:
        return ConnectionErrorType.timeout;
      case ApiErrorType.validation:
        return ConnectionErrorType.invalidCredentials;
      default:
        return ConnectionErrorType.unknown;
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(ApiError error, ConnectionErrorType errorType) {
    switch (errorType) {
      case ConnectionErrorType.networkError:
        return 'Unable to connect to the server. '
            'Please check your internet connection and try again.';
      case ConnectionErrorType.serverError:
        return 'The server is not responding. '
            'Please verify your server URL and try again.';
      case ConnectionErrorType.authenticationFailed:
        return 'Authentication failed. '
            'Please check your username and password.';
      case ConnectionErrorType.timeout:
        return 'Connection timed out. '
            'The server took too long to respond. Please try again.';
      case ConnectionErrorType.invalidCredentials:
        return error.message;
      case ConnectionErrorType.accountExpired:
        return 'Your account is not active or has expired. '
            'Please contact your IPTV provider.';
      default:
        return error.message.isNotEmpty
            ? error.message
            : 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handle connection reset
  Future<void> _onConnectionReset(
    XtreamConnectionReset event,
    Emitter<XtreamConnectionState> emit,
  ) async {
    _channelsLoaded = 0;
    _moviesLoaded = 0;
    _seriesLoaded = 0;
    emit(const XtreamConnectionInitial());
  }
}

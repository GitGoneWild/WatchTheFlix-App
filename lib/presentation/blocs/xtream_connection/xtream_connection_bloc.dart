// Xtream Connection BLoC
// Business logic component for Xtream connection progress.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../modules/core/logging/app_logger.dart';
import '../../../modules/core/models/api_result.dart';
import '../../../modules/xtreamcodes/account/xtream_api_client.dart';
import '../../../modules/xtreamcodes/auth/xtream_auth_service.dart';
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
    dynamic credentials,
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

      // Check if account is active
      final authResponse = authResult.data;
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

      await _authService.saveCredentials(credentials);

      // Initialize service manager
      await _serviceManager.initialize(credentials);

      // Step 5: Fetch live channels
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingChannels,
        progress: 0.35,
        message: 'Loading live TV channels...',
      ));

      final categoriesResult = await apiClient.getLiveCategories();
      if (categoriesResult.isSuccess) {
        _channelsLoaded = categoriesResult.data.length;
        moduleLogger.info(
          'Successfully fetched $_channelsLoaded live categories',
          tag: 'XtreamConnection',
        );
        emit(XtreamConnectionInProgress(
          currentStep: ConnectionStep.fetchingChannels,
          progress: 0.45,
          message: 'Found $_channelsLoaded channel categories',
          channelsLoaded: _channelsLoaded,
        ));
      } else {
        moduleLogger.warning(
          'Failed to fetch live categories, continuing anyway',
          tag: 'XtreamConnection',
          error: categoriesResult.error,
        );
      }

      // Step 6: Fetch movies
      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingMovies,
        progress: 0.55,
        message: 'Loading movies...',
        channelsLoaded: _channelsLoaded,
      ));

      final vodCategoriesResult = await apiClient.getVodCategories();
      if (vodCategoriesResult.isSuccess) {
        _moviesLoaded = vodCategoriesResult.data.length;
        moduleLogger.info(
          'Successfully fetched $_moviesLoaded VOD categories',
          tag: 'XtreamConnection',
        );
        emit(XtreamConnectionInProgress(
          currentStep: ConnectionStep.fetchingMovies,
          progress: 0.65,
          message: 'Found $_moviesLoaded movie categories',
          channelsLoaded: _channelsLoaded,
          moviesLoaded: _moviesLoaded,
        ));
      } else {
        moduleLogger.warning(
          'Failed to fetch VOD categories, continuing anyway',
          tag: 'XtreamConnection',
          error: vodCategoriesResult.error,
        );
      }

      // Step 7: Fetch series
      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingSeries,
        progress: 0.75,
        message: 'Loading series...',
        channelsLoaded: _channelsLoaded,
        moviesLoaded: _moviesLoaded,
      ));

      final seriesCategoriesResult = await apiClient.getSeriesCategories();
      if (seriesCategoriesResult.isSuccess) {
        _seriesLoaded = seriesCategoriesResult.data.length;
        moduleLogger.info(
          'Successfully fetched $_seriesLoaded series categories',
          tag: 'XtreamConnection',
        );
        emit(XtreamConnectionInProgress(
          currentStep: ConnectionStep.fetchingSeries,
          progress: 0.85,
          message: 'Found $_seriesLoaded series categories',
          channelsLoaded: _channelsLoaded,
          moviesLoaded: _moviesLoaded,
          seriesLoaded: _seriesLoaded,
        ));
      } else {
        moduleLogger.warning(
          'Failed to fetch series categories, continuing anyway',
          tag: 'XtreamConnection',
          error: seriesCategoriesResult.error,
        );
      }

      // Step 8: Update EPG (non-blocking)
      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.updatingEpg,
        progress: 0.9,
        message: 'Updating program guide...',
        channelsLoaded: _channelsLoaded,
        moviesLoaded: _moviesLoaded,
        seriesLoaded: _seriesLoaded,
      ));

      // Trigger EPG refresh in background (don't wait for it to complete)
      if (_serviceManager.isInitialized) {
        _serviceManager.repositoryFactory.epgRepository.refreshEpg().then(
          (result) {
            if (result.isSuccess) {
              moduleLogger.info(
                'EPG refreshed successfully',
                tag: 'XtreamConnection',
              );
            } else {
              moduleLogger.warning(
                'EPG refresh failed, will retry later',
                tag: 'XtreamConnection',
                error: result.error,
              );
            }
          },
        ).catchError((error, stackTrace) {
          moduleLogger.error(
            'Error during EPG refresh',
            tag: 'XtreamConnection',
            error: error,
            stackTrace: stackTrace,
          );
        });
      }

      // Step 9: Completed
      emit(XtreamConnectionInProgress(
        currentStep: ConnectionStep.completed,
        progress: 1.0,
        message: 'Setup complete!',
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

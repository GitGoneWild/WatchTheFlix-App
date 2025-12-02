// Xtream Connection BLoC
// Business logic component for Xtream connection progress.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../modules/core/logging/app_logger.dart';
import '../../../modules/xtreamcodes/account/xtream_api_client.dart';
import '../../../modules/xtreamcodes/auth/xtream_auth_service.dart';
import 'xtream_connection_event.dart';
import 'xtream_connection_state.dart';

/// Xtream connection progress BLoC
class XtreamConnectionBloc
    extends Bloc<XtreamConnectionEvent, XtreamConnectionState> {
  XtreamConnectionBloc({
    required IXtreamAuthService authService,
  })  : _authService = authService,
        super(const XtreamConnectionInitial()) {
    on<XtreamConnectionStarted>(_onConnectionStarted);
    on<XtreamConnectionReset>(_onConnectionReset);
  }

  final IXtreamAuthService _authService;

  /// Handle connection started
  Future<void> _onConnectionStarted(
    XtreamConnectionStarted event,
    Emitter<XtreamConnectionState> emit,
  ) async {
    try {
      moduleLogger.info('Starting Xtream connection process', tag: 'XtreamConnection');

      // Step 1: Test connection
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.testingConnection,
        progress: 0.2,
        message: 'Testing connection to server...',
      ));

      final apiClient = XtreamApiClient(credentials: event.credentials);
      final authResult = await apiClient.authenticate();

      if (authResult.isFailure) {
        moduleLogger.error(
          'Connection test failed',
          tag: 'XtreamConnection',
          error: authResult.error,
        );
        emit(XtreamConnectionError(
          message: authResult.error.message,
          failedStep: ConnectionStep.testingConnection,
        ));
        return;
      }

      // Save credentials after successful test
      await _authService.saveCredentials(event.credentials);

      // Step 2: Fetch live channels
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingChannels,
        progress: 0.4,
        message: 'Loading live TV channels...',
      ));

      final categoriesResult = await apiClient.getLiveCategories();
      // Continue even if this fails - it's not critical

      // Step 3: Fetch movies
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingMovies,
        progress: 0.6,
        message: 'Loading movies...',
      ));

      final vodCategoriesResult = await apiClient.getVodCategories();
      // Continue even if this fails - it's not critical

      // Step 4: Fetch series (optional)
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.fetchingSeries,
        progress: 0.75,
        message: 'Loading series...',
      ));

      final seriesCategoriesResult = await apiClient.getSeriesCategories();
      // Series fetching is optional, continue even if it fails

      // Step 5: Update EPG
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.updatingEpg,
        progress: 0.9,
        message: 'Updating program guide...',
      ));

      // EPG fetching is done in background - don't block on it
      // The EPG repository will handle this when content is accessed

      // Step 6: Completed
      emit(const XtreamConnectionInProgress(
        currentStep: ConnectionStep.completed,
        progress: 1.0,
        message: 'Setup complete!',
      ));

      // Small delay before showing success
      await Future.delayed(const Duration(milliseconds: 500));

      moduleLogger.info('Xtream connection completed successfully', tag: 'XtreamConnection');
      emit(const XtreamConnectionSuccess());
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Unexpected error during connection',
        tag: 'XtreamConnection',
        error: e,
        stackTrace: stackTrace,
      );
      emit(XtreamConnectionError(
        message: 'An unexpected error occurred: $e',
        failedStep: ConnectionStep.testingConnection,
      ));
    }
  }

  /// Handle connection reset
  Future<void> _onConnectionReset(
    XtreamConnectionReset event,
    Emitter<XtreamConnectionState> emit,
  ) async {
    emit(const XtreamConnectionInitial());
  }
}

// Xtream Auth BLoC
// Business logic component for Xtream authentication.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../modules/core/logging/app_logger.dart';
import '../../../modules/xtreamcodes/account/xtream_api_client.dart';
import '../../../modules/xtreamcodes/auth/xtream_auth_service.dart';
import '../../../modules/xtreamcodes/auth/xtream_credentials.dart';
import 'xtream_auth_event.dart';
import 'xtream_auth_state.dart';

/// Xtream authentication BLoC
class XtreamAuthBloc extends Bloc<XtreamAuthEvent, XtreamAuthState> {
  XtreamAuthBloc({
    required IXtreamAuthService authService,
  })  : _authService = authService,
        super(const XtreamAuthInitial()) {
    on<XtreamAuthLoginRequested>(_onLoginRequested);
    on<XtreamAuthLoadCredentials>(_onLoadCredentials);
    on<XtreamAuthLogoutRequested>(_onLogoutRequested);
    on<XtreamAuthValidateCredentials>(_onValidateCredentials);
  }

  final IXtreamAuthService _authService;

  /// Handle login request
  Future<void> _onLoginRequested(
    XtreamAuthLoginRequested event,
    Emitter<XtreamAuthState> emit,
  ) async {
    emit(const XtreamAuthLoading());

    try {
      // Create credentials
      final credentials = XtreamCredentials.fromUrl(
        serverUrl: event.serverUrl,
        username: event.username,
        password: event.password,
      );

      // Validate credentials format
      final validation = _authService.validateCredentials(credentials);
      if (validation.isFailure) {
        emit(XtreamAuthValidationError(message: validation.error.message));
        return;
      }

      moduleLogger.info('Attempting Xtream login', tag: 'XtreamAuth');

      // Create API client and authenticate
      final apiClient = XtreamApiClient(credentials: credentials);
      final authResult = await apiClient.authenticate();

      if (authResult.isFailure) {
        moduleLogger.error(
          'Xtream authentication failed',
          tag: 'XtreamAuth',
          error: authResult.error,
        );
        emit(XtreamAuthError(message: authResult.error.message));
        return;
      }

      final authResponse = authResult.data;

      // Check if account is active
      if (!authResponse.userInfo.isActive) {
        emit(const XtreamAuthError(
          message: 'Account is not active or has expired',
        ));
        return;
      }

      // Save credentials
      final saveResult = await _authService.saveCredentials(credentials);
      if (saveResult.isFailure) {
        moduleLogger.warning(
          'Failed to save credentials',
          tag: 'XtreamAuth',
          error: saveResult.error,
        );
      }

      moduleLogger.info('Xtream authentication successful', tag: 'XtreamAuth');

      emit(XtreamAuthAuthenticated(
        credentials: credentials,
        userInfo: authResponse.userInfo,
        serverInfo: authResponse.serverInfo,
      ));
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Unexpected error during login',
        tag: 'XtreamAuth',
        error: e,
        stackTrace: stackTrace,
      );
      emit(XtreamAuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  /// Handle load credentials
  Future<void> _onLoadCredentials(
    XtreamAuthLoadCredentials event,
    Emitter<XtreamAuthState> emit,
  ) async {
    emit(const XtreamAuthLoading());

    try {
      moduleLogger.info('Loading saved credentials', tag: 'XtreamAuth');

      final credentialsResult = await _authService.loadCredentials();

      if (credentialsResult.isFailure) {
        moduleLogger.info('No saved credentials found', tag: 'XtreamAuth');
        emit(const XtreamAuthUnauthenticated());
        return;
      }

      final credentials = credentialsResult.data;

      // Verify credentials are still valid
      final apiClient = XtreamApiClient(credentials: credentials);
      final authResult = await apiClient.authenticate();

      if (authResult.isFailure) {
        moduleLogger.warning(
          'Saved credentials are no longer valid',
          tag: 'XtreamAuth',
        );
        // Clear invalid credentials
        await _authService.clearCredentials();
        emit(const XtreamAuthUnauthenticated());
        return;
      }

      final authResponse = authResult.data;

      if (!authResponse.userInfo.isActive) {
        emit(const XtreamAuthUnauthenticated());
        return;
      }

      moduleLogger.info(
        'Loaded and verified saved credentials',
        tag: 'XtreamAuth',
      );

      emit(XtreamAuthAuthenticated(
        credentials: credentials,
        userInfo: authResponse.userInfo,
        serverInfo: authResponse.serverInfo,
      ));
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error loading credentials',
        tag: 'XtreamAuth',
        error: e,
        stackTrace: stackTrace,
      );
      emit(const XtreamAuthUnauthenticated());
    }
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    XtreamAuthLogoutRequested event,
    Emitter<XtreamAuthState> emit,
  ) async {
    try {
      moduleLogger.info('Logging out from Xtream', tag: 'XtreamAuth');

      await _authService.clearCredentials();

      moduleLogger.info('Logout successful', tag: 'XtreamAuth');

      emit(const XtreamAuthUnauthenticated());
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error during logout',
        tag: 'XtreamAuth',
        error: e,
        stackTrace: stackTrace,
      );
      // Still emit unauthenticated state
      emit(const XtreamAuthUnauthenticated());
    }
  }

  /// Handle validate credentials
  Future<void> _onValidateCredentials(
    XtreamAuthValidateCredentials event,
    Emitter<XtreamAuthState> emit,
  ) async {
    final validation = _authService.validateCredentials(event.credentials);

    if (validation.isFailure) {
      emit(XtreamAuthValidationError(message: validation.error.message));
    }
  }
}

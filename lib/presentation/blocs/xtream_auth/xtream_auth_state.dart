// Xtream Auth States
// States for Xtream authentication BLoC.

import 'package:equatable/equatable.dart';

import '../../../modules/xtreamcodes/auth/xtream_credentials.dart';
import '../../../modules/xtreamcodes/models/xtream_api_models.dart';

/// Base class for Xtream auth states
abstract class XtreamAuthState extends Equatable {
  const XtreamAuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class XtreamAuthInitial extends XtreamAuthState {
  const XtreamAuthInitial();
}

/// Loading state
class XtreamAuthLoading extends XtreamAuthState {
  const XtreamAuthLoading();
}

/// Authenticated state
class XtreamAuthAuthenticated extends XtreamAuthState {
  const XtreamAuthAuthenticated({
    required this.credentials,
    required this.userInfo,
    required this.serverInfo,
  });

  final XtreamCredentials credentials;
  final XtreamUserInfo userInfo;
  final XtreamServerInfo serverInfo;

  @override
  List<Object?> get props => [credentials, userInfo, serverInfo];
}

/// Unauthenticated state
class XtreamAuthUnauthenticated extends XtreamAuthState {
  const XtreamAuthUnauthenticated();
}

/// Authentication error state
class XtreamAuthError extends XtreamAuthState {
  const XtreamAuthError({
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Validation error state
class XtreamAuthValidationError extends XtreamAuthState {
  const XtreamAuthValidationError({
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [message];
}

// Xtream Auth Events
// Events for Xtream authentication BLoC.

import 'package:equatable/equatable.dart';

import '../../../modules/xtreamcodes/auth/xtream_credentials.dart';

/// Base class for Xtream auth events
abstract class XtreamAuthEvent extends Equatable {
  const XtreamAuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to login with Xtream credentials
class XtreamAuthLoginRequested extends XtreamAuthEvent {
  const XtreamAuthLoginRequested({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  final String serverUrl;
  final String username;
  final String password;

  @override
  List<Object?> get props => [serverUrl, username, password];
}

/// Event to load saved credentials
class XtreamAuthLoadCredentials extends XtreamAuthEvent {
  const XtreamAuthLoadCredentials();
}

/// Event to logout
class XtreamAuthLogoutRequested extends XtreamAuthEvent {
  const XtreamAuthLogoutRequested();
}

/// Event to validate credentials
class XtreamAuthValidateCredentials extends XtreamAuthEvent {
  const XtreamAuthValidateCredentials({
    required this.credentials,
  });

  final XtreamCredentials credentials;

  @override
  List<Object?> get props => [credentials];
}

// Xtream Connection Events
// Events for Xtream connection progress BLoC.

import 'package:equatable/equatable.dart';

import '../../../modules/xtreamcodes/auth/xtream_credentials.dart';

/// Base class for Xtream connection events
abstract class XtreamConnectionEvent extends Equatable {
  const XtreamConnectionEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start connection process
class XtreamConnectionStarted extends XtreamConnectionEvent {
  const XtreamConnectionStarted({
    required this.credentials,
  });

  final XtreamCredentials credentials;

  @override
  List<Object?> get props => [credentials];
}

/// Event to reset connection state
class XtreamConnectionReset extends XtreamConnectionEvent {
  const XtreamConnectionReset();
}

// Xtream Connection States
// States for Xtream connection progress BLoC.

import 'package:equatable/equatable.dart';

/// Connection step
enum ConnectionStep {
  idle,
  testingConnection,
  fetchingChannels,
  fetchingMovies,
  fetchingSeries,
  updatingEpg,
  completed,
}

/// Base class for Xtream connection states
abstract class XtreamConnectionState extends Equatable {
  const XtreamConnectionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class XtreamConnectionInitial extends XtreamConnectionState {
  const XtreamConnectionInitial();
}

/// In progress state
class XtreamConnectionInProgress extends XtreamConnectionState {
  const XtreamConnectionInProgress({
    required this.currentStep,
    required this.progress,
    this.message,
  });

  final ConnectionStep currentStep;
  final double progress; // 0.0 to 1.0
  final String? message;

  @override
  List<Object?> get props => [currentStep, progress, message];
}

/// Success state
class XtreamConnectionSuccess extends XtreamConnectionState {
  const XtreamConnectionSuccess();
}

/// Error state
class XtreamConnectionError extends XtreamConnectionState {
  const XtreamConnectionError({
    required this.message,
    required this.failedStep,
  });

  final String message;
  final ConnectionStep failedStep;

  @override
  List<Object?> get props => [message, failedStep];
}

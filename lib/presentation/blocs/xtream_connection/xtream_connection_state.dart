// Xtream Connection States
// States for Xtream connection progress BLoC.

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

/// Extension methods for ConnectionStep
extension ConnectionStepExtension on ConnectionStep {
  /// Get the display title for this step
  String get title {
    switch (this) {
      case ConnectionStep.idle:
        return 'Preparing...';
      case ConnectionStep.testingConnection:
        return 'Testing Connection';
      case ConnectionStep.fetchingChannels:
        return 'Getting Live Channels';
      case ConnectionStep.fetchingMovies:
        return 'Loading Movies';
      case ConnectionStep.fetchingSeries:
        return 'Loading Series';
      case ConnectionStep.updatingEpg:
        return 'Updating EPG';
      case ConnectionStep.completed:
        return 'Setup Complete!';
    }
  }

  /// Get the icon for this step
  IconData get icon {
    switch (this) {
      case ConnectionStep.idle:
        return Icons.hourglass_empty;
      case ConnectionStep.testingConnection:
        return Icons.wifi_tethering;
      case ConnectionStep.fetchingChannels:
        return Icons.live_tv;
      case ConnectionStep.fetchingMovies:
        return Icons.movie;
      case ConnectionStep.fetchingSeries:
        return Icons.video_library;
      case ConnectionStep.updatingEpg:
        return Icons.schedule;
      case ConnectionStep.completed:
        return Icons.check_circle;
    }
  }
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

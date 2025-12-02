// Xtream Connection States
// States for Xtream connection progress BLoC.

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Connection step
enum ConnectionStep {
  idle,
  validatingCredentials,
  testingConnection,
  authenticating,
  fetchingChannels,
  fetchingMovies,
  fetchingSeries,
  updatingEpg,
  savingCredentials,
  completed,
}

/// Extension methods for ConnectionStep
extension ConnectionStepExtension on ConnectionStep {
  /// Get the display title for this step
  String get title {
    switch (this) {
      case ConnectionStep.idle:
        return 'Preparing...';
      case ConnectionStep.validatingCredentials:
        return 'Validating Credentials';
      case ConnectionStep.testingConnection:
        return 'Testing Connection';
      case ConnectionStep.authenticating:
        return 'Authenticating';
      case ConnectionStep.fetchingChannels:
        return 'Getting Live Channels';
      case ConnectionStep.fetchingMovies:
        return 'Loading Movies';
      case ConnectionStep.fetchingSeries:
        return 'Loading Series';
      case ConnectionStep.updatingEpg:
        return 'Updating EPG';
      case ConnectionStep.savingCredentials:
        return 'Saving Credentials';
      case ConnectionStep.completed:
        return 'Setup Complete!';
    }
  }

  /// Get the icon for this step
  IconData get icon {
    switch (this) {
      case ConnectionStep.idle:
        return Icons.hourglass_empty;
      case ConnectionStep.validatingCredentials:
        return Icons.verified_user;
      case ConnectionStep.testingConnection:
        return Icons.wifi_tethering;
      case ConnectionStep.authenticating:
        return Icons.lock_open;
      case ConnectionStep.fetchingChannels:
        return Icons.live_tv;
      case ConnectionStep.fetchingMovies:
        return Icons.movie;
      case ConnectionStep.fetchingSeries:
        return Icons.video_library;
      case ConnectionStep.updatingEpg:
        return Icons.schedule;
      case ConnectionStep.savingCredentials:
        return Icons.save;
      case ConnectionStep.completed:
        return Icons.check_circle;
    }
  }

  /// Get the description for this step
  String get description {
    switch (this) {
      case ConnectionStep.idle:
        return 'Getting ready...';
      case ConnectionStep.validatingCredentials:
        return 'Checking your credentials format';
      case ConnectionStep.testingConnection:
        return 'Connecting to your IPTV server';
      case ConnectionStep.authenticating:
        return 'Verifying your account';
      case ConnectionStep.fetchingChannels:
        return 'Loading live TV channels';
      case ConnectionStep.fetchingMovies:
        return 'Loading movies catalog';
      case ConnectionStep.fetchingSeries:
        return 'Loading TV series';
      case ConnectionStep.updatingEpg:
        return 'Downloading program guide';
      case ConnectionStep.savingCredentials:
        return 'Saving your credentials';
      case ConnectionStep.completed:
        return 'You\'re all set!';
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

/// In progress state with detailed status information
class XtreamConnectionInProgress extends XtreamConnectionState {
  const XtreamConnectionInProgress({
    required this.currentStep,
    required this.progress,
    this.message,
    this.channelsLoaded = 0,
    this.moviesLoaded = 0,
    this.seriesLoaded = 0,
  });

  final ConnectionStep currentStep;
  final double progress; // 0.0 to 1.0
  final String? message;
  final int channelsLoaded;
  final int moviesLoaded;
  final int seriesLoaded;

  @override
  List<Object?> get props => [
        currentStep,
        progress,
        message,
        channelsLoaded,
        moviesLoaded,
        seriesLoaded,
      ];

  /// Create a copy with updated values
  XtreamConnectionInProgress copyWith({
    ConnectionStep? currentStep,
    double? progress,
    String? message,
    int? channelsLoaded,
    int? moviesLoaded,
    int? seriesLoaded,
  }) {
    return XtreamConnectionInProgress(
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      channelsLoaded: channelsLoaded ?? this.channelsLoaded,
      moviesLoaded: moviesLoaded ?? this.moviesLoaded,
      seriesLoaded: seriesLoaded ?? this.seriesLoaded,
    );
  }
}

/// Success state with summary information
class XtreamConnectionSuccess extends XtreamConnectionState {
  const XtreamConnectionSuccess({
    this.channelsLoaded = 0,
    this.moviesLoaded = 0,
    this.seriesLoaded = 0,
  });

  final int channelsLoaded;
  final int moviesLoaded;
  final int seriesLoaded;

  @override
  List<Object?> get props => [channelsLoaded, moviesLoaded, seriesLoaded];
}

/// Error state with retry capability
class XtreamConnectionError extends XtreamConnectionState {
  const XtreamConnectionError({
    required this.message,
    required this.failedStep,
    this.errorType = ConnectionErrorType.unknown,
    this.canRetry = true,
  });

  final String message;
  final ConnectionStep failedStep;
  final ConnectionErrorType errorType;
  final bool canRetry;

  @override
  List<Object?> get props => [message, failedStep, errorType, canRetry];
}

/// Connection error types
enum ConnectionErrorType {
  /// Invalid credentials format
  invalidCredentials,

  /// Network connection error
  networkError,

  /// Server unavailable or not responding
  serverError,

  /// Authentication failed (wrong username/password)
  authenticationFailed,

  /// Account expired or inactive
  accountExpired,

  /// Request timeout
  timeout,

  /// Unknown error
  unknown,
}

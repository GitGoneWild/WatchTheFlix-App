import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code,
  });
  final String message;
  final int? code;

  @override
  List<Object?> get props => [message, code];
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code,
  });
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache error occurred',
    super.code,
  });
}

/// Parse failure
class ParseFailure extends Failure {
  const ParseFailure({
    super.message = 'Failed to parse data',
    super.code,
  });
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed',
    super.code,
  });
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred',
    super.code,
  });
}

/// Xtream-specific failure types for onboarding and API interactions
class XtreamFailure extends Failure {
  const XtreamFailure({
    required super.message,
    super.code,
    required this.step,
    this.isRecoverable = true,
  });

  /// The onboarding step that failed
  final String step;

  /// Whether the failure is recoverable (can be retried)
  final bool isRecoverable;

  /// Factory for authentication failures
  factory XtreamFailure.auth(String message) => XtreamFailure(
        message: message,
        step: 'authentication',
        isRecoverable: false,
      );

  /// Factory for account fetch failures
  factory XtreamFailure.account(dynamic error) => XtreamFailure(
        message: 'Failed to fetch account info: $error',
        step: 'account',
        isRecoverable: true,
      );

  /// Factory for category fetch failures
  factory XtreamFailure.categories(String type, dynamic error) => XtreamFailure(
        message: 'Failed to fetch $type categories: $error',
        step: 'categories',
        isRecoverable: true,
      );

  /// Factory for live channel fetch failures
  factory XtreamFailure.liveChannels(dynamic error) => XtreamFailure(
        message: 'Failed to fetch live channels: $error',
        step: 'liveChannels',
        isRecoverable: true,
      );

  /// Factory for movie fetch failures
  factory XtreamFailure.movies(dynamic error) => XtreamFailure(
        message: 'Failed to fetch movies: $error',
        step: 'movies',
        isRecoverable: true,
      );

  /// Factory for series fetch failures
  factory XtreamFailure.series(dynamic error) => XtreamFailure(
        message: 'Failed to fetch series: $error',
        step: 'series',
        isRecoverable: true,
      );

  /// Factory for EPG fetch failures
  factory XtreamFailure.epg(dynamic error) => XtreamFailure(
        message: 'Failed to fetch EPG data: $error',
        step: 'epg',
        isRecoverable: true,
      );

  /// Factory for empty EPG data (not an error, but a valid state)
  factory XtreamFailure.epgEmpty() => const XtreamFailure(
        message: 'EPG data is empty or not available from provider',
        step: 'epg',
        isRecoverable: false,
      );

  /// Factory for timeout failures
  factory XtreamFailure.timeout(String step) => XtreamFailure(
        message: 'Request timed out during $step',
        step: step,
        isRecoverable: true,
      );

  @override
  List<Object?> get props => [message, code, step, isRecoverable];
}

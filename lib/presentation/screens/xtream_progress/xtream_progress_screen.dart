// Xtream Connection Progress Screen
// Shows progress during Xtream Codes connection setup.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/dependency_injection.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../modules/xtreamcodes/auth/xtream_credentials.dart';
import '../../blocs/xtream_connection/xtream_connection_bloc.dart';
import '../../blocs/xtream_connection/xtream_connection_event.dart';
import '../../blocs/xtream_connection/xtream_connection_state.dart';

/// Xtream connection progress screen
class XtreamProgressScreen extends StatelessWidget {
  const XtreamProgressScreen({
    super.key,
    required this.credentials,
  });

  final XtreamCredentials credentials;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<XtreamConnectionBloc>()
        ..add(XtreamConnectionStarted(credentials: credentials)),
      child: const _XtreamProgressContent(),
    );
  }
}

class _XtreamProgressContent extends StatelessWidget {
  const _XtreamProgressContent();

  String _getStepTitle(ConnectionStep step) {
    switch (step) {
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

  IconData _getStepIcon(ConnectionStep step) {
    switch (step) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<XtreamConnectionBloc, XtreamConnectionState>(
        listener: (context, state) {
          if (state is XtreamConnectionSuccess) {
            // Navigate to home on success
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            });
          }
        },
        builder: (context, state) {
          if (state is XtreamConnectionError) {
            return _ErrorView(
              message: state.message,
              failedStep: state.failedStep,
              onRetry: () {
                context.read<XtreamConnectionBloc>().add(
                      const XtreamConnectionReset(),
                    );
                Navigator.pop(context);
              },
            );
          }

          if (state is XtreamConnectionInProgress) {
            return _ProgressView(
              currentStep: state.currentStep,
              progress: state.progress,
              message: state.message,
            );
          }

          // Default/loading state
          return const _ProgressView(
            currentStep: ConnectionStep.idle,
            progress: 0.0,
          );
        },
      ),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({
    required this.currentStep,
    required this.progress,
    this.message,
  });

  final ConnectionStep currentStep;
  final double progress;
  final String? message;

  String _getStepTitle(ConnectionStep step) {
    switch (step) {
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

  IconData _getStepIcon(ConnectionStep step) {
    switch (step) {
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

  @override
  Widget build(BuildContext context) {
    final isCompleted = currentStep == ConnectionStep.completed;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.8, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check_circle,
                            size: 60,
                            color: Colors.green,
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 4,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                              Icon(
                                _getStepIcon(currentStep),
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              _getStepTitle(currentStep),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            if (message != null)
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 32),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                backgroundColor: AppColors.surface,
              ),
            ),

            const SizedBox(height: 8),

            // Progress percentage
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 48),

            // Steps indicator
            _StepsIndicator(currentStep: currentStep),
          ],
        ),
      ),
    );
  }
}

class _StepsIndicator extends StatelessWidget {
  const _StepsIndicator({required this.currentStep});

  final ConnectionStep currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ConnectionStep.testingConnection,
      ConnectionStep.fetchingChannels,
      ConnectionStep.fetchingMovies,
      ConnectionStep.updatingEpg,
    ];

    final currentIndex = steps.indexOf(currentStep);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentIndex ||
            currentStep == ConnectionStep.completed;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            Container(
              width: isCurrent ? 12 : 8,
              height: isCurrent ? 12 : 8,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            if (index < steps.length - 1)
              Container(
                width: 32,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
          ],
        );
      }),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.failedStep,
    required this.onRetry,
  });

  final String message;
  final ConnectionStep failedStep;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Connection Failed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

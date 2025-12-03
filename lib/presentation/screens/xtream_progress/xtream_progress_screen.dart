// Xtream Connection Progress Screen
// Shows progress during Xtream Codes connection setup.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      child: _XtreamProgressContent(credentials: credentials),
    );
  }
}

class _XtreamProgressContent extends StatelessWidget {
  const _XtreamProgressContent({required this.credentials});

  final XtreamCredentials credentials;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<XtreamConnectionBloc, XtreamConnectionState>(
        listener: (context, state) {
          if (state is XtreamConnectionSuccess) {
            // Navigate to home on success
            Future.delayed(const Duration(milliseconds: 1500), () {
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
              errorType: state.errorType,
              canRetry: state.canRetry,
              onRetry: () {
                context.read<XtreamConnectionBloc>().add(
                      XtreamConnectionRetry(credentials: credentials),
                    );
              },
              onGoBack: () {
                context.read<XtreamConnectionBloc>().add(
                      const XtreamConnectionReset(),
                    );
                Navigator.pop(context);
              },
            );
          }

          if (state is XtreamConnectionSuccess) {
            return _SuccessView(
              channelsLoaded: state.channelsLoaded,
              moviesLoaded: state.moviesLoaded,
              seriesLoaded: state.seriesLoaded,
            );
          }

          if (state is XtreamConnectionInProgress) {
            return _ProgressView(
              currentStep: state.currentStep,
              progress: state.progress,
              message: state.message,
              channelsLoaded: state.channelsLoaded,
              moviesLoaded: state.moviesLoaded,
              seriesLoaded: state.seriesLoaded,
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
    this.channelsLoaded = 0,
    this.moviesLoaded = 0,
    this.seriesLoaded = 0,
  });

  final ConnectionStep currentStep;
  final double progress;
  final String? message;
  final int channelsLoaded;
  final int moviesLoaded;
  final int seriesLoaded;

  @override
  Widget build(BuildContext context) {
    final isCompleted = currentStep == ConnectionStep.completed;
    final isLoadingContent = currentStep == ConnectionStep.fetchingChannels ||
        currentStep == ConnectionStep.fetchingMovies ||
        currentStep == ConnectionStep.fetchingSeries;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Playful meme during content loading
            if (isLoadingContent && !isCompleted)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: 200,
                  height: 150,
                  child: SvgPicture.asset(
                    'assets/images/piracy_meme.svg',
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => const SizedBox.shrink(),
                  ),
                ),
              ),

            // Animated Icon
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
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check_circle,
                            size: 60,
                            color: AppColors.success,
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
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                  backgroundColor: AppColors.surface,
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  currentStep.icon,
                                  key: ValueKey(currentStep),
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Title
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                currentStep.title,
                key: ValueKey(currentStep.title),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // Description/Message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                message ?? currentStep.description,
                key: ValueKey(message ?? currentStep.description),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Progress bar with animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0, end: progress),
              builder: (context, animatedProgress, child) {
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: animatedProgress,
                        minHeight: 8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? AppColors.success : AppColors.primary,
                        ),
                        backgroundColor: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(animatedProgress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Steps indicator
            _StepsIndicator(currentStep: currentStep),

            const SizedBox(height: 32),

            // Content stats
            if (channelsLoaded > 0 || moviesLoaded > 0 || seriesLoaded > 0)
              _ContentStats(
                channelsLoaded: channelsLoaded,
                moviesLoaded: moviesLoaded,
                seriesLoaded: seriesLoaded,
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display content loading stats
class _ContentStats extends StatelessWidget {
  const _ContentStats({
    required this.channelsLoaded,
    required this.moviesLoaded,
    required this.seriesLoaded,
  });

  final int channelsLoaded;
  final int moviesLoaded;
  final int seriesLoaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            icon: Icons.live_tv,
            value: channelsLoaded,
            label: 'Channels',
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.border,
          ),
          _StatItem(
            icon: Icons.movie,
            value: moviesLoaded,
            label: 'Movies',
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.border,
          ),
          _StatItem(
            icon: Icons.video_library,
            value: seriesLoaded,
            label: 'Series',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
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
      ConnectionStep.fetchingSeries,
      ConnectionStep.updatingEpg,
    ];

    final currentIndex = steps.indexOf(currentStep);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final isCompleted =
            index < currentIndex || currentStep == ConnectionStep.completed;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isCurrent ? 12 : 8,
              height: isCurrent ? 12 : 8,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? (currentStep == ConnectionStep.completed
                        ? AppColors.success
                        : AppColors.primary)
                    : AppColors.textTertiary,
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            if (index < steps.length - 1)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isCompleted
                    ? (currentStep == ConnectionStep.completed
                        ? AppColors.success
                        : AppColors.primary)
                    : AppColors.textTertiary,
              ),
          ],
        );
      }),
    );
  }
}

/// Success view after connection completes
class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.channelsLoaded,
    required this.moviesLoaded,
    required this.seriesLoaded,
  });

  final int channelsLoaded;
  final int moviesLoaded;
  final int seriesLoaded;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 60,
                      color: AppColors.success,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'All Set!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your IPTV service is ready to use.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _ContentStats(
              channelsLoaded: channelsLoaded,
              moviesLoaded: moviesLoaded,
              seriesLoaded: seriesLoaded,
            ),
            const SizedBox(height: 32),
            Text(
              'Redirecting to home...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.failedStep,
    required this.errorType,
    required this.canRetry,
    required this.onRetry,
    required this.onGoBack,
  });

  final String message;
  final ConnectionStep failedStep;
  final ConnectionErrorType errorType;
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onGoBack;

  IconData get _errorIcon {
    switch (errorType) {
      case ConnectionErrorType.networkError:
        return Icons.wifi_off;
      case ConnectionErrorType.serverError:
        return Icons.cloud_off;
      case ConnectionErrorType.authenticationFailed:
        return Icons.lock;
      case ConnectionErrorType.accountExpired:
        return Icons.timer_off;
      case ConnectionErrorType.timeout:
        return Icons.schedule;
      case ConnectionErrorType.invalidCredentials:
        return Icons.error;
      default:
        return Icons.error_outline;
    }
  }

  String get _errorTitle {
    switch (errorType) {
      case ConnectionErrorType.networkError:
        return 'No Connection';
      case ConnectionErrorType.serverError:
        return 'Server Error';
      case ConnectionErrorType.authenticationFailed:
        return 'Authentication Failed';
      case ConnectionErrorType.accountExpired:
        return 'Account Expired';
      case ConnectionErrorType.timeout:
        return 'Connection Timeout';
      case ConnectionErrorType.invalidCredentials:
        return 'Invalid Credentials';
      default:
        return 'Connection Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _errorIcon,
                      size: 60,
                      color: AppColors.error,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              _errorTitle,
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
            const SizedBox(height: 8),
            // Show which step failed
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    failedStep.icon,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Failed at: ${failedStep.title}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (canRetry)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onGoBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Change Credentials'),
            ),
          ],
        ),
      ),
    );
  }
}

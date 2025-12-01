import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../blocs/xtream_onboarding/xtream_onboarding_bloc.dart';

/// Xtream Codes onboarding screen with real-time progress feedback
class XtreamOnboardingScreen extends StatelessWidget {
  const XtreamOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<XtreamOnboardingBloc, XtreamOnboardingState>(
          listener: (context, state) {
            if (state is XtreamOnboardingCompleted) {
              // Navigate to home after a short delay to show completion
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              });
            }
          },
          builder: (context, state) {
            return _buildContent(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, XtreamOnboardingState state) {
    if (state is XtreamOnboardingInProgress) {
      return _OnboardingProgressView(state: state);
    } else if (state is XtreamOnboardingCompleted) {
      return _OnboardingCompletedView(result: state.result);
    } else if (state is XtreamOnboardingError) {
      return _OnboardingErrorView(state: state);
    }
    return const Center(child: CircularProgressIndicator());
  }
}

/// Progress view showing real-time onboarding status
class _OnboardingProgressView extends StatelessWidget {
  final XtreamOnboardingInProgress state;

  const _OnboardingProgressView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo/Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.settings_input_antenna,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            'Setting Up Your Content',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch your content...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Progress indicator
          _AnimatedProgressBar(progress: state.progress),
          const SizedBox(height: 16),

          // Percentage
          Text(
            '${(state.progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),

          // Current step
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    state.statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Completed steps list
          Expanded(
            child: _CompletedStepsList(steps: state.completedSteps),
          ),
        ],
      ),
    );
  }
}

/// Animated progress bar
class _AnimatedProgressBar extends StatelessWidget {
  final double progress;

  const _AnimatedProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// List of completed steps
class _CompletedStepsList extends StatelessWidget {
  final List<OnboardingStepResult> steps;

  const _CompletedStepsList({required this.steps});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: steps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final step = steps[index];
        return _StepResultTile(result: step);
      },
    );
  }
}

/// Single step result tile
class _StepResultTile extends StatelessWidget {
  final OnboardingStepResult result;

  const _StepResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.success
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.warning_rounded,
            color: result.success ? AppColors.success : AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.step.displayName.replaceAll('...', ''),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (result.itemCount > 0)
                  Text(
                    '${result.itemCount} items loaded',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                if (!result.success && result.errorMessage != null)
                  Text(
                    result.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Completed view showing summary
class _OnboardingCompletedView extends StatelessWidget {
  final OnboardingResult result;

  const _OnboardingCompletedView({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 70,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Setup Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.success,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your content is ready to stream',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 48),

          // Stats grid
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.live_tv,
                        label: 'Live Channels',
                        value: result.liveChannels.toString(),
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.movie,
                        label: 'Movies',
                        value: result.movies.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.tv,
                        label: 'Series',
                        value: result.series.toString(),
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.category,
                        label: 'Categories',
                        value: (result.liveCategories +
                                result.movieCategories +
                                result.seriesCategories)
                            .toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    );
  }
}

/// Stat item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

/// Error view with retry option
class _OnboardingErrorView extends StatelessWidget {
  final XtreamOnboardingError state;

  const _OnboardingErrorView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Setup Failed',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed at: ${state.failedStep.displayName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          if (state.canRetry) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context
                      .read<XtreamOnboardingBloc>()
                      .add(const RetryOnboardingEvent());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/channel.dart';
import '../../blocs/favorites/favorites_bloc.dart';

/// Watch History Screen displays recently watched channels
class WatchHistoryScreen extends StatelessWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch History'),
        backgroundColor: AppColors.background,
        actions: [
          BlocBuilder<FavoritesBloc, FavoritesState>(
            builder: (context, state) {
              if (state is FavoritesLoadedState &&
                  state.recentlyWatched.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearHistoryDialog(context),
                  tooltip: 'Clear History',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoadingState) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (state is FavoritesErrorState) {
            return _ErrorView(message: state.message);
          }

          if (state is FavoritesLoadedState) {
            final recentlyWatched = state.recentlyWatched;

            if (recentlyWatched.isEmpty) {
              return _EmptyHistoryView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recentlyWatched.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final channel = recentlyWatched[index];
                return _HistoryItem(
                  channel: channel,
                  onTap: () {
                    // Add to recent again (updates timestamp)
                    context.read<FavoritesBloc>().add(AddRecentEvent(channel));
                    // Navigate to player
                    Navigator.pushNamed(
                      context,
                      AppRoutes.player,
                      arguments: channel,
                    );
                  },
                  onRemove: () {
                    // TODO: Implement remove from history functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Remove from history not yet implemented'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Clear Watch History'),
        content: const Text(
          'Are you sure you want to clear all watch history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement clear history functionality
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Clear history not yet implemented'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// History item widget
class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.channel,
    required this.onTap,
    required this.onRemove,
  });

  final Channel channel;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  channel.logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.tv,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    );
                  },
                ),
              )
            : const Center(
                child: Icon(
                  Icons.tv,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
      ),
      title: Text(
        channel.name,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (channel.categoryName != null) ...[
            const SizedBox(height: 4),
            Text(
              channel.categoryName!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (channel.epgInfo?.currentProgramTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              channel.epgInfo!.currentProgramTitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accent,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.delete_outline,
          color: AppColors.textSecondary,
        ),
        onPressed: onRemove,
        tooltip: 'Remove from history',
      ),
      onTap: onTap,
    );
  }
}

/// Empty history view
class _EmptyHistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Watch History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Channels you watch will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Error view
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

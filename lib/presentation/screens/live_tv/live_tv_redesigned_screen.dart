import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/category.dart';
import '../../blocs/channel/channel_bloc.dart';
import '../../blocs/favorites/favorites_bloc.dart';

/// Redesigned Live TV Screen with vertical categories on the left side
/// Optimized for better usability and visual appeal
class LiveTVRedesignedScreen extends StatefulWidget {
  const LiveTVRedesignedScreen({super.key});

  @override
  State<LiveTVRedesignedScreen> createState() => _LiveTVRedesignedScreenState();
}

class _LiveTVRedesignedScreenState extends State<LiveTVRedesignedScreen> {
  final ScrollController _channelScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void dispose() {
    _channelScrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _onChannelSelected(Channel channel) {
    context.read<FavoritesBloc>().add(AddRecentEvent(channel));
    Navigator.pushNamed(
      context,
      AppRoutes.player,
      arguments: channel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelBloc, ChannelState>(
      builder: (context, channelState) {
        return BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, favoritesState) {
            if (channelState is ChannelLoadingState) {
              return const _LoadingView();
            }

            if (channelState is ChannelErrorState) {
              return _ErrorView(message: channelState.message);
            }

            if (channelState is ChannelLoadedState) {
              return _buildMainContent(channelState, favoritesState);
            }

            return const _EmptyView();
          },
        );
      },
    );
  }

  Widget _buildMainContent(
    ChannelLoadedState channelState,
    FavoritesState favoritesState,
  ) {
    final isFavorite = favoritesState is FavoritesLoadedState
        ? (String id) => favoritesState.isFavorite(id)
        : (String id) => false;

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar with categories
          _buildCategorySidebar(channelState),

          // Main content area with channels
          Expanded(
            child: Column(
              children: [
                // Top app bar
                _buildAppBar(channelState),

                // Channels grid
                Expanded(
                  child: _buildChannelsGrid(
                    channelState,
                    isFavorite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar(ChannelLoadedState state) {
    final categories = state.categories;
    final selectedCategory = state.selectedCategory;

    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.category, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Categories list
          Expanded(
            child: BlocBuilder<FavoritesBloc, FavoritesState>(
              builder: (context, favoritesState) {
                final favorites = favoritesState is FavoritesLoadedState
                    ? favoritesState.favorites
                    : <Channel>[];
                final recentlyWatched = favoritesState is FavoritesLoadedState
                    ? favoritesState.recentlyWatched
                    : <Channel>[];
                
                // Calculate item count: Favorites + Recently Watched + All + Regular categories
                final specialCategoriesCount = (favorites.isNotEmpty ? 1 : 0) + 
                                               (recentlyWatched.isNotEmpty ? 1 : 0);
                final totalItemCount = specialCategoriesCount + 1 + categories.length;
                
                return ListView.builder(
                  controller: _categoryScrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: totalItemCount,
                  itemBuilder: (context, index) {
                    var currentIndex = 0;
                    
                    // Favorites category (special)
                    if (favorites.isNotEmpty) {
                      if (index == currentIndex) {
                        return _CategoryItem(
                          label: 'Favorites',
                          icon: Icons.favorite,
                          iconColor: AppColors.primary,
                          isSelected: selectedCategory?.id == '_favorites',
                          channelCount: favorites.length,
                          onTap: () {
                            context.read<ChannelBloc>().add(
                                  SelectCategoryEvent(
                                    Category(
                                      id: '_favorites',
                                      name: 'Favorites',
                                      channelCount: favorites.length,
                                    ),
                                  ),
                                );
                          },
                        );
                      }
                      currentIndex++;
                    }
                    
                    // Recently Watched category (special)
                    if (recentlyWatched.isNotEmpty) {
                      if (index == currentIndex) {
                        return _CategoryItem(
                          label: 'Recently Watched',
                          icon: Icons.history,
                          iconColor: AppColors.accentOrange,
                          isSelected: selectedCategory?.id == '_recent',
                          channelCount: recentlyWatched.length,
                          onTap: () {
                            context.read<ChannelBloc>().add(
                                  SelectCategoryEvent(
                                    Category(
                                      id: '_recent',
                                      name: 'Recently Watched',
                                      channelCount: recentlyWatched.length,
                                    ),
                                  ),
                                );
                          },
                        );
                      }
                      currentIndex++;
                    }
                    
                    // All Channels category
                    if (index == currentIndex) {
                      return _CategoryItem(
                        label: 'All Channels',
                        icon: Icons.live_tv,
                        isSelected: selectedCategory == null,
                        channelCount: state.channels.length,
                        onTap: () {
                          context.read<ChannelBloc>().add(
                                const SelectCategoryEvent(null),
                              );
                        },
                      );
                    }
                    currentIndex++;

                    // Regular categories
                    final categoryIndex = index - currentIndex;
                    final category = categories[categoryIndex];
                    return _CategoryItem(
                      label: category.name,
                      icon: Icons.folder_outlined,
                      isSelected: selectedCategory?.id == category.id,
                      channelCount: category.channelCount,
                      onTap: () {
                        context.read<ChannelBloc>().add(
                              SelectCategoryEvent(category),
                            );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ChannelLoadedState state) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, favoritesState) {
        final favorites = favoritesState is FavoritesLoadedState
            ? favoritesState.favorites
            : <Channel>[];
        final recentlyWatched = favoritesState is FavoritesLoadedState
            ? favoritesState.recentlyWatched
            : <Channel>[];
        
        // Determine channel count based on selected category
        int channelCount;
        if (state.selectedCategory?.id == '_favorites') {
          channelCount = favorites.length;
        } else if (state.selectedCategory?.id == '_recent') {
          channelCount = recentlyWatched.length;
        } else {
          channelCount = state.filteredChannels.length;
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Current category indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.selectedCategory?.name ?? 'All Channels',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$channelCount channels available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
                tooltip: 'Search',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<ChannelBloc>().add(const LoadChannelsEvent());
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChannelsGrid(
    ChannelLoadedState state,
    bool Function(String) isFavorite,
  ) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, favoritesState) {
        final favorites = favoritesState is FavoritesLoadedState
            ? favoritesState.favorites
            : <Channel>[];
        final recentlyWatched = favoritesState is FavoritesLoadedState
            ? favoritesState.recentlyWatched
            : <Channel>[];
        
        List<Channel> displayChannels;
        
        // Handle special categories
        if (state.selectedCategory?.id == '_favorites') {
          displayChannels = favorites;
        } else if (state.selectedCategory?.id == '_recent') {
          displayChannels = recentlyWatched;
        } else {
          // For regular categories, show favorited channels first
          final channels = state.filteredChannels;
          final favoriteIds = favorites.map((c) => c.id).toSet();
          
          final favoritedInCategory = channels
              .where((c) => favoriteIds.contains(c.id))
              .toList();
          final nonFavoritedInCategory = channels
              .where((c) => !favoriteIds.contains(c.id))
              .toList();
          
          displayChannels = [...favoritedInCategory, ...nonFavoritedInCategory];
        }

        if (displayChannels.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tv_off_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No channels in this category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting a different category',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          controller: _channelScrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: displayChannels.length,
          itemBuilder: (context, index) {
            final channel = displayChannels[index];
            return _ChannelCard(
              channel: channel,
              isFavorite: isFavorite(channel.id),
              onTap: () => _onChannelSelected(channel),
              onFavoriteToggle: () {
                context.read<FavoritesBloc>().add(
                      ToggleFavoriteEvent(channel),
                    );
              },
            );
          },
        );
      },
    );
  }
}

/// Category item widget for the sidebar
class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.iconColor,
    this.channelCount,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? iconColor;
  final int? channelCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withOpacity(0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor ?? (isSelected ? AppColors.primary : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (channelCount != null && channelCount! > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$channelCount',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Channel card widget with EPG info
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  final Channel channel;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Channel logo/thumbnail
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                      child: channel.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: channel.logoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _buildPlaceholder(),
                              errorWidget: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),

                    // Live indicator
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.overlay,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? AppColors.primary : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                    // EPG progress bar
                    if (channel.epgInfo?.startTime != null &&
                        channel.epgInfo?.endTime != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          color: AppColors.surface,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _calculateProgress(),
                            child: Container(color: AppColors.secondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Channel info with EPG
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Channel name
                      Text(
                        channel.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Current program from EPG or category name
                      if (channel.epgInfo?.currentProgram != null)
                        Text(
                          channel.epgInfo!.currentProgram!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (channel.groupTitle != null)
                        Text(
                          channel.groupTitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const Spacer(),

                      // Next program indicator
                      if (channel.epgInfo?.nextProgram != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Next: ${channel.epgInfo!.nextProgram}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.textTertiary,
                                      fontSize: 9,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateProgress() {
    final startTime = channel.epgInfo?.startTime;
    final endTime = channel.epgInfo?.endTime;
    if (startTime == null || endTime == null) return 0.0;

    final now = DateTime.now();
    if (now.isBefore(startTime) || now.isAfter(endTime)) return 0.0;

    final totalDuration = endTime.difference(startTime).inSeconds;
    final elapsed = now.difference(startTime).inSeconds;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  Widget _buildPlaceholder() {
    return const ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Icon(Icons.live_tv, size: 40, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Loading view
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading channels...'),
          ],
        ),
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
    return Scaffold(
      body: Center(
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
              'Failed to load channels',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ChannelBloc>().add(const LoadChannelsEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty view
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tv_off_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No channels available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a playlist to start watching',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addPlaylist);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Playlist'),
            ),
          ],
        ),
      ),
    );
  }
}

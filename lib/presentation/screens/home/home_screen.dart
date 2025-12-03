import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/movie.dart';
import '../../blocs/channel/channel_bloc.dart';
import '../../blocs/movies/movies_bloc.dart';
import '../../blocs/navigation/navigation_bloc.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../blocs/playlist/playlist_bloc.dart';
import '../../blocs/settings/settings_bloc.dart' as settings;
import '../../widgets/content_widgets.dart';
import '../../widgets/channel_card.dart';
import '../live_tv/live_tv_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: IndexedStack(
            index: state.currentIndex,
            children: const [
              HomeTab(),
              LiveTVTab(),
              MoviesTab(),
              SeriesTab(),
              SettingsTab(),
            ],
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.backgroundLight,
              border: Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: state.currentIndex,
              onDestinationSelected: (index) {
                context.read<NavigationBloc>().add(ChangeTabEvent(index));
              },
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primary.withOpacity(0.15),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: AppColors.primary),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.live_tv_outlined),
                  selectedIcon: Icon(Icons.live_tv, color: AppColors.primary),
                  label: 'Live TV',
                ),
                NavigationDestination(
                  icon: Icon(Icons.movie_outlined),
                  selectedIcon: Icon(Icons.movie, color: AppColors.primary),
                  label: 'Movies',
                ),
                NavigationDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon:
                      Icon(Icons.video_library, color: AppColors.primary),
                  label: 'Series',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings, color: AppColors.primary),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Home tab content with Favorites and Continue Watching
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, favoritesState) {
        return CustomScrollView(
          slivers: [
            // App bar with logo and search
            SliverAppBar(
              floating: true,
              expandedHeight: 60,
              backgroundColor: AppColors.background.withOpacity(0.95),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'WatchTheFlix',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.cast_outlined),
                  onPressed: () {},
                  tooltip: 'Cast to device',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.search),
                  tooltip: 'Search',
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Quick access buttons
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _QuickAccessButton(
                      icon: Icons.live_tv,
                      label: 'Live TV',
                      color: AppColors.primary,
                      onTap: () {
                        context
                            .read<NavigationBloc>()
                            .add(const ChangeTabEvent(1));
                      },
                    ),
                    const SizedBox(width: 12),
                    _QuickAccessButton(
                      icon: Icons.movie_outlined,
                      label: 'Movies',
                      color: AppColors.accent,
                      onTap: () {
                        context
                            .read<NavigationBloc>()
                            .add(const ChangeTabEvent(2));
                      },
                    ),
                    const SizedBox(width: 12),
                    _QuickAccessButton(
                      icon: Icons.video_library_outlined,
                      label: 'Series',
                      color: AppColors.accentPurple,
                      onTap: () {
                        context
                            .read<NavigationBloc>()
                            .add(const ChangeTabEvent(3));
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Continue Watching Section
            if (favoritesState is FavoritesLoadedState &&
                favoritesState.recentlyWatched.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _SectionHeader(
                    title: 'Continue Watching',
                    icon: Icons.play_circle_outline,
                    iconColor: AppColors.secondary,
                    onSeeAll: () {},
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: favoritesState.recentlyWatched.take(10).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final channel = favoritesState.recentlyWatched[index];
                      // Progress tracking placeholder - actual progress would come from playback state
                      final progress =
                          (index + 1) * 0.1 % 1.0; // Simulated progress
                      return SizedBox(
                        width: 140,
                        child: _ContinueWatchingCard(
                          channel: channel,
                          progress: progress,
                          onTap: () {
                            context
                                .read<FavoritesBloc>()
                                .add(AddRecentEvent(channel));
                            Navigator.pushNamed(
                              context,
                              AppRoutes.player,
                              arguments: channel,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Favorites Section
            if (favoritesState is FavoritesLoadedState &&
                favoritesState.favorites.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _SectionHeader(
                    title: 'My Favorites',
                    icon: Icons.favorite,
                    iconColor: AppColors.primary,
                    onSeeAll: () =>
                        Navigator.pushNamed(context, AppRoutes.favorites),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: favoritesState.favorites.take(10).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final channel = favoritesState.favorites[index];
                      return SizedBox(
                        width: 140,
                        child: ChannelCard(
                          channel: channel,
                          onTap: () {
                            context
                                .read<FavoritesBloc>()
                                .add(AddRecentEvent(channel));
                            Navigator.pushNamed(
                              context,
                              AppRoutes.player,
                              arguments: channel,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Popular Channels Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: BlocBuilder<ChannelBloc, ChannelState>(
                  builder: (context, channelState) {
                    if (channelState is ChannelLoadedState &&
                        channelState.channels.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'Popular Channels',
                            icon: Icons.trending_up,
                            iconColor: AppColors.accentOrange,
                            onSeeAll: () {
                              context
                                  .read<NavigationBloc>()
                                  .add(const ChangeTabEvent(1));
                            },
                          ),
                          SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: channelState.channels.take(10).length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final channel = channelState.channels[index];
                                return SizedBox(
                                  width: 140,
                                  child: ChannelCard(
                                    channel: channel,
                                    onTap: () {
                                      context
                                          .read<FavoritesBloc>()
                                          .add(AddRecentEvent(channel));
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.player,
                                        arguments: channel,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

            // Categories Quick Access
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: BlocBuilder<ChannelBloc, ChannelState>(
                  builder: (context, channelState) {
                    if (channelState is ChannelLoadedState &&
                        channelState.categories.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            title: 'Browse by Category',
                            icon: Icons.category_outlined,
                            iconColor: AppColors.accent,
                          ),
                          SizedBox(
                            height: 50,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount:
                                  channelState.categories.take(10).length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final category = channelState.categories[index];
                                return _CategoryPill(
                                  label: category.name,
                                  onTap: () {
                                    context
                                        .read<NavigationBloc>()
                                        .add(const ChangeTabEvent(1));
                                    context
                                        .read<ChannelBloc>()
                                        .add(SelectCategoryEvent(category));
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

            // Empty state when no content
            if (favoritesState is FavoritesLoadedState &&
                favoritesState.favorites.isEmpty &&
                favoritesState.recentlyWatched.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _EmptyHomeState(),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        );
      },
    );
  }
}

/// Quick access button widget
class _QuickAccessButton extends StatelessWidget {
  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.onSeeAll,
  });
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(color: AppColors.textLink, fontSize: 13),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.textLink,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Continue watching card with progress
class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({
    required this.channel,
    required this.progress,
    this.onTap,
  });
  final Channel channel;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(7)),
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: channel.logoUrl != null
                          ? Image.network(
                              channel.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.live_tv,
                                    size: 40, color: AppColors.textSecondary),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.live_tv,
                                  size: 40, color: AppColors.textSecondary),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.overlay,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                channel.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category pill widget
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    this.onTap,
  });
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}

/// Empty home state widget
class _EmptyHomeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tv_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to WatchTheFlix',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start watching by adding a playlist or\nbrowsing available channels',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.addPlaylist),
            icon: const Icon(Icons.add),
            label: const Text('Add Playlist'),
          ),
        ],
      ),
    );
  }
}

/// Live TV tab with favorites and categories
class LiveTVTab extends StatelessWidget {
  const LiveTVTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelBloc, ChannelState>(
      builder: (context, channelState) {
        return BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, favoritesState) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: const Text('Live TV'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {},
                      tooltip: 'Filter',
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.search),
                      tooltip: 'Search',
                    ),
                  ],
                ),

                // Favorites in Live TV
                if (favoritesState is FavoritesLoadedState &&
                    favoritesState.favorites.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: _SectionHeader(
                        title: 'Favorites',
                        icon: Icons.favorite,
                        iconColor: AppColors.primary,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: favoritesState.favorites.take(8).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final channel = favoritesState.favorites[index];
                          return SizedBox(
                            width: 120,
                            child: _CompactChannelCard(
                              channel: channel,
                              isFavorite: true,
                              onTap: () {
                                context
                                    .read<FavoritesBloc>()
                                    .add(AddRecentEvent(channel));
                                Navigator.pushNamed(context, AppRoutes.player,
                                    arguments: channel);
                              },
                              onFavoriteToggle: () {
                                context
                                    .read<FavoritesBloc>()
                                    .add(ToggleFavoriteEvent(channel));
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Categories
                if (channelState is ChannelLoadedState) ...[
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: channelState.categories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return CategoryChip(
                              label: 'All',
                              isSelected: channelState.selectedCategory == null,
                              onTap: () => context
                                  .read<ChannelBloc>()
                                  .add(const SelectCategoryEvent(null)),
                            );
                          }
                          final category = channelState.categories[index - 1];
                          return CategoryChip(
                            label: category.name,
                            isSelected: channelState.selectedCategory?.id ==
                                category.id,
                            onTap: () => context
                                .read<ChannelBloc>()
                                .add(SelectCategoryEvent(category)),
                          );
                        },
                      ),
                    ),
                  ),

                  // Channels grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final channel = channelState.filteredChannels[index];
                          final isFavorite =
                              favoritesState is FavoritesLoadedState
                                  ? favoritesState.isFavorite(channel.id)
                                  : false;
                          return _ChannelGridCard(
                            channel: channel,
                            isFavorite: isFavorite,
                            onTap: () {
                              context
                                  .read<FavoritesBloc>()
                                  .add(AddRecentEvent(channel));
                              Navigator.pushNamed(context, AppRoutes.player,
                                  arguments: channel);
                            },
                            onFavoriteToggle: () {
                              context
                                  .read<FavoritesBloc>()
                                  .add(ToggleFavoriteEvent(channel));
                            },
                          );
                        },
                        childCount: channelState.filteredChannels.length,
                      ),
                    ),
                  ),
                ] else if (channelState is ChannelLoadingState) ...[
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ] else ...[
                  SliverFillRemaining(
                    child: _EmptyChannelState(),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// Compact channel card for horizontal lists
class _CompactChannelCard extends StatelessWidget {
  const _CompactChannelCard({
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
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(7)),
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: channel.logoUrl != null
                          ? Image.network(
                              channel.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.live_tv,
                                    size: 32, color: AppColors.textSecondary),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.live_tv,
                                  size: 32, color: AppColors.textSecondary),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.overlay,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.primary : Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                channel.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Channel grid card with favorite toggle
class _ChannelGridCard extends StatelessWidget {
  const _ChannelGridCard({
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(7)),
                      child: ColoredBox(
                        color: AppColors.surface,
                        child: channel.logoUrl != null
                            ? Image.network(
                                channel.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.live_tv,
                                      size: 36, color: AppColors.textSecondary),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.live_tv,
                                    size: 36, color: AppColors.textSecondary),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
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
                            color:
                                isFavorite ? AppColors.primary : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    // EPG indicator if available
                    if (channel.epgInfo != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.background.withOpacity(0.9)
                              ],
                            ),
                          ),
                          child: Text(
                            channel.epgInfo!.currentProgram ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.name,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (channel.groupTitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          channel.groupTitle!,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
}

/// Empty channel state
class _EmptyChannelState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.live_tv_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No channels available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a playlist to start watching',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.addPlaylist),
            icon: const Icon(Icons.add),
            label: const Text('Add Playlist'),
          ),
        ],
      ),
    );
  }
}

/// Movies tab with categories and grid display
class MoviesTab extends StatefulWidget {
  const MoviesTab({super.key});

  @override
  State<MoviesTab> createState() => _MoviesTabState();
}

class _MoviesTabState extends State<MoviesTab> {
  @override
  void initState() {
    super.initState();
    // Load movies when the tab is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoviesBloc>().add(const LoadMoviesEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoviesBloc, MoviesState>(
      builder: (context, moviesState) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Movies'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<MoviesBloc>().add(const LoadMoviesEvent());
                  },
                  tooltip: 'Refresh',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.search),
                  tooltip: 'Search',
                ),
              ],
            ),

            // Category filter chips
            if (moviesState is MoviesLoadedState &&
                moviesState.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: moviesState.categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return CategoryChip(
                          label: 'All',
                          isSelected: moviesState.selectedCategory == null,
                          onTap: () => context
                              .read<MoviesBloc>()
                              .add(const SelectMovieCategoryEvent(null)),
                        );
                      }
                      final category = moviesState.categories[index - 1];
                      return CategoryChip(
                        label: category.name,
                        isSelected:
                            moviesState.selectedCategory?.id == category.id,
                        onTap: () => context
                            .read<MoviesBloc>()
                            .add(SelectMovieCategoryEvent(category)),
                      );
                    },
                  ),
                ),
              ),

            // Movies grid or loading/empty/error states
            if (moviesState is MoviesLoadingState)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (moviesState is MoviesErrorState)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load movies',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        moviesState.message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<MoviesBloc>().add(const LoadMoviesEvent());
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (moviesState is MoviesLoadedState)
              if (moviesState.filteredMovies.isEmpty)
                SliverFillRemaining(
                  child: _EmptyMoviesState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = moviesState.filteredMovies[index];
                        return _MovieGridCard(
                          movie: movie,
                          onTap: () {
                            // Navigate to play the movie using toChannel() adapter
                            Navigator.pushNamed(
                              context,
                              AppRoutes.player,
                              arguments: movie.toChannel(),
                            );
                          },
                        );
                      },
                      childCount: moviesState.filteredMovies.length,
                    ),
                  ),
                )
            else
              SliverFillRemaining(
                child: _EmptyMoviesState(),
              ),
          ],
        );
      },
    );
  }
}

/// Movie grid card widget
class _MovieGridCard extends StatelessWidget {
  const _MovieGridCard({
    required this.movie,
    this.onTap,
  });
  final Movie movie;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(7)),
                      child: ColoredBox(
                        color: AppColors.surface,
                        child: movie.posterUrl != null
                            ? Image.network(
                                movie.posterUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.movie,
                                      size: 48, color: AppColors.textSecondary),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.movie,
                                    size: 48, color: AppColors.textSecondary),
                              ),
                      ),
                    ),
                    // Rating badge if available
                    if (movie.rating != null && movie.rating! > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.overlay,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.warning,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                movie.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Play overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withOpacity(0.7),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Play button
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.name,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (movie.releaseDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          movie.releaseDate!.length >= 4
                              ? movie.releaseDate!.substring(0, 4)
                              : movie.releaseDate!,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
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
}

/// Empty movies state
class _EmptyMoviesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.movie_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Movies Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Movies will appear here once they are loaded\nfrom your IPTV provider',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Series tab with categories and favorites
class SeriesTab extends StatelessWidget {
  const SeriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, favoritesState) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Series'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {},
                  tooltip: 'Filter',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.search),
                  tooltip: 'Search',
                ),
              ],
            ),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.video_library_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Series',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse your TV series collection\nAdd a playlist with series content to get started',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Enhanced Settings tab
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<settings.SettingsBloc, settings.SettingsState>(
      builder: (context, state) {
        final settingsData = state is settings.SettingsLoadedState
            ? state.settings
            : const settings.AppSettings();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              // Data Refresh Section
              _SettingsSection(
                title: 'Data & Sync',
                children: [
                  _RefreshTile(
                    isRefreshing: state is settings.SettingsLoadedState
                        ? state.isRefreshing
                        : false,
                    lastRefresh: settingsData.lastRefresh,
                    onRefresh: () {
                      // Trigger refresh on all blocs
                      context.read<settings.SettingsBloc>().add(
                            const settings.RefreshPlaylistDataEvent(),
                          );
                      context.read<PlaylistBloc>().add(
                            const LoadPlaylistsEvent(),
                          );
                      context.read<ChannelBloc>().add(
                            const LoadChannelsEvent(),
                          );
                      context.read<FavoritesBloc>().add(
                            const LoadFavoritesEvent(),
                          );
                    },
                  ),
                  _SettingsDropdownTile<int>(
                    icon: Icons.schedule,
                    iconColor: AppColors.secondary,
                    title: 'Auto-Refresh Interval',
                    subtitle: '${settingsData.refreshIntervalHours} hours',
                    value: settingsData.refreshIntervalHours,
                    items: const [
                      DropdownMenuItem(value: 6, child: Text('6 hours')),
                      DropdownMenuItem(value: 12, child: Text('12 hours')),
                      DropdownMenuItem(value: 24, child: Text('24 hours')),
                      DropdownMenuItem(value: 48, child: Text('48 hours')),
                      DropdownMenuItem(value: 72, child: Text('72 hours')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<settings.SettingsBloc>().add(
                              settings.UpdateRefreshIntervalEvent(value),
                            );
                      }
                    },
                  ),
                ],
              ),

              // Playlist Management Section
              _SettingsSection(
                title: 'Content',
                children: [
                  _SettingsTile(
                    icon: Icons.playlist_play,
                    iconColor: AppColors.accent,
                    title: 'Manage Playlists',
                    subtitle: 'Add, edit, or remove playlists',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.addPlaylist),
                  ),
                  _SettingsTile(
                    icon: Icons.favorite,
                    iconColor: AppColors.primary,
                    title: 'Favorites',
                    subtitle: 'Your favorite channels and content',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.favorites),
                  ),
                  _SettingsTile(
                    icon: Icons.history,
                    iconColor: AppColors.accentOrange,
                    title: 'Watch History',
                    subtitle: 'Recently watched content',
                    onTap: () {},
                  ),
                ],
              ),

              // Xtream Codes Section
              _SettingsSection(
                title: 'Xtream Codes',
                children: [
                  _SettingsTile(
                    icon: Icons.live_tv,
                    iconColor: AppColors.primary,
                    title: 'Manage Account',
                    subtitle: 'View or change Xtream Codes credentials',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.xtreamLogin),
                  ),
                  _SettingsTile(
                    icon: Icons.refresh,
                    iconColor: AppColors.accent,
                    title: 'Refresh Channels',
                    subtitle: 'Update live channels and VOD content',
                    onTap: () {
                      // Trigger data refresh for all blocs
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing Xtream channels and content...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      // Trigger refresh on channel and playlist blocs
                      context.read<ChannelBloc>().add(const LoadChannelsEvent());
                      context.read<PlaylistBloc>().add(const LoadPlaylistsEvent());
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.schedule,
                    iconColor: AppColors.secondary,
                    title: 'Refresh EPG',
                    subtitle: 'Update program guide information',
                    onTap: () {
                      // Trigger EPG refresh
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing EPG data...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      // Trigger data reload which will fetch fresh EPG
                      context.read<settings.SettingsBloc>().add(
                            const settings.RefreshPlaylistDataEvent(),
                          );
                      context.read<ChannelBloc>().add(
                            const LoadChannelsEvent(),
                          );
                    },
                  ),
                ],
              ),

              // Appearance Section
              _SettingsSection(
                title: 'Appearance',
                children: [
                  _SettingsDropdownTile<settings.ThemeMode>(
                    icon: Icons.dark_mode,
                    iconColor: AppColors.accentPurple,
                    title: 'Theme',
                    subtitle: settingsData.themeMode.label,
                    value: settingsData.themeMode,
                    items: settings.ThemeMode.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<settings.SettingsBloc>().add(
                              settings.UpdateThemeModeEvent(value),
                            );
                      }
                    },
                  ),
                  _SettingsSwitchTile(
                    icon: Icons.tv,
                    iconColor: AppColors.secondary,
                    title: 'Show EPG',
                    subtitle: 'Display program guide information',
                    value: settingsData.showEpg,
                    onChanged: (_) {
                      context.read<settings.SettingsBloc>().add(
                            const settings.ToggleEpgEvent(),
                          );
                    },
                  ),
                ],
              ),

              // Playback Section
              _SettingsSection(
                title: 'Playback',
                children: [
                  _SettingsDropdownTile<settings.VideoQuality>(
                    icon: Icons.high_quality,
                    iconColor: AppColors.accent,
                    title: 'Video Quality',
                    subtitle: settingsData.videoQuality.label,
                    value: settingsData.videoQuality,
                    items: settings.VideoQuality.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<settings.SettingsBloc>().add(
                              settings.UpdateVideoQualityEvent(value),
                            );
                      }
                    },
                  ),
                  _SettingsSwitchTile(
                    icon: Icons.play_arrow,
                    iconColor: AppColors.secondary,
                    title: 'Auto Play',
                    subtitle: 'Automatically start playback',
                    value: settingsData.autoPlay,
                    onChanged: (_) {
                      context.read<settings.SettingsBloc>().add(
                            const settings.ToggleAutoPlayEvent(),
                          );
                    },
                  ),
                  _SettingsSwitchTile(
                    icon: Icons.subtitles,
                    iconColor: AppColors.accentOrange,
                    title: 'Subtitles',
                    subtitle: 'Enable closed captions when available',
                    value: settingsData.subtitlesEnabled,
                    onChanged: (_) {
                      context.read<settings.SettingsBloc>().add(
                            const settings.ToggleSubtitlesEvent(),
                          );
                    },
                  ),
                  _SettingsSwitchTile(
                    icon: Icons.picture_in_picture,
                    iconColor: AppColors.accentPurple,
                    title: 'Picture-in-Picture',
                    subtitle: 'Continue watching in a floating window',
                    value: settingsData.pipEnabled,
                    onChanged: (_) {
                      context.read<settings.SettingsBloc>().add(
                            const settings.TogglePipEvent(),
                          );
                    },
                  ),
                  _SettingsSwitchTile(
                    icon: Icons.refresh,
                    iconColor: AppColors.warning,
                    title: 'Auto Retry',
                    subtitle: 'Automatically retry on connection failure',
                    value: settingsData.autoRetry,
                    onChanged: (_) {
                      context.read<settings.SettingsBloc>().add(
                            const settings.ToggleAutoRetryEvent(),
                          );
                    },
                  ),
                ],
              ),

              // About Section
              _SettingsSection(
                title: 'About',
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    iconColor: AppColors.textSecondary,
                    title: 'About WatchTheFlix',
                    subtitle: 'Version 1.0.0',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'WatchTheFlix',
                        applicationVersion: '1.0.0',
                        applicationIcon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        children: [
                          const Text(
                              'Your ultimate IPTV streaming experience.'),
                          const SizedBox(height: 8),
                          const Text(
                            'Built with Flutter',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.restore,
                    iconColor: AppColors.error,
                    title: 'Reset Settings',
                    subtitle: 'Restore all settings to default',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Reset Settings?'),
                          content: const Text(
                            'This will restore all settings to their default values. This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<settings.SettingsBloc>().add(
                                      const settings.ResetSettingsEvent(),
                                    );
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Settings have been reset'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

/// Settings section header
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Settings tile widget
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

/// Settings switch tile widget
class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textSecondary)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// Settings dropdown tile widget
class _SettingsDropdownTile<T> extends StatelessWidget {
  const _SettingsDropdownTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textSecondary)),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
        dropdownColor: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// Refresh tile widget for manual data refresh
class _RefreshTile extends StatelessWidget {
  const _RefreshTile({
    required this.isRefreshing,
    this.lastRefresh,
    required this.onRefresh,
  });
  final bool isRefreshing;
  final DateTime? lastRefresh;
  final VoidCallback onRefresh;

  String _formatLastRefresh() {
    if (lastRefresh == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastRefresh!);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';

    return DateFormat('MMM d, yyyy').format(lastRefresh!);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isRefreshing ? Icons.sync : Icons.refresh,
          color: AppColors.secondary,
          size: 20,
        ),
      ),
      title: const Text('Refresh Playlist Data'),
      subtitle: Text(
        isRefreshing
            ? 'Refreshing...'
            : 'Last updated: ${_formatLastRefresh()}',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: isRefreshing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
    );
  }
}

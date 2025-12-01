import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/channel.dart';
import '../../blocs/channel/channel_bloc.dart';
import '../../blocs/navigation/navigation_bloc.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../blocs/settings/settings_bloc.dart' as settings;
import '../../widgets/content_widgets.dart';
import '../../widgets/channel_card.dart';

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
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
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
                  selectedIcon: Icon(Icons.video_library, color: AppColors.primary),
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
              pinned: false,
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
                  onPressed: () => Navigator.pushNamed(context, '/search'),
                  tooltip: 'Search',
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Quick access buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _QuickAccessButton(
                      icon: Icons.live_tv,
                      label: 'Live TV',
                      color: AppColors.primary,
                      onTap: () {
                        context.read<NavigationBloc>().add(const ChangeTabEvent(1));
                      },
                    ),
                    const SizedBox(width: 12),
                    _QuickAccessButton(
                      icon: Icons.movie_outlined,
                      label: 'Movies',
                      color: AppColors.accent,
                      onTap: () {
                        context.read<NavigationBloc>().add(const ChangeTabEvent(2));
                      },
                    ),
                    const SizedBox(width: 12),
                    _QuickAccessButton(
                      icon: Icons.video_library_outlined,
                      label: 'Series',
                      color: AppColors.accentPurple,
                      onTap: () {
                        context.read<NavigationBloc>().add(const ChangeTabEvent(3));
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: favoritesState.recentlyWatched.take(10).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final channel = favoritesState.recentlyWatched[index];
                      return SizedBox(
                        width: 140,
                        child: _ContinueWatchingCard(
                          channel: channel,
                          progress: 0.5,
                          onTap: () {
                            context.read<FavoritesBloc>().add(AddRecentEvent(channel));
                            Navigator.pushNamed(
                              context,
                              '/player',
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
                    onSeeAll: () => Navigator.pushNamed(context, '/favorites'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: favoritesState.favorites.take(10).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final channel = favoritesState.favorites[index];
                      return SizedBox(
                        width: 140,
                        child: ChannelCard(
                          channel: channel,
                          onTap: () {
                            context.read<FavoritesBloc>().add(AddRecentEvent(channel));
                            Navigator.pushNamed(
                              context,
                              '/player',
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
                              context.read<NavigationBloc>().add(const ChangeTabEvent(1));
                            },
                          ),
                          SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: channelState.channels.take(10).length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final channel = channelState.channels[index];
                                return SizedBox(
                                  width: 140,
                                  child: ChannelCard(
                                    channel: channel,
                                    onTap: () {
                                      context.read<FavoritesBloc>().add(AddRecentEvent(channel));
                                      Navigator.pushNamed(
                                        context,
                                        '/player',
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
                          _SectionHeader(
                            title: 'Browse by Category',
                            icon: Icons.category_outlined,
                            iconColor: AppColors.accent,
                          ),
                          SizedBox(
                            height: 50,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: channelState.categories.take(10).length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final category = channelState.categories[index];
                                return _CategoryPill(
                                  label: category.name,
                                  onTap: () {
                                    context.read<NavigationBloc>().add(const ChangeTabEvent(1));
                                    context.read<ChannelBloc>().add(SelectCategoryEvent(category));
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
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

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
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.onSeeAll,
  });

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(color: AppColors.textLink, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
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
  final Channel channel;
  final double progress;
  final VoidCallback? onTap;

  const _ContinueWatchingCard({
    required this.channel,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    child: Container(
                      color: AppColors.surface,
                      child: channel.logoUrl != null
                          ? Image.network(
                              channel.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.live_tv, size: 40, color: AppColors.textSecondary),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.live_tv, size: 40, color: AppColors.textSecondary),
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
  final String label;
  final VoidCallback? onTap;

  const _CategoryPill({
    required this.label,
    this.onTap,
  });

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
            onPressed: () => Navigator.pushNamed(context, '/add-playlist'),
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
                      onPressed: () => Navigator.pushNamed(context, '/search'),
                      tooltip: 'Search',
                    ),
                  ],
                ),

                // Favorites in Live TV
                if (favoritesState is FavoritesLoadedState &&
                    favoritesState.favorites.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                context.read<FavoritesBloc>().add(AddRecentEvent(channel));
                                Navigator.pushNamed(context, '/player', arguments: channel);
                              },
                              onFavoriteToggle: () {
                                context.read<FavoritesBloc>().add(ToggleFavoriteEvent(channel));
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
                            isSelected: channelState.selectedCategory?.id == category.id,
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
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final channel = channelState.filteredChannels[index];
                          final isFavorite = favoritesState is FavoritesLoadedState
                              ? favoritesState.isFavorite(channel.id)
                              : false;
                          return _ChannelGridCard(
                            channel: channel,
                            isFavorite: isFavorite,
                            onTap: () {
                              context.read<FavoritesBloc>().add(AddRecentEvent(channel));
                              Navigator.pushNamed(context, '/player', arguments: channel);
                            },
                            onFavoriteToggle: () {
                              context.read<FavoritesBloc>().add(ToggleFavoriteEvent(channel));
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
  final Channel channel;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const _CompactChannelCard({
    required this.channel,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    child: Container(
                      color: AppColors.surface,
                      child: channel.logoUrl != null
                          ? Image.network(
                              channel.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.live_tv, size: 32, color: AppColors.textSecondary),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.live_tv, size: 32, color: AppColors.textSecondary),
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
  final Channel channel;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const _ChannelGridCard({
    required this.channel,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      child: Container(
                        color: AppColors.surface,
                        child: channel.logoUrl != null
                            ? Image.network(
                                channel.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.live_tv, size: 36, color: AppColors.textSecondary),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.live_tv, size: 36, color: AppColors.textSecondary),
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
                            color: isFavorite ? AppColors.primary : Colors.white,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppColors.background.withOpacity(0.9)],
                            ),
                          ),
                          child: Text(
                            channel.epgInfo!.currentProgram ?? '',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        channel.name,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (channel.groupTitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          channel.groupTitle!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
            onPressed: () => Navigator.pushNamed(context, '/add-playlist'),
            icon: const Icon(Icons.add),
            label: const Text('Add Playlist'),
          ),
        ],
      ),
    );
  }
}

/// Movies tab with categories and favorites
class MoviesTab extends StatelessWidget {
  const MoviesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, favoritesState) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Movies'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {},
                  tooltip: 'Filter',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => Navigator.pushNamed(context, '/search'),
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
                        Icons.movie_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Movies',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse your movie collection\nAdd a playlist with VOD content to get started',
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
                  onPressed: () => Navigator.pushNamed(context, '/search'),
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
              // Playlist Management Section
              _SettingsSection(
                title: 'Content',
                children: [
                  _SettingsTile(
                    icon: Icons.playlist_play,
                    iconColor: AppColors.accent,
                    title: 'Manage Playlists',
                    subtitle: 'Add, edit, or remove playlists',
                    onTap: () => Navigator.pushNamed(context, '/add-playlist'),
                  ),
                  _SettingsTile(
                    icon: Icons.favorite,
                    iconColor: AppColors.primary,
                    title: 'Favorites',
                    subtitle: 'Your favorite channels and content',
                    onTap: () => Navigator.pushNamed(context, '/favorites'),
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
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
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
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
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
                          const Text('Your ultimate IPTV streaming experience.'),
                          const SizedBox(height: 8),
                          Text(
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
                              child: Text(
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
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

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
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

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
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

/// Settings switch tile widget
class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

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
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// Settings dropdown tile widget
class _SettingsDropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SettingsDropdownTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

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
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
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

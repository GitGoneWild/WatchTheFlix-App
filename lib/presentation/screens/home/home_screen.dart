import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/channel.dart';
import '../../blocs/channel/channel_bloc.dart';
import '../../blocs/navigation/navigation_bloc.dart';
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.currentIndex,
            onDestinationSelected: (index) {
              context.read<NavigationBloc>().add(ChangeTabEvent(index));
            },
            backgroundColor: AppColors.backgroundLight,
            indicatorColor: AppColors.primary.withOpacity(0.2),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.live_tv_outlined),
                selectedIcon: Icon(Icons.live_tv),
                label: 'Live TV',
              ),
              NavigationDestination(
                icon: Icon(Icons.movie_outlined),
                selectedIcon: Icon(Icons.movie),
                label: 'Movies',
              ),
              NavigationDestination(
                icon: Icon(Icons.video_library_outlined),
                selectedIcon: Icon(Icons.video_library),
                label: 'Series',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Home tab content
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          floating: true,
          title: Row(
            children: [
              const Icon(Icons.play_circle_filled, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'WatchTheFlix',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.pushNamed(context, '/search'),
            ),
          ],
        ),

        // Hero banner
        SliverToBoxAdapter(
          child: HeroBanner(
            title: 'Featured Content',
            description: 'Discover the latest movies, series, and live TV channels.',
            onPlay: () {},
            onInfo: () {},
          ),
        ),

        // Continue watching
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ContentCarousel(
              title: 'Continue Watching',
              children: List.generate(
                5,
                (index) => MovieCard(
                  title: 'Content ${index + 1}',
                  year: '2024',
                  rating: 4.5,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),

        // Popular channels
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: BlocBuilder<ChannelBloc, ChannelState>(
              builder: (context, state) {
                if (state is ChannelLoadedState) {
                  return ContentCarousel(
                    title: 'Popular Channels',
                    children: state.channels.take(10).map((channel) {
                      return ChannelCard(
                        channel: channel,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/player',
                          arguments: channel,
                        ),
                      );
                    }).toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),

        // Recently added
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: ContentCarousel(
              title: 'Recently Added',
              children: List.generate(
                8,
                (index) => MovieCard(
                  title: 'New Movie ${index + 1}',
                  year: '2024',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Live TV tab
class LiveTVTab extends StatelessWidget {
  const LiveTVTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelBloc, ChannelState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Live TV'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => Navigator.pushNamed(context, '/search'),
                ),
              ],
            ),

            // Categories
            if (state is ChannelLoadedState) ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return CategoryChip(
                          label: 'All',
                          isSelected: state.selectedCategory == null,
                          onTap: () => context
                              .read<ChannelBloc>()
                              .add(const SelectCategoryEvent(null)),
                        );
                      }
                      final category = state.categories[index - 1];
                      return CategoryChip(
                        label: category.name,
                        isSelected: state.selectedCategory?.id == category.id,
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
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final channel = state.filteredChannels[index];
                      return ChannelCard(
                        channel: channel,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/player',
                          arguments: channel,
                        ),
                      );
                    },
                    childCount: state.filteredChannels.length,
                  ),
                ),
              ),
            ] else if (state is ChannelLoadingState) ...[
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else ...[
              SliverFillRemaining(
                child: Center(
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
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/add-playlist'),
                        child: const Text('Add Playlist'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Movies tab placeholder
class MoviesTab extends StatelessWidget {
  const MoviesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.movie_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Movies',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Browse your movie collection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Series tab placeholder
class SeriesTab extends StatelessWidget {
  const SeriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Series'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Series',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Browse your TV series collection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings tab
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: const Text('Manage Playlists'),
            subtitle: const Text('Add, edit, or remove playlists'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/add-playlist'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorites'),
            subtitle: const Text('Your favorite channels'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/favorites'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Appearance'),
            subtitle: const Text('Theme and display settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.play_circle),
            title: const Text('Player Settings'),
            subtitle: const Text('Configure video player'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('WatchTheFlix v1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'WatchTheFlix',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.play_circle_filled,
                  size: 48,
                  color: AppColors.primary,
                ),
                children: [
                  const Text('Your ultimate IPTV streaming experience.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

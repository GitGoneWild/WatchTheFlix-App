import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/category.dart';
import '../../blocs/channel/channel_bloc.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../widgets/content_widgets.dart';

/// Professional Live TV Screen inspired by Sky TV and YouTube TV
class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({super.key});

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  final ScrollController _gridScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  Channel? _focusedChannel;
  bool _showMiniPlayer = false;

  @override
  void dispose() {
    _gridScrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _onChannelFocused(Channel channel) {
    setState(() {
      _focusedChannel = channel;
    });
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
    final favorites = favoritesState is FavoritesLoadedState
        ? favoritesState.favorites
        : <Channel>[];
    final recentlyWatched = favoritesState is FavoritesLoadedState
        ? favoritesState.recentlyWatched
        : <Channel>[];
    final isFavorite = favoritesState is FavoritesLoadedState
        ? (String id) => favoritesState.isFavorite(id)
        : (String id) => false;

    return Scaffold(
      body: CustomScrollView(
        controller: _gridScrollController,
        slivers: [
          // App bar with search and filter
          _buildAppBar(channelState),

          // Featured channel hero section (currently focused or playing)
          if (_focusedChannel != null || recentlyWatched.isNotEmpty)
            SliverToBoxAdapter(
              child: _FeaturedChannelCard(
                channel: _focusedChannel ?? recentlyWatched.first,
                onPlay: () => _onChannelSelected(
                  _focusedChannel ?? recentlyWatched.first,
                ),
              ),
            ),

          // Quick access sections
          // Continue Watching section
          if (recentlyWatched.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Continue Watching',
                icon: Icons.play_circle_outline,
                iconColor: AppColors.secondary,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recentlyWatched.take(10).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final channel = recentlyWatched[index];
                    // Calculate progress based on EPG data if available
                    double progress = 0.0;
                    if (channel.epgInfo?.startTime != null && 
                        channel.epgInfo?.endTime != null) {
                      final now = DateTime.now();
                      final start = channel.epgInfo!.startTime!;
                      final end = channel.epgInfo!.endTime!;
                      if (now.isAfter(start) && now.isBefore(end)) {
                        final total = end.difference(start).inSeconds;
                        final elapsed = now.difference(start).inSeconds;
                        progress = (elapsed / total).clamp(0.0, 1.0);
                      }
                    }
                    return _QuickAccessCard(
                      channel: channel,
                      showProgress: true,
                      progress: progress,
                      onTap: () => _onChannelSelected(channel),
                    );
                  },
                ),
              ),
            ),
          ],

          // Favorites section
          if (favorites.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'My Favorites',
                icon: Icons.favorite,
                iconColor: AppColors.primary,
                onSeeAll: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: favorites.take(10).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final channel = favorites[index];
                    return _QuickAccessCard(
                      channel: channel,
                      isFavorite: true,
                      onTap: () => _onChannelSelected(channel),
                      onFavoriteToggle: () {
                        context.read<FavoritesBloc>().add(
                              ToggleFavoriteEvent(channel),
                            );
                      },
                    );
                  },
                ),
              ),
            ),
          ],

          // Categories horizontal list
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: _CategoryBar(
              categories: channelState.categories,
              selectedCategory: channelState.selectedCategory,
              scrollController: _categoryScrollController,
              onCategorySelected: (category) {
                context.read<ChannelBloc>().add(SelectCategoryEvent(category));
              },
            ),
          ),

          // Channel grid (main content)
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: channelState.selectedCategory?.name ?? 'All Channels',
              icon: Icons.live_tv,
              iconColor: AppColors.accent,
              trailing: Text(
                '${channelState.filteredChannels.length} channels',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final channel = channelState.filteredChannels[index];
                  return _ChannelGridItem(
                    channel: channel,
                    isFavorite: isFavorite(channel.id),
                    onTap: () => _onChannelSelected(channel),
                    onFocus: () => _onChannelFocused(channel),
                    onFavoriteToggle: () {
                      context.read<FavoritesBloc>().add(
                            ToggleFavoriteEvent(channel),
                          );
                    },
                  );
                },
                childCount: channelState.filteredChannels.length,
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(ChannelLoadedState state) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      expandedHeight: 60,
      backgroundColor: AppColors.background.withOpacity(0.95),
      title: Row(
        children: [
          const Icon(Icons.live_tv, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            'Live TV',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          tooltip: 'Search channels',
        ),
        // Filter button
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterBottomSheet(state),
          tooltip: 'Filter',
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<ChannelBloc>().add(const LoadChannelsEvent());
          },
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showFilterBottomSheet(ChannelLoadedState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filter Channels',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: state.selectedCategory == null,
                    onSelected: (_) {
                      context.read<ChannelBloc>().add(
                            const SelectCategoryEvent(null),
                          );
                      Navigator.pop(context);
                    },
                  ),
                  ...state.categories.map((cat) {
                    return FilterChip(
                      label: Text(cat.name),
                      selected: state.selectedCategory?.id == cat.id,
                      onSelected: (_) {
                        context.read<ChannelBloc>().add(
                              SelectCategoryEvent(cat),
                            );
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// Featured channel card at the top
class _FeaturedChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onPlay;

  const _FeaturedChannelCard({
    required this.channel,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.accent.withOpacity(0.2),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background image
          if (channel.logoUrl != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: channel.logoUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.6),
                  colorBlendMode: BlendMode.darken,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  channel.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (channel.epgInfo?.currentProgram != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    channel.epgInfo!.currentProgram!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (channel.groupTitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          channel.groupTitle!,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.onSeeAll,
    this.trailing,
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
          if (trailing != null) trailing!,
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

/// Quick access card for favorites and recent
class _QuickAccessCard extends StatelessWidget {
  final Channel channel;
  final bool isFavorite;
  final bool showProgress;
  final double progress;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const _QuickAccessCard({
    required this.channel,
    this.isFavorite = false,
    this.showProgress = false,
    this.progress = 0,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                    child: channel.logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: channel.logoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Favorite button
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 6,
                      right: 6,
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
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  // Play button overlay
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            if (showProgress)
              Container(
                height: 3,
                color: AppColors.surface,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(color: AppColors.primary),
                ),
              ),
            // Channel name
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                channel.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
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

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.live_tv, size: 32, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Category bar for filtering
class _CategoryBar extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ScrollController scrollController;
  final void Function(Category?) onCategorySelected;

  const _CategoryBar({
    required this.categories,
    this.selectedCategory,
    required this.scrollController,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return CategoryChip(
              label: 'All',
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
            );
          }
          final category = categories[index - 1];
          return CategoryChip(
            label: category.name,
            isSelected: selectedCategory?.id == category.id,
            onTap: () => onCategorySelected(category),
          );
        },
      ),
    );
  }
}

/// Channel grid item with EPG info
class _ChannelGridItem extends StatelessWidget {
  final Channel channel;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFocus;
  final VoidCallback? onFavoriteToggle;

  const _ChannelGridItem({
    required this.channel,
    this.isFavorite = false,
    this.onTap,
    this.onFocus,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onFocus?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
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
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: Colors.white,
                            ),
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
              // Channel info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
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
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
    return Container(
      color: AppColors.surface,
      child: const Center(
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
  final String message;

  const _ErrorView({required this.message});

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
              style: TextStyle(color: AppColors.textSecondary),
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
            Text(
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

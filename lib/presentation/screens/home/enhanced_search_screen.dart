import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/channel.dart';
import '../../blocs/channel/channel_bloc.dart';
import '../../blocs/movies/movies_bloc.dart';
import '../../blocs/favorites/favorites_bloc.dart';

/// Enhanced Search Screen with modern design and multi-content search
/// Supports searching across Live TV, Movies, and Series
class EnhancedSearchScreen extends StatefulWidget {
  const EnhancedSearchScreen({super.key});

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends State<EnhancedSearchScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxRecentSearches = 10;
  static const int _maxFavoritesDisplay = 8;
  
  final _searchController = TextEditingController();
  late final FocusNode _focusNode;
  late final TabController _tabController;
  Timer? _debounceTimer;
  final List<String> _recentSearches = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _tabController = TabController(length: 3, vsync: this);
    _focusNode.requestFocus();
    
    // Listen to focus changes to rebuild border color
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    setState(() {
      _searchQuery = query;
    });

    _debounceTimer = Timer(AppConstants.searchDebounce, () {
      if (query.length >= AppConstants.minSearchLength) {
        // Trigger search in channel bloc
        context.read<ChannelBloc>().add(SearchChannelsEvent(query));
        // TODO: Movie and series search not yet implemented. Track with follow-up issue.
      } else if (query.isEmpty) {
        context.read<ChannelBloc>().add(const ClearSearchEvent());
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > _maxRecentSearches) {
          _recentSearches.removeLast();
        }
      });
    }
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ChannelBloc>().add(const ClearSearchEvent());
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search header with back button and search field
            _buildSearchHeader(),

            // Tab bar for content type filtering
            _buildTabBar(),

            // Search results or suggestions
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildSuggestions()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? AppColors.primary
                          : AppColors.border,
                      width: _focusNode.hasFocus ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search channels, movies, series...',
                      border: InputBorder.none,
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _clearSearch,
                              color: AppColors.textSecondary,
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Live TV'),
          Tab(text: 'Movies'),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, favoritesState) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search tips
            _buildSearchTips(),
            const SizedBox(height: 24),

            // Recent searches
            if (_recentSearches.isNotEmpty) ...[
              _buildRecentSearches(),
              const SizedBox(height: 24),
            ],

            // Quick access to favorites
            if (favoritesState is FavoritesLoadedState &&
                favoritesState.favorites.isNotEmpty) ...[
              _buildFavorites(favoritesState),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSearchTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Search Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Search by channel name, movie title, or genre'),
          _buildTipItem('Use tabs to filter results by content type'),
          _buildTipItem('Recent searches are saved for quick access'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Searches',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _recentSearches.clear();
                });
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: AppColors.textLink,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((search) {
            return Material(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {
                  _searchController.text = search;
                  _onSearchChanged(search);
                  _onSearchSubmitted(search);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        search,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _recentSearches.remove(search);
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFavorites(FavoritesLoadedState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.favorite,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Your Favorites',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.favorites.take(_maxFavoritesDisplay).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final channel = state.favorites[index];
              return _buildFavoriteItem(channel);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteItem(Channel channel) {
    return GestureDetector(
      onTap: () {
        context.read<FavoritesBloc>().add(AddRecentEvent(channel));
        Navigator.pushNamed(
          context,
          AppRoutes.player,
          arguments: channel,
        );
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: channel.logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: channel.logoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.live_tv,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : const Icon(
                      Icons.live_tv,
                      color: AppColors.textSecondary,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: Text(
              channel.name,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllResults(),
        _buildLiveTVResults(),
        _buildMoviesResults(),
      ],
    );
  }

  Widget _buildAllResults() {
    return BlocBuilder<ChannelBloc, ChannelState>(
      builder: (context, channelState) {
        return BlocBuilder<MoviesBloc, MoviesState>(
          builder: (context, moviesState) {
            final channelResults = channelState is ChannelLoadedState
                ? channelState.filteredChannels
                : <Channel>[];

            final totalResults = channelResults.length;

            if (totalResults == 0) {
              return _buildNoResults();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Results count
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '$totalResults ${totalResults == 1 ? 'result' : 'results'} found',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),

                // Channel results
                if (channelResults.isNotEmpty) ...[
                  _buildResultsGrid(channelResults),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLiveTVResults() {
    return BlocBuilder<ChannelBloc, ChannelState>(
      builder: (context, state) {
        if (state is ChannelLoadedState) {
          final results = state.filteredChannels
              .where((c) => c.type == ContentType.live)
              .toList();

          if (results.isEmpty) {
            return _buildNoResults();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${results.length} ${results.length == 1 ? 'channel' : 'channels'} found',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              _buildResultsGrid(results),
            ],
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildMoviesResults() {
    return BlocBuilder<MoviesBloc, MoviesState>(
      builder: (context, state) {
        // For now, show a message as movies bloc might not have search implemented yet
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
              const SizedBox(height: 16),
              Text(
                'Movie Search',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Movie search will be available soon',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsGrid(List<Channel> results) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final channel = results[index];
        return _buildResultCard(channel);
      },
    );
  }

  Widget _buildResultCard(Channel channel) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, favoritesState) {
        final isFavorite = favoritesState is FavoritesLoadedState
            ? favoritesState.isFavorite(channel.id)
            : false;

        return Material(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              context.read<FavoritesBloc>().add(AddRecentEvent(channel));
              Navigator.pushNamed(
                context,
                AppRoutes.player,
                arguments: channel,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                          child: channel.logoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: channel.logoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const ColoredBox(
                                    color: AppColors.surface,
                                    child: Center(
                                      child: Icon(
                                        Icons.live_tv,
                                        size: 32,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => const ColoredBox(
                                    color: AppColors.surface,
                                    child: Center(
                                      child: Icon(
                                        Icons.live_tv,
                                        size: 32,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                              : const ColoredBox(
                                  color: AppColors.surface,
                                  child: Center(
                                    child: Icon(
                                      Icons.live_tv,
                                      size: 32,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                        ),
                        // Favorite indicator
                        if (isFavorite)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(
                              Icons.favorite,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.name,
                            style:
                                Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (channel.groupTitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              channel.groupTitle!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
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
      },
    );
  }

  Widget _buildNoResults() {
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
              Icons.search_off,
              size: 56,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Results Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try searching with different keywords or check your spelling',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

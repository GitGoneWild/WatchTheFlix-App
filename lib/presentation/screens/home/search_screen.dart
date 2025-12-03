import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/channel.dart';
import '../../blocs/channel/channel_bloc.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../widgets/channel_card.dart';

/// Enhanced Search screen with autocomplete and filters
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  late final FocusNode _focusNode;
  Timer? _debounceTimer;
  String? _selectedFilter;
  bool _showSuggestions = false;

  final List<String> _filters = ['All', 'Live TV', 'Movies', 'Series'];
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _searchController.text.isEmpty;
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    setState(() {
      _showSuggestions = query.isEmpty && _focusNode.hasFocus;
    });

    _debounceTimer = Timer(AppConstants.searchDebounce, () {
      if (query.length >= AppConstants.minSearchLength) {
        context.read<ChannelBloc>().add(SearchChannelsEvent(query));
      } else if (query.isEmpty) {
        context.read<ChannelBloc>().add(const ClearSearchEvent());
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
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
      _showSuggestions = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search channels, movies, series...',
                          border: InputBorder.none,
                          hintStyle:
                              const TextStyle(color: AppColors.textTertiary),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
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
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter ||
                      (_selectedFilter == null && filter == 'All');
                  return FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? filter : null;
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  );
                },
              ),
            ),

            // Search results or suggestions
            Expanded(
              child: _showSuggestions
                  ? _buildSuggestions()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, favoritesState) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Recent searches
            if (_recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _recentSearches.clear();
                      });
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: AppColors.textLink, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_recentSearches.length, (index) {
                final search = _recentSearches[index];
                return ListTile(
                  leading:
                      const Icon(Icons.history, color: AppColors.textSecondary),
                  title: Text(search),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      setState(() {
                        _recentSearches.removeAt(index);
                      });
                    },
                  ),
                  onTap: () {
                    _searchController.text = search;
                    _onSearchChanged(search);
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 24),
            ],

            // Quick access to favorites
            if (favoritesState is FavoritesLoadedState &&
                favoritesState.favorites.isNotEmpty) ...[
              Text(
                'Your Favorites',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: favoritesState.favorites.take(6).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final channel = favoritesState.favorites[index];
                    return GestureDetector(
                      onTap: () {
                        context
                            .read<FavoritesBloc>()
                            .add(AddRecentEvent(channel));
                        Navigator.pushNamed(context, AppRoutes.player,
                            arguments: channel);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: channel.logoUrl != null
                                  ? Image.network(
                                      channel.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
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
                            width: 70,
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
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<ChannelBloc, ChannelState>(
      builder: (context, state) {
        return BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, favoritesState) {
            if (state is ChannelLoadedState) {
              var results = state.filteredChannels;

              // Apply content type filter
              if (_selectedFilter != null && _selectedFilter != 'All') {
                switch (_selectedFilter) {
                  case 'Live TV':
                    results = results
                        .where((c) => c.type == ContentType.live)
                        .toList();
                    break;
                  case 'Movies':
                    results = results
                        .where((c) => c.type == ContentType.movie)
                        .toList();
                    break;
                  case 'Series':
                    results = results
                        .where((c) => c.type == ContentType.series)
                        .toList();
                    break;
                }
              }

              if (state.searchQuery == null || state.searchQuery!.isEmpty) {
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
                          Icons.search,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Search for content',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find channels, movies, and series',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                );
              }

              if (results.isEmpty) {
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
                          Icons.search_off,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFilter != null && _selectedFilter != 'All'
                            ? 'Try a different search term or filter'
                            : 'Try a different search term',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${results.length} results found',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        if (_selectedFilter != null && _selectedFilter != 'All')
                          Text(
                            ' in $_selectedFilter',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final channel = results[index];
                        final isFavorite =
                            favoritesState is FavoritesLoadedState
                                ? favoritesState.isFavorite(channel.id)
                                : false;
                        return ChannelCard(
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
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }
}

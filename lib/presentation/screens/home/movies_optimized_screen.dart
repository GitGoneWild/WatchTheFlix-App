import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/movie.dart';
import '../../../domain/entities/category.dart';
import '../../blocs/movies/movies_bloc.dart';

/// Optimized Movies Screen designed for large catalogs (100k+ movies)
/// Features:
/// - Lazy loading with virtualized list
/// - Category filtering on the left sidebar
/// - Smooth scrolling with cached images
/// - Performance-optimized grid layout
class MoviesOptimizedScreen extends StatefulWidget {
  const MoviesOptimizedScreen({super.key});

  @override
  State<MoviesOptimizedScreen> createState() => _MoviesOptimizedScreenState();
}

class _MoviesOptimizedScreenState extends State<MoviesOptimizedScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  static const int _itemsPerPage = 50;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load movies when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoviesBloc>().add(const LoadMoviesEvent());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = maxScroll - currentScroll;

    // Load more when user is 200 pixels from the bottom
    if (delta < 200) {
      _loadMoreMovies();
    }
  }

  void _loadMoreMovies() {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    // Simulate loading delay for pagination
    // In real implementation, this would trigger an event to load next page
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoviesBloc, MoviesState>(
      builder: (context, state) {
        if (state is MoviesLoadingState) {
          return const _LoadingView();
        }

        if (state is MoviesErrorState) {
          return _ErrorView(message: state.message);
        }

        if (state is MoviesLoadedState) {
          return _buildMainContent(state);
        }

        return const _EmptyView();
      },
    );
  }

  Widget _buildMainContent(MoviesLoadedState state) {
    return Scaffold(
      body: Row(
        children: [
          // Left sidebar with categories
          _buildCategorySidebar(state),

          // Main content area with movies grid
          Expanded(
            child: Column(
              children: [
                // Top app bar
                _buildAppBar(state),

                // Movies grid
                Expanded(
                  child: _buildMoviesGrid(state),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar(MoviesLoadedState state) {
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
                const Icon(Icons.movie, color: AppColors.accent, size: 20),
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
            child: ListView.builder(
              controller: _categoryScrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CategoryItem(
                    label: 'All Movies',
                    icon: Icons.movie_outlined,
                    isSelected: selectedCategory == null,
                    movieCount: state.movies.length,
                    onTap: () {
                      context.read<MoviesBloc>().add(
                            const SelectMovieCategoryEvent(null),
                          );
                      _resetPagination();
                    },
                  );
                }

                final category = categories[index - 1];
                return _CategoryItem(
                  label: category.name,
                  icon: Icons.folder_outlined,
                  isSelected: selectedCategory?.id == category.id,
                  movieCount: category.channelCount,
                  onTap: () {
                    context.read<MoviesBloc>().add(
                          SelectMovieCategoryEvent(category),
                        );
                    _resetPagination();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 1;
    });
    // Scroll to top when category changes
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Widget _buildAppBar(MoviesLoadedState state) {
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
                  state.selectedCategory?.name ?? 'All Movies',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.filteredMovies.length} ${state.filteredMovies.length == 1 ? 'movie' : 'movies'} available',
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
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(state),
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MoviesBloc>().add(const LoadMoviesEvent());
              _resetPagination();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  void _showSortOptions(MoviesLoadedState state) {
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
                'Sort Movies',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _SortOption(
                icon: Icons.abc,
                title: 'Name (A-Z)',
                onTap: () => Navigator.pop(context),
              ),
              _SortOption(
                icon: Icons.star,
                title: 'Rating (High to Low)',
                onTap: () => Navigator.pop(context),
              ),
              _SortOption(
                icon: Icons.calendar_today,
                title: 'Release Date (Newest)',
                onTap: () => Navigator.pop(context),
              ),
              _SortOption(
                icon: Icons.trending_up,
                title: 'Most Popular',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoviesGrid(MoviesLoadedState state) {
    final movies = state.filteredMovies;

    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No movies in this category',
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

    // Calculate items to display with pagination
    final itemsToShow = (_currentPage * _itemsPerPage).clamp(0, movies.length);
    final displayedMovies = movies.take(itemsToShow).toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final movie = displayedMovies[index];
                return _MovieCard(
                  movie: movie,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.player,
                      arguments: movie.toChannel(),
                    );
                  },
                );
              },
              childCount: displayedMovies.length,
            ),
          ),
        ),

        // Loading indicator when loading more
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }
}

/// Category item widget for the sidebar
class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.movieCount,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final int? movieCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.accent.withOpacity(0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
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
                    if (movieCount != null && movieCount! > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$movieCount',
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

/// Optimized movie card widget with cached images
class _MovieCard extends StatelessWidget {
  const _MovieCard({
    required this.movie,
    this.onTap,
  });

  final Movie movie;
  final VoidCallback? onTap;

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
              // Movie poster
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                      child: movie.posterUrl != null
                          ? CachedNetworkImage(
                              imageUrl: movie.posterUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _buildPlaceholder(),
                              errorWidget: (_, __, ___) => _buildPlaceholder(),
                              // Use memory cache for performance
                              memCacheWidth: 180,
                              memCacheHeight: 270,
                            )
                          : _buildPlaceholder(),
                    ),

                    // Rating badge
                    if (movie.rating != null && movie.rating! > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.overlay,
                            borderRadius: BorderRadius.circular(6),
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

                    // Play overlay gradient
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
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
                        padding: const EdgeInsets.all(10),
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

              // Movie info
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  Widget _buildPlaceholder() {
    return const ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Icon(Icons.movie, size: 48, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Sort option widget
class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
            Text('Loading movies...'),
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
              'Failed to load movies',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.movie_outlined,
                size: 56,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Movies will appear here once they are loaded from your IPTV provider',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

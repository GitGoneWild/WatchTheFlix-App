import '../entities/channel.dart';
import '../entities/category.dart';
import '../entities/movie.dart';
import '../entities/series.dart';

/// Channel repository interface
abstract class ChannelRepository {
  /// Get all live channels
  Future<List<Channel>> getLiveChannels({String? categoryId});

  /// Get all live categories
  Future<List<Category>> getLiveCategories();

  /// Get all movies
  Future<List<Movie>> getMovies({String? categoryId});

  /// Get all movie categories
  Future<List<Category>> getMovieCategories();

  /// Get all series
  Future<List<Series>> getAllSeries({String? categoryId});

  /// Get all series categories
  Future<List<Category>> getSeriesCategories();

  /// Get series details with seasons and episodes
  Future<Series> getSeriesDetails(String seriesId);

  /// Search content
  Future<SearchResult> search(String query);

  /// Get channel by ID
  Future<Channel?> getChannelById(String id);

  /// Get movie by ID
  Future<Movie?> getMovieById(String id);

  /// Get favorites
  Future<List<Channel>> getFavorites();

  /// Add to favorites
  Future<void> addToFavorites(Channel channel);

  /// Remove from favorites
  Future<void> removeFromFavorites(String channelId);

  /// Check if channel is favorite
  Future<bool> isFavorite(String channelId);

  /// Get recent channels
  Future<List<Channel>> getRecentChannels();

  /// Add to recent channels
  Future<void> addToRecent(Channel channel);
}

/// Search result containing all content types
class SearchResult {
  const SearchResult({
    required this.channels,
    required this.movies,
    required this.series,
  });
  final List<Channel> channels;
  final List<Movie> movies;
  final List<Series> series;

  bool get isEmpty => channels.isEmpty && movies.isEmpty && series.isEmpty;

  int get totalCount => channels.length + movies.length + series.length;
}

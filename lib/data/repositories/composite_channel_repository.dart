// Composite Channel Repository
// Repository that delegates to Xtream or M3U repository based on availability.

import '../../domain/entities/category.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../modules/core/logging/app_logger.dart';
import '../../modules/xtreamcodes/xtream_service_manager.dart';
import '../datasources/local/local_storage.dart';
import 'channel_repository_impl.dart';
import 'xtream_channel_repository.dart';

/// Composite channel repository that delegates to the appropriate implementation
class CompositeChannelRepository implements ChannelRepository {
  CompositeChannelRepository({
    required XtreamServiceManager serviceManager,
    required ChannelRepositoryImpl m3uRepository,
    required LocalStorage localStorage,
  })  : _serviceManager = serviceManager,
        _m3uRepository = m3uRepository,
        _localStorage = localStorage;

  final XtreamServiceManager _serviceManager;
  final ChannelRepositoryImpl _m3uRepository;
  final LocalStorage _localStorage;

  /// Lazily created Xtream repository
  XtreamChannelRepository? _xtreamRepository;

  /// Get the active repository based on Xtream initialization status
  ChannelRepository get _activeRepository {
    if (_serviceManager.isInitialized) {
      moduleLogger.info(
        'Using Xtream repository for channel operations',
        tag: 'CompositeRepo',
      );
      _xtreamRepository ??= XtreamChannelRepository(
        serviceManager: _serviceManager,
        localStorage: _localStorage,
      );
      return _xtreamRepository!;
    }
    moduleLogger.info(
      'Using M3U repository for channel operations',
      tag: 'CompositeRepo',
    );
    return _m3uRepository;
  }

  @override
  Future<List<Channel>> getLiveChannels({String? categoryId}) {
    return _activeRepository.getLiveChannels(categoryId: categoryId);
  }

  @override
  Future<List<Category>> getLiveCategories() {
    return _activeRepository.getLiveCategories();
  }

  @override
  Future<List<Movie>> getMovies({String? categoryId}) {
    return _activeRepository.getMovies(categoryId: categoryId);
  }

  @override
  Future<List<Category>> getMovieCategories() {
    return _activeRepository.getMovieCategories();
  }

  @override
  Future<List<Series>> getAllSeries({String? categoryId}) {
    return _activeRepository.getAllSeries(categoryId: categoryId);
  }

  @override
  Future<List<Category>> getSeriesCategories() {
    return _activeRepository.getSeriesCategories();
  }

  @override
  Future<Series> getSeriesDetails(String seriesId) {
    return _activeRepository.getSeriesDetails(seriesId);
  }

  @override
  Future<SearchResult> search(String query) {
    return _activeRepository.search(query);
  }

  @override
  Future<Channel?> getChannelById(String id) {
    return _activeRepository.getChannelById(id);
  }

  @override
  Future<Movie?> getMovieById(String id) {
    return _activeRepository.getMovieById(id);
  }

  // Favorites and recent channels always use local storage
  @override
  Future<List<Channel>> getFavorites() {
    return _activeRepository.getFavorites();
  }

  @override
  Future<void> addToFavorites(Channel channel) {
    return _activeRepository.addToFavorites(channel);
  }

  @override
  Future<void> removeFromFavorites(String channelId) {
    return _activeRepository.removeFromFavorites(channelId);
  }

  @override
  Future<bool> isFavorite(String channelId) {
    return _activeRepository.isFavorite(channelId);
  }

  @override
  Future<List<Channel>> getRecentChannels() {
    return _activeRepository.getRecentChannels();
  }

  @override
  Future<void> addToRecent(Channel channel) {
    return _activeRepository.addToRecent(channel);
  }
}

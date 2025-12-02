// XtreamLocalStorage
// Local storage service for persisting Xtream Codes data using Hive.
// Provides fast, offline-tolerant access to channels, movies, series, and EPG.

import 'package:hive/hive.dart';

import '../../core/logging/app_logger.dart';
import '../../core/models/base_models.dart';
import '../epg/epg_models.dart';
import 'xtream_hive_models.dart';

/// Box names for Xtream Codes data
class XtreamBoxNames {
  static const String channels = 'xtream_channels';
  static const String liveCategories = 'xtream_live_categories';
  static const String movies = 'xtream_movies';
  static const String movieCategories = 'xtream_movie_categories';
  static const String series = 'xtream_series';
  static const String seriesCategories = 'xtream_series_categories';
  static const String epgPrograms = 'xtream_epg_programs';
  static const String syncStatus = 'xtream_sync_status';
}

/// Local storage service for Xtream Codes data.
///
/// This service provides persistent storage for all Xtream Codes data
/// including channels, categories, movies, series, and EPG data.
/// Data is stored using Hive for fast access and offline support.
class XtreamLocalStorage {
  late Box<HiveChannel> _channelsBox;
  late Box<HiveCategory> _liveCategoriesBox;
  late Box<HiveVodItem> _moviesBox;
  late Box<HiveCategory> _movieCategoriesBox;
  late Box<HiveSeries> _seriesBox;
  late Box<HiveCategory> _seriesCategoriesBox;
  late Box<HiveEpgProgram> _epgProgramsBox;
  late Box<HiveSyncStatus> _syncStatusBox;

  bool _isInitialized = false;

  /// Check if storage is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize storage and register adapters
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      moduleLogger.info('Initializing Xtream local storage', tag: 'Storage');

      // Register adapters if not already registered
      _registerAdapters();

      // Open boxes
      _channelsBox = await Hive.openBox<HiveChannel>(XtreamBoxNames.channels);
      _liveCategoriesBox =
          await Hive.openBox<HiveCategory>(XtreamBoxNames.liveCategories);
      _moviesBox = await Hive.openBox<HiveVodItem>(XtreamBoxNames.movies);
      _movieCategoriesBox =
          await Hive.openBox<HiveCategory>(XtreamBoxNames.movieCategories);
      _seriesBox = await Hive.openBox<HiveSeries>(XtreamBoxNames.series);
      _seriesCategoriesBox =
          await Hive.openBox<HiveCategory>(XtreamBoxNames.seriesCategories);
      _epgProgramsBox =
          await Hive.openBox<HiveEpgProgram>(XtreamBoxNames.epgPrograms);
      _syncStatusBox =
          await Hive.openBox<HiveSyncStatus>(XtreamBoxNames.syncStatus);

      _isInitialized = true;
      moduleLogger.info('Xtream local storage initialized', tag: 'Storage');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to initialize Xtream local storage',
        tag: 'Storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Register Hive type adapters
  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(XtreamHiveTypeIds.contentType)) {
      Hive.registerAdapter(HiveContentTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(XtreamHiveTypeIds.channel)) {
      Hive.registerAdapter(HiveChannelAdapter());
    }
    if (!Hive.isAdapterRegistered(XtreamHiveTypeIds.category)) {
      Hive.registerAdapter(HiveCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(XtreamHiveTypeIds.vodItem)) {
      Hive.registerAdapter(HiveVodItemAdapter());
    }
    if (!Hive.isAdapterRegistered(XtreamHiveTypeIds.episode)) {
      Hive.registerAdapter(HiveEpisodeAdapter());
    }
    if (!Hive.isAdapterRegistered(XtreamHiveTypeIds.season)) {
      Hive.registerAdapter(HiveSeasonAdapter());
    }
    if (!Hive.isAdapterRegistered(XtreamHiveTypeIds.series)) {
      Hive.registerAdapter(HiveSeriesAdapter());
    }
    if (!Hive.isAdapterRegistered(XtreamHiveTypeIds.epgProgram)) {
      Hive.registerAdapter(HiveEpgProgramAdapter());
    }
    if (!Hive.isAdapterRegistered(XtreamHiveTypeIds.syncStatus)) {
      Hive.registerAdapter(HiveSyncStatusAdapter());
    }
  }

  /// Ensure storage is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'XtreamLocalStorage not initialized. Call initialize() first.');
    }
  }

  // ============ Channel Operations ============

  /// Save channels to local storage
  Future<void> saveChannels(
    String profileId,
    List<DomainChannel> channels,
  ) async {
    _ensureInitialized();
    try {
      // Clear existing channels for this profile
      await _clearProfileChannels(profileId);

      // Save new channels
      for (final channel in channels) {
        final key = _getChannelKey(profileId, channel.id);
        await _channelsBox.put(key, HiveChannel.fromDomain(channel));
      }

      moduleLogger.info(
        'Saved ${channels.length} channels for profile $profileId',
        tag: 'Storage',
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save channels',
        tag: 'Storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all channels for a profile
  List<DomainChannel> getChannels(String profileId, {String? categoryId}) {
    _ensureInitialized();
    final prefix = '${profileId}_';
    final channels = _channelsBox.values
        .where(
          (c) => _channelsBox.keys
              .firstWhere((k) => _channelsBox.get(k) == c, orElse: () => '')
              .toString()
              .startsWith(prefix),
        )
        .map((c) => c.toDomain())
        .where((c) => categoryId == null || c.categoryId == categoryId)
        .toList();

    return channels;
  }

  /// Get channels by profile
  List<DomainChannel> getChannelsByProfile(String profileId) {
    _ensureInitialized();
    final prefix = '${profileId}_';
    return _channelsBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .map((key) => _channelsBox.get(key)!)
        .map((c) => c.toDomain())
        .toList();
  }

  /// Get channel count for a profile
  int getChannelCount(String profileId) {
    _ensureInitialized();
    final prefix = '${profileId}_';
    return _channelsBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .length;
  }

  Future<void> _clearProfileChannels(String profileId) async {
    final prefix = '${profileId}_';
    final keysToDelete = _channelsBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .toList();
    await _channelsBox.deleteAll(keysToDelete);
  }

  String _getChannelKey(String profileId, String channelId) {
    return '${profileId}_$channelId';
  }

  // ============ Category Operations ============

  /// Save live TV categories
  Future<void> saveLiveCategories(
    String profileId,
    List<DomainCategory> categories,
  ) async {
    _ensureInitialized();
    await _saveCategories(_liveCategoriesBox, profileId, categories, 'live');
  }

  /// Save movie categories
  Future<void> saveMovieCategories(
    String profileId,
    List<DomainCategory> categories,
  ) async {
    _ensureInitialized();
    await _saveCategories(_movieCategoriesBox, profileId, categories, 'movie');
  }

  /// Save series categories
  Future<void> saveSeriesCategories(
    String profileId,
    List<DomainCategory> categories,
  ) async {
    _ensureInitialized();
    await _saveCategories(
      _seriesCategoriesBox,
      profileId,
      categories,
      'series',
    );
  }

  Future<void> _saveCategories(
    Box<HiveCategory> box,
    String profileId,
    List<DomainCategory> categories,
    String type,
  ) async {
    try {
      // Clear existing categories for this profile
      await _clearProfileData(box, profileId);

      // Save new categories
      for (final category in categories) {
        final key = _getCategoryKey(profileId, category.id);
        await box.put(key, HiveCategory.fromDomain(category, type));
      }

      moduleLogger.info(
        'Saved ${categories.length} $type categories for profile $profileId',
        tag: 'Storage',
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save $type categories',
        tag: 'Storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get live TV categories
  List<DomainCategory> getLiveCategories(String profileId) {
    _ensureInitialized();
    return _getCategoriesByProfile(_liveCategoriesBox, profileId);
  }

  /// Get movie categories
  List<DomainCategory> getMovieCategories(String profileId) {
    _ensureInitialized();
    return _getCategoriesByProfile(_movieCategoriesBox, profileId);
  }

  /// Get series categories
  List<DomainCategory> getSeriesCategories(String profileId) {
    _ensureInitialized();
    return _getCategoriesByProfile(_seriesCategoriesBox, profileId);
  }

  List<DomainCategory> _getCategoriesByProfile(
    Box<HiveCategory> box,
    String profileId,
  ) {
    final prefix = '${profileId}_';
    return box.keys
        .where((key) => key.toString().startsWith(prefix))
        .map((key) => box.get(key)!)
        .map((c) => c.toDomain())
        .toList();
  }

  String _getCategoryKey(String profileId, String categoryId) {
    return '${profileId}_$categoryId';
  }

  // ============ Movie Operations ============

  /// Save movies to local storage
  Future<void> saveMovies(
    String profileId,
    List<VodItem> movies,
  ) async {
    _ensureInitialized();
    try {
      // Clear existing movies for this profile
      await _clearProfileData(_moviesBox, profileId);

      // Save new movies
      for (final movie in movies) {
        final key = _getMovieKey(profileId, movie.id);
        await _moviesBox.put(key, HiveVodItem.fromDomain(movie));
      }

      moduleLogger.info(
        'Saved ${movies.length} movies for profile $profileId',
        tag: 'Storage',
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save movies',
        tag: 'Storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all movies for a profile
  List<VodItem> getMovies(String profileId, {String? categoryId}) {
    _ensureInitialized();
    final prefix = '${profileId}_';
    return _moviesBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .map((key) => _moviesBox.get(key)!)
        .map((m) => m.toDomain())
        .where((m) => categoryId == null || m.categoryId == categoryId)
        .toList();
  }

  /// Get movie count for a profile
  int getMovieCount(String profileId) {
    _ensureInitialized();
    final prefix = '${profileId}_';
    return _moviesBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .length;
  }

  /// Get movie by ID
  VodItem? getMovieById(String profileId, String movieId) {
    _ensureInitialized();
    final key = _getMovieKey(profileId, movieId);
    return _moviesBox.get(key)?.toDomain();
  }

  String _getMovieKey(String profileId, String movieId) {
    return '${profileId}_$movieId';
  }

  // ============ Series Operations ============

  /// Save series to local storage
  Future<void> saveSeries(
    String profileId,
    List<DomainSeries> seriesList,
  ) async {
    _ensureInitialized();
    try {
      // Clear existing series for this profile
      await _clearProfileData(_seriesBox, profileId);

      // Save new series
      for (final series in seriesList) {
        final key = _getSeriesKey(profileId, series.id);
        await _seriesBox.put(key, HiveSeries.fromDomain(series));
      }

      moduleLogger.info(
        'Saved ${seriesList.length} series for profile $profileId',
        tag: 'Storage',
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save series',
        tag: 'Storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all series for a profile
  List<DomainSeries> getSeries(String profileId, {String? categoryId}) {
    _ensureInitialized();
    final prefix = '${profileId}_';
    return _seriesBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .map((key) => _seriesBox.get(key)!)
        .map((s) => s.toDomain())
        .where((s) => categoryId == null || s.categoryId == categoryId)
        .toList();
  }

  /// Get series count for a profile
  int getSeriesCount(String profileId) {
    _ensureInitialized();
    final prefix = '${profileId}_';
    return _seriesBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .length;
  }

  /// Get series by ID
  DomainSeries? getSeriesById(String profileId, String seriesId) {
    _ensureInitialized();
    final key = _getSeriesKey(profileId, seriesId);
    return _seriesBox.get(key)?.toDomain();
  }

  /// Update series with episodes (after fetching details)
  Future<void> updateSeriesWithDetails(
    String profileId,
    DomainSeries series,
  ) async {
    _ensureInitialized();
    final key = _getSeriesKey(profileId, series.id);
    await _seriesBox.put(key, HiveSeries.fromDomain(series));
  }

  String _getSeriesKey(String profileId, String seriesId) {
    return '${profileId}_$seriesId';
  }

  // ============ EPG Operations ============

  /// Save EPG programs to local storage
  Future<void> saveEpgPrograms(
    String profileId,
    List<EpgProgram> programs,
  ) async {
    _ensureInitialized();
    try {
      // Clear existing EPG for this profile
      await _clearProfileData(_epgProgramsBox, profileId);

      // Save new EPG programs
      for (int i = 0; i < programs.length; i++) {
        final program = programs[i];
        final key = _getEpgKey(profileId, program.channelId, i);
        await _epgProgramsBox.put(key, HiveEpgProgram.fromDomain(program));
      }

      moduleLogger.info(
        'Saved ${programs.length} EPG programs for profile $profileId',
        tag: 'Storage',
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save EPG programs',
        tag: 'Storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get EPG programs for a channel
  List<EpgProgram> getEpgForChannel(String profileId, String channelId) {
    _ensureInitialized();
    final prefix = '${profileId}_${channelId}_';
    return _epgProgramsBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .map((key) => _epgProgramsBox.get(key)!)
        .map((p) => p.toDomain())
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get all EPG programs for a profile
  Map<String, List<EpgProgram>> getAllEpg(String profileId) {
    _ensureInitialized();
    final prefix = '${profileId}_';
    final result = <String, List<EpgProgram>>{};

    for (final key in _epgProgramsBox.keys) {
      if (key.toString().startsWith(prefix)) {
        final program = _epgProgramsBox.get(key)!.toDomain();
        result.putIfAbsent(program.channelId, () => []).add(program);
      }
    }

    // Sort each channel's programs by start time
    for (final programs in result.values) {
      programs.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return result;
  }

  /// Get EPG program count for a profile
  int getEpgProgramCount(String profileId) {
    _ensureInitialized();
    final prefix = '${profileId}_';
    return _epgProgramsBox.keys
        .where((key) => key.toString().startsWith(prefix))
        .length;
  }

  /// Clean up old EPG data (keep only future + recent past)
  Future<void> cleanupOldEpg(String profileId,
      {Duration keepPast = const Duration(hours: 6)}) async {
    _ensureInitialized();
    final cutoff = DateTime.now().subtract(keepPast);
    final prefix = '${profileId}_';

    final keysToDelete = <dynamic>[];
    for (final key in _epgProgramsBox.keys) {
      if (key.toString().startsWith(prefix)) {
        final program = _epgProgramsBox.get(key);
        if (program != null && program.endTime.isBefore(cutoff)) {
          keysToDelete.add(key);
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _epgProgramsBox.deleteAll(keysToDelete);
      moduleLogger.debug(
        'Cleaned up ${keysToDelete.length} old EPG entries',
        tag: 'Storage',
      );
    }
  }

  String _getEpgKey(String profileId, String channelId, int index) {
    return '${profileId}_${channelId}_$index';
  }

  // ============ Sync Status Operations ============

  /// Get sync status for a profile
  HiveSyncStatus? getSyncStatus(String profileId) {
    _ensureInitialized();
    return _syncStatusBox.get(profileId);
  }

  /// Save sync status
  Future<void> saveSyncStatus(HiveSyncStatus status) async {
    _ensureInitialized();
    await _syncStatusBox.put(status.profileId, status);
  }

  /// Create or get sync status for a profile
  HiveSyncStatus getOrCreateSyncStatus(String profileId) {
    _ensureInitialized();
    var status = _syncStatusBox.get(profileId);
    if (status == null) {
      status = HiveSyncStatus(profileId: profileId);
      _syncStatusBox.put(profileId, status);
    }
    return status;
  }

  // ============ General Operations ============

  /// Clear all data for a profile
  Future<void> clearProfileData(String profileId) async {
    _ensureInitialized();
    try {
      await _clearProfileChannels(profileId);
      await _clearProfileData(_liveCategoriesBox, profileId);
      await _clearProfileData(_movieCategoriesBox, profileId);
      await _clearProfileData(_seriesCategoriesBox, profileId);
      await _clearProfileData(_moviesBox, profileId);
      await _clearProfileData(_seriesBox, profileId);
      await _clearProfileData(_epgProgramsBox, profileId);
      await _syncStatusBox.delete(profileId);

      moduleLogger.info(
        'Cleared all data for profile $profileId',
        tag: 'Storage',
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to clear profile data',
        tag: 'Storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _clearProfileData<T extends HiveObject>(
    Box<T> box,
    String profileId,
  ) async {
    final prefix = '${profileId}_';
    final keysToDelete =
        box.keys.where((key) => key.toString().startsWith(prefix)).toList();
    await box.deleteAll(keysToDelete);
  }

  /// Clear all Xtream data
  Future<void> clearAll() async {
    _ensureInitialized();
    try {
      await _channelsBox.clear();
      await _liveCategoriesBox.clear();
      await _movieCategoriesBox.clear();
      await _seriesCategoriesBox.clear();
      await _moviesBox.clear();
      await _seriesBox.clear();
      await _epgProgramsBox.clear();
      await _syncStatusBox.clear();

      moduleLogger.info('Cleared all Xtream data', tag: 'Storage');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to clear all data',
        tag: 'Storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Close all boxes
  Future<void> close() async {
    if (!_isInitialized) return;
    try {
      await _channelsBox.close();
      await _liveCategoriesBox.close();
      await _movieCategoriesBox.close();
      await _seriesCategoriesBox.close();
      await _moviesBox.close();
      await _seriesBox.close();
      await _epgProgramsBox.close();
      await _syncStatusBox.close();
      _isInitialized = false;
      moduleLogger.info('Xtream local storage closed', tag: 'Storage');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to close storage',
        tag: 'Storage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get storage statistics
  Map<String, int> getStorageStats(String profileId) {
    _ensureInitialized();
    return {
      'channels': getChannelCount(profileId),
      'liveCategories': getLiveCategories(profileId).length,
      'movies': getMovieCount(profileId),
      'movieCategories': getMovieCategories(profileId).length,
      'series': getSeriesCount(profileId),
      'seriesCategories': getSeriesCategories(profileId).length,
      'epgPrograms': getEpgProgramCount(profileId),
    };
  }
}

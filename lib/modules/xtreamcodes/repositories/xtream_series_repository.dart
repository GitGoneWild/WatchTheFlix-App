// Xtream Series Repository
// Repository for managing TV series with smart caching.

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/storage/storage_service.dart';
import '../account/xtream_api_client.dart';
import '../mappers/xtream_mappers.dart';

/// Storage keys for series cache
const String _seriesCacheKey = 'xtream_series_items';
const String _seriesCategoriesCacheKey = 'xtream_series_categories';
const String _seriesTimestampKey = 'xtream_series_timestamp';

/// Xtream series repository interface
abstract class IXtreamSeriesRepository {
  /// Get all series
  Future<ApiResult<List<DomainSeries>>> getSeries({
    String? categoryId,
    bool forceRefresh = false,
  });

  /// Get series categories
  Future<ApiResult<List<DomainCategory>>> getSeriesCategories({
    bool forceRefresh = false,
  });

  /// Get detailed series info with seasons and episodes
  Future<ApiResult<DomainSeries>> getSeriesInfo(String seriesId);

  /// Refresh series from server
  Future<ApiResult<void>> refreshSeries();

  /// Clear series cache
  Future<ApiResult<void>> clearCache();
}

/// Xtream series repository implementation
class XtreamSeriesRepository implements IXtreamSeriesRepository {
  XtreamSeriesRepository({
    required XtreamApiClient apiClient,
    required IStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  final XtreamApiClient _apiClient;
  final IStorageService _storage;

  List<DomainSeries>? _cachedSeries;
  List<DomainCategory>? _cachedCategories;

  /// Flag to prevent multiple simultaneous refreshes
  bool _isRefreshingSeries = false;
  bool _isRefreshingCategories = false;

  @override
  Future<ApiResult<List<DomainSeries>>> getSeries({
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    try {
      // Load from cache if needed
      if (_cachedSeries == null && !forceRefresh) {
        await _loadSeriesFromCache();
      }

      // Refresh in background if cache is stale (but still return cached data immediately)
      if (!forceRefresh && await _isCacheStale()) {
        // Trigger background refresh without waiting
        _refreshSeriesInBackground();
      } else if (forceRefresh) {
        // Only block on force refresh
        final refreshResult = await refreshSeries();
        if (refreshResult.isFailure && _cachedSeries == null) {
          return ApiResult.failure(refreshResult.error);
        }
      }

      if (_cachedSeries == null) {
        return ApiResult.failure(
          const ApiError(
            type: ApiErrorType.notFound,
            message: 'No series available',
          ),
        );
      }

      // Filter by category if specified
      var series = _cachedSeries!;
      if (categoryId != null) {
        series = series.where((s) => s.categoryId == categoryId).toList();
      }

      return ApiResult.success(series);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to get series',
        tag: 'XtreamSeries',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<DomainCategory>>> getSeriesCategories({
    bool forceRefresh = false,
  }) async {
    try {
      // Load from cache if needed
      if (_cachedCategories == null && !forceRefresh) {
        await _loadCategoriesFromCache();
      }

      // Refresh in background if cache is stale
      if (!forceRefresh && await _isCacheStale()) {
        _refreshCategoriesInBackground();
      } else if (forceRefresh) {
        final categoriesResult = await _apiClient.getSeriesCategories();
        if (categoriesResult.isSuccess) {
          _cachedCategories = categoriesResult.data
              .map((c) => XtreamMappers.seriesCategoryToCategory(c))
              .toList();
          await _saveCategoriesToCache(_cachedCategories!);
        } else if (_cachedCategories == null) {
          return ApiResult.failure(categoriesResult.error);
        }
      }

      if (_cachedCategories == null) {
        return ApiResult.failure(
          const ApiError(
            type: ApiErrorType.notFound,
            message: 'No series categories available',
          ),
        );
      }

      return ApiResult.success(_cachedCategories!);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to get series categories',
        tag: 'XtreamSeries',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<DomainSeries>> getSeriesInfo(String seriesId) async {
    try {
      moduleLogger.info('Fetching series info for: $seriesId', tag: 'XtreamSeries');

      // Extract the numeric ID from the full ID (e.g., "xtream_series_123" -> "123")
      final numericId = seriesId.replaceAll('xtream_series_', '');

      final infoResult = await _apiClient.getSeriesInfo(numericId);
      if (infoResult.isFailure) {
        return ApiResult.failure(infoResult.error);
      }

      final domainSeries = XtreamMappers.seriesInfoToDoMainSeries(
        infoResult.data,
        numericId,
        _apiClient,
      );

      return ApiResult.success(domainSeries);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to get series info',
        tag: 'XtreamSeries',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<void>> refreshSeries() async {
    try {
      moduleLogger.info('Refreshing series', tag: 'XtreamSeries');

      final seriesResult = await _apiClient.getSeries();
      if (seriesResult.isFailure) {
        return ApiResult.failure(seriesResult.error);
      }

      _cachedSeries = seriesResult.data
          .map((s) => XtreamMappers.seriesToDomainSeries(s, _apiClient))
          .toList();

      await _saveSeriesToCache(_cachedSeries!);
      await _updateCacheTimestamp();

      moduleLogger.info(
        'Refreshed ${_cachedSeries!.length} series',
        tag: 'XtreamSeries',
      );

      return ApiResult.success(null);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to refresh series',
        tag: 'XtreamSeries',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<void>> clearCache() async {
    try {
      _cachedSeries = null;
      _cachedCategories = null;
      await _storage.remove(_seriesCacheKey);
      await _storage.remove(_seriesCategoriesCacheKey);
      await _storage.remove(_seriesTimestampKey);
      moduleLogger.info('Series cache cleared', tag: 'XtreamSeries');
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Refresh series in background without blocking
  void _refreshSeriesInBackground() {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshingSeries) return;

    _isRefreshingSeries = true;

    // Fire and forget - don't await
    refreshSeries().then((result) {
      if (result.isSuccess) {
        moduleLogger.info(
          'Background series refresh completed successfully',
          tag: 'XtreamSeries',
        );
      } else {
        moduleLogger.warning(
          'Background series refresh failed: ${result.error.message}',
          tag: 'XtreamSeries',
        );
      }
    }).catchError((error, stackTrace) {
      moduleLogger.error(
        'Background series refresh error',
        tag: 'XtreamSeries',
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      _isRefreshingSeries = false;
    });
  }

  /// Refresh categories in background without blocking
  void _refreshCategoriesInBackground() {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshingCategories) return;

    _isRefreshingCategories = true;

    // Fire and forget - don't await
    _apiClient.getSeriesCategories().then((categoriesResult) {
      if (categoriesResult.isSuccess) {
        _cachedCategories = categoriesResult.data
            .map((c) => XtreamMappers.seriesCategoryToCategory(c))
            .toList();
        _saveCategoriesToCache(_cachedCategories!);
        moduleLogger.info(
          'Background series categories refresh completed',
          tag: 'XtreamSeries',
        );
      } else {
        moduleLogger.warning(
          'Background series categories refresh failed: ${categoriesResult.error.message}',
          tag: 'XtreamSeries',
        );
      }
    }).catchError((error, stackTrace) {
      moduleLogger.error(
        'Background series categories refresh error',
        tag: 'XtreamSeries',
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      _isRefreshingCategories = false;
    });
  }

  /// Check if cache is stale
  Future<bool> _isCacheStale() async {
    final timestampResult = await _storage.getInt(_seriesTimestampKey);
    if (timestampResult.isFailure || timestampResult.data == null) {
      return true;
    }

    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
      timestampResult.data!,
    );
    final cacheAge = DateTime.now().difference(lastUpdate);
    return cacheAge > AppConfig().cacheExpiration;
  }

  /// Update cache timestamp
  Future<void> _updateCacheTimestamp() async {
    await _storage.setInt(
      _seriesTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Load series from cache
  Future<void> _loadSeriesFromCache() async {
    try {
      final seriesResult = await _storage.getJsonList(_seriesCacheKey);
      if (seriesResult.isSuccess && seriesResult.data != null) {
        _cachedSeries = seriesResult.data!
            .map((json) => _seriesFromJson(json))
            .whereType<DomainSeries>()
            .toList();
        moduleLogger.info(
          'Loaded ${_cachedSeries!.length} series from cache',
          tag: 'XtreamSeries',
        );
      }
    } catch (e) {
      moduleLogger.warning(
        'Failed to load series from cache',
        tag: 'XtreamSeries',
        error: e,
      );
    }
  }

  /// Load categories from cache
  Future<void> _loadCategoriesFromCache() async {
    try {
      final categoriesResult = await _storage.getJsonList(
        _seriesCategoriesCacheKey,
      );
      if (categoriesResult.isSuccess && categoriesResult.data != null) {
        _cachedCategories = categoriesResult.data!
            .map((json) => _categoryFromJson(json))
            .whereType<DomainCategory>()
            .toList();
        moduleLogger.info(
          'Loaded ${_cachedCategories!.length} series categories from cache',
          tag: 'XtreamSeries',
        );
      }
    } catch (e) {
      moduleLogger.warning(
        'Failed to load series categories from cache',
        tag: 'XtreamSeries',
        error: e,
      );
    }
  }

  /// Save series to cache
  Future<void> _saveSeriesToCache(List<DomainSeries> series) async {
    try {
      final seriesJson = series.map((s) => _seriesToJson(s)).toList();
      await _storage.setJsonList(_seriesCacheKey, seriesJson);
      moduleLogger.info('Series saved to cache', tag: 'XtreamSeries');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save series to cache',
        tag: 'XtreamSeries',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Save categories to cache
  Future<void> _saveCategoriesToCache(List<DomainCategory> categories) async {
    try {
      final categoriesJson = categories.map((c) => _categoryToJson(c)).toList();
      await _storage.setJsonList(_seriesCategoriesCacheKey, categoriesJson);
      moduleLogger.info('Series categories saved to cache', tag: 'XtreamSeries');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save series categories to cache',
        tag: 'XtreamSeries',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Convert series to JSON
  Map<String, dynamic> _seriesToJson(DomainSeries series) {
    return {
      'id': series.id,
      'name': series.name,
      'posterUrl': series.posterUrl,
      'backdropUrl': series.backdropUrl,
      'description': series.description,
      'categoryId': series.categoryId,
      'genre': series.genre,
      'releaseDate': series.releaseDate,
      'rating': series.rating,
      'metadata': series.metadata,
    };
  }

  /// Convert JSON to series
  DomainSeries? _seriesFromJson(Map<String, dynamic> json) {
    try {
      return DomainSeries(
        id: json['id'] as String,
        name: json['name'] as String,
        posterUrl: json['posterUrl'] as String?,
        backdropUrl: json['backdropUrl'] as String?,
        description: json['description'] as String?,
        categoryId: json['categoryId'] as String?,
        genre: json['genre'] as String?,
        releaseDate: json['releaseDate'] as String?,
        rating: json['rating'] as double?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      moduleLogger.warning(
        'Failed to parse series from JSON',
        tag: 'XtreamSeries',
        error: e,
      );
      return null;
    }
  }

  /// Convert category to JSON
  Map<String, dynamic> _categoryToJson(DomainCategory category) {
    return {
      'id': category.id,
      'name': category.name,
      'channelCount': category.channelCount,
      'iconUrl': category.iconUrl,
      'sortOrder': category.sortOrder,
    };
  }

  /// Convert JSON to category
  DomainCategory? _categoryFromJson(Map<String, dynamic> json) {
    try {
      return DomainCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        channelCount: json['channelCount'] as int,
        iconUrl: json['iconUrl'] as String?,
        sortOrder: json['sortOrder'] as int?,
      );
    } catch (e) {
      moduleLogger.warning(
        'Failed to parse series category from JSON',
        tag: 'XtreamSeries',
        error: e,
      );
      return null;
    }
  }
}

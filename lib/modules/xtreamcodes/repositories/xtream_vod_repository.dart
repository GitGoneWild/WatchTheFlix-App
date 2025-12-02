// Xtream VOD Repository
// Repository for managing VOD (movies) with smart caching.

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/storage/storage_service.dart';
import '../account/xtream_api_client.dart';
import '../mappers/xtream_mappers.dart';

/// Storage keys for VOD cache
const String _vodItemsCacheKey = 'xtream_vod_items';
const String _vodCategoriesCacheKey = 'xtream_vod_categories';
const String _vodTimestampKey = 'xtream_vod_timestamp';

/// Xtream VOD repository interface
abstract class IXtreamVodRepository {
  /// Get all VOD items (movies)
  Future<ApiResult<List<VodItem>>> getVodItems({
    String? categoryId,
    bool forceRefresh = false,
  });

  /// Get VOD categories
  Future<ApiResult<List<DomainCategory>>> getVodCategories({
    bool forceRefresh = false,
  });

  /// Get detailed VOD info
  Future<ApiResult<VodItem>> getVodInfo(String vodId);

  /// Refresh VOD items from server
  Future<ApiResult<void>> refreshVodItems();

  /// Clear VOD cache
  Future<ApiResult<void>> clearCache();
}

/// Xtream VOD repository implementation
class XtreamVodRepository implements IXtreamVodRepository {
  XtreamVodRepository({
    required XtreamApiClient apiClient,
    required IStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  final XtreamApiClient _apiClient;
  final IStorageService _storage;

  List<VodItem>? _cachedItems;
  List<DomainCategory>? _cachedCategories;

  @override
  Future<ApiResult<List<VodItem>>> getVodItems({
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    try {
      if (_cachedItems == null && !forceRefresh) {
        await _loadItemsFromCache();
      }

      if (forceRefresh || await _isCacheStale()) {
        final refreshResult = await refreshVodItems();
        if (refreshResult.isFailure && _cachedItems == null) {
          return ApiResult.failure(refreshResult.error);
        }
      }

      if (_cachedItems == null) {
        return ApiResult.failure(
          const ApiError(
            type: ApiErrorType.notFound,
            message: 'No VOD items available',
          ),
        );
      }

      var items = _cachedItems!;
      if (categoryId != null) {
        items = items.where((i) => i.categoryId == categoryId).toList();
      }

      return ApiResult.success(items);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to get VOD items',
        tag: 'XtreamVod',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<DomainCategory>>> getVodCategories({
    bool forceRefresh = false,
  }) async {
    try {
      if (_cachedCategories == null && !forceRefresh) {
        await _loadCategoriesFromCache();
      }

      if (forceRefresh || await _isCacheStale()) {
        final categoriesResult = await _apiClient.getVodCategories();
        if (categoriesResult.isSuccess) {
          _cachedCategories = categoriesResult.data
              .map((c) => XtreamMappers.vodCategoryToCategory(c))
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
            message: 'No VOD categories available',
          ),
        );
      }

      return ApiResult.success(_cachedCategories!);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to get VOD categories',
        tag: 'XtreamVod',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<VodItem>> getVodInfo(String vodId) async {
    try {
      moduleLogger.info('Fetching VOD info for: $vodId', tag: 'XtreamVod');

      final infoResult = await _apiClient.getVodInfo(vodId);
      if (infoResult.isFailure) {
        return ApiResult.failure(infoResult.error);
      }

      final vodItem = XtreamMappers.vodInfoToVodItem(
        infoResult.data,
        _apiClient,
      );

      return ApiResult.success(vodItem);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to get VOD info',
        tag: 'XtreamVod',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<void>> refreshVodItems() async {
    try {
      moduleLogger.info('Refreshing VOD items', tag: 'XtreamVod');

      final streamsResult = await _apiClient.getVodStreams();
      if (streamsResult.isFailure) {
        return ApiResult.failure(streamsResult.error);
      }

      _cachedItems = streamsResult.data
          .map((s) => XtreamMappers.vodStreamToVodItem(s, _apiClient))
          .toList();

      await _saveItemsToCache(_cachedItems!);
      await _updateCacheTimestamp();

      moduleLogger.info(
        'Refreshed ${_cachedItems!.length} VOD items',
        tag: 'XtreamVod',
      );

      return ApiResult.success(null);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to refresh VOD items',
        tag: 'XtreamVod',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<void>> clearCache() async {
    try {
      _cachedItems = null;
      _cachedCategories = null;
      await _storage.remove(_vodItemsCacheKey);
      await _storage.remove(_vodCategoriesCacheKey);
      await _storage.remove(_vodTimestampKey);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  Future<bool> _isCacheStale() async {
    final timestampResult = await _storage.getInt(_vodTimestampKey);
    if (timestampResult.isFailure) return true;
    
    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
      timestampResult.data!,
    );
    final cacheAge = DateTime.now().difference(lastUpdate);
    return cacheAge > AppConfig().cacheExpiration;
  }

  Future<void> _updateCacheTimestamp() async {
    await _storage.setInt(
      _vodTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _loadItemsFromCache() async {
    try {
      final itemsResult = await _storage.getJsonList(_vodItemsCacheKey);
      if (itemsResult.isSuccess && itemsResult.data != null) {
        _cachedItems = itemsResult.data!
            .map((json) => _vodItemFromJson(json))
            .whereType<VodItem>()
            .toList();
      }
    } catch (e) {
      moduleLogger.warning('Failed to load VOD items from cache', tag: 'XtreamVod', error: e);
    }
  }

  Future<void> _loadCategoriesFromCache() async {
    try {
      final categoriesResult = await _storage.getJsonList(_vodCategoriesCacheKey);
      if (categoriesResult.isSuccess && categoriesResult.data != null) {
        _cachedCategories = categoriesResult.data!
            .map((json) => _categoryFromJson(json))
            .whereType<DomainCategory>()
            .toList();
      }
    } catch (e) {
      moduleLogger.warning('Failed to load VOD categories from cache', tag: 'XtreamVod', error: e);
    }
  }

  Future<void> _saveItemsToCache(List<VodItem> items) async {
    try {
      final itemsJson = items.map((i) => _vodItemToJson(i)).toList();
      await _storage.setJsonList(_vodItemsCacheKey, itemsJson);
    } catch (e, stackTrace) {
      moduleLogger.error('Failed to save VOD items to cache', tag: 'XtreamVod', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _saveCategoriesToCache(List<DomainCategory> categories) async {
    try {
      final categoriesJson = categories.map((c) => _categoryToJson(c)).toList();
      await _storage.setJsonList(_vodCategoriesCacheKey, categoriesJson);
    } catch (e, stackTrace) {
      moduleLogger.error('Failed to save VOD categories to cache', tag: 'XtreamVod', error: e, stackTrace: stackTrace);
    }
  }

  Map<String, dynamic> _vodItemToJson(VodItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'streamUrl': item.streamUrl,
      'posterUrl': item.posterUrl,
      'backdropUrl': item.backdropUrl,
      'description': item.description,
      'categoryId': item.categoryId,
      'genre': item.genre,
      'releaseDate': item.releaseDate,
      'rating': item.rating,
      'duration': item.duration,
      'type': item.type.name,
      'metadata': item.metadata,
    };
  }

  VodItem? _vodItemFromJson(Map<String, dynamic> json) {
    try {
      return VodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        streamUrl: json['streamUrl'] as String,
        posterUrl: json['posterUrl'] as String?,
        backdropUrl: json['backdropUrl'] as String?,
        description: json['description'] as String?,
        categoryId: json['categoryId'] as String?,
        genre: json['genre'] as String?,
        releaseDate: json['releaseDate'] as String?,
        rating: json['rating'] as double?,
        duration: json['duration'] as int?,
        type: ContentType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ContentType.movie,
        ),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _categoryToJson(DomainCategory category) {
    return {
      'id': category.id,
      'name': category.name,
      'channelCount': category.channelCount,
      'iconUrl': category.iconUrl,
      'sortOrder': category.sortOrder,
    };
  }

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
      return null;
    }
  }
}

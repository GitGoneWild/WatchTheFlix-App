// Xtream Live TV Repository
// Repository for managing live TV channels with smart caching.

import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import '../../core/storage/storage_service.dart';
import '../account/xtream_api_client.dart';
import '../epg/xtream_epg_repository.dart';
import '../mappers/xtream_mappers.dart';
import '../models/xtream_api_models.dart';

/// Storage keys for live TV cache
const String _liveChannelsCacheKey = 'xtream_live_channels';
const String _liveCategoriesCacheKey = 'xtream_live_categories';
const String _liveChannelsTimestampKey = 'xtream_live_channels_timestamp';

/// Metadata key for EPG channel ID
const String _metadataKeyEpgChannelId = 'epgChannelId';

/// Xtream Live TV repository interface
abstract class IXtreamLiveRepository {
  /// Get all live channels
  Future<ApiResult<List<DomainChannel>>> getLiveChannels({
    String? categoryId,
    bool forceRefresh = false,
  });

  /// Get live categories
  Future<ApiResult<List<DomainCategory>>> getLiveCategories({
    bool forceRefresh = false,
  });

  /// Refresh live channels from server
  Future<ApiResult<void>> refreshLiveChannels();

  /// Clear live channels cache
  Future<ApiResult<void>> clearCache();
}

/// Xtream Live TV repository implementation
class XtreamLiveRepository implements IXtreamLiveRepository {
  XtreamLiveRepository({
    required XtreamApiClient apiClient,
    required IStorageService storage,
    IXtreamEpgRepository? epgRepository,
  })  : _apiClient = apiClient,
        _storage = storage,
        _epgRepository = epgRepository;

  final XtreamApiClient _apiClient;
  final IStorageService _storage;
  final IXtreamEpgRepository? _epgRepository;

  /// In-memory cache
  List<DomainChannel>? _cachedChannels;
  List<DomainCategory>? _cachedCategories;
  
  /// Flag to prevent multiple simultaneous background refreshes
  bool _isRefreshingChannels = false;
  bool _isRefreshingCategories = false;
  bool _isEnrichingEpg = false;

  @override
  Future<ApiResult<List<DomainChannel>>> getLiveChannels({
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    try {
      // Load from cache if needed
      if (_cachedChannels == null && !forceRefresh) {
        await _loadChannelsFromCache();
      }

      // Refresh in background if cache is stale (but still return cached data immediately)
      if (!forceRefresh && await _isCacheStale()) {
        // Trigger background refresh without waiting
        _refreshChannelsInBackground();
      } else if (forceRefresh) {
        // Only block on force refresh
        final refreshResult = await refreshLiveChannels();
        if (refreshResult.isFailure && _cachedChannels == null) {
          return ApiResult.failure(refreshResult.error);
        }
      }

      if (_cachedChannels == null) {
        return ApiResult.failure(
          const ApiError(
            type: ApiErrorType.notFound,
            message: 'No live channels available',
          ),
        );
      }

      // Filter by category if specified
      var channels = _cachedChannels!;
      if (categoryId != null) {
        channels = channels
            .where((c) => c.categoryId == categoryId)
            .toList();
      }

      // Enrich channels with category names
      channels = await _enrichChannelsWithCategoryNames(channels);

      // Enrich channels with EPG data in background (non-blocking)
      // Pass the full cache, not filtered channels, to avoid losing data
      if (_epgRepository != null && _cachedChannels != null) {
        // Fire and forget - EPG enrichment happens in background
        _enrichChannelsWithEpgInBackground(_cachedChannels!);
        // Return channels immediately without EPG data
      }

      return ApiResult.success(channels);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to get live channels',
        tag: 'XtreamLive',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<DomainCategory>>> getLiveCategories({
    bool forceRefresh = false,
  }) async {
    try {
      // Load from cache if needed
      if (_cachedCategories == null && !forceRefresh) {
        await _loadCategoriesFromCache();
      }

      // Refresh in background if cache is stale (but still return cached data immediately)
      if (!forceRefresh && await _isCacheStale()) {
        // Trigger background refresh without waiting
        _refreshCategoriesInBackground();
      } else if (forceRefresh) {
        // Only block on force refresh
        final categoriesResult = await _apiClient.getLiveCategories();
        if (categoriesResult.isSuccess) {
          _cachedCategories = categoriesResult.data
              .map((c) => XtreamMappers.liveCategoryToCategory(c))
              .toList();
          await _saveCategoriesToCache(_cachedCategories!);
        } else {
          // API call failed - try to extract categories from channels
          moduleLogger.warning(
            'Categories API failed, extracting from channels',
            tag: 'XtreamLive',
          );
          final extractedCategories = await _extractCategoriesFromChannels();
          if (extractedCategories.isNotEmpty) {
            _cachedCategories = extractedCategories;
            await _saveCategoriesToCache(_cachedCategories!);
            moduleLogger.info(
              'Extracted ${extractedCategories.length} categories from channels',
              tag: 'XtreamLive',
            );
          } else if (_cachedCategories == null) {
            return ApiResult.failure(categoriesResult.error);
          }
        }
      }

      if (_cachedCategories == null) {
        // Last resort: try to extract from channels
        final extractedCategories = await _extractCategoriesFromChannels();
        if (extractedCategories.isNotEmpty) {
          _cachedCategories = extractedCategories;
          await _saveCategoriesToCache(_cachedCategories!);
        } else {
          return ApiResult.failure(
            const ApiError(
              type: ApiErrorType.notFound,
              message: 'No live categories available',
            ),
          );
        }
      }

      return ApiResult.success(_cachedCategories!);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to get live categories',
        tag: 'XtreamLive',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Extract categories from cached channels when API fails
  Future<List<DomainCategory>> _extractCategoriesFromChannels() async {
    // Ensure channels are loaded
    if (_cachedChannels == null) {
      await _loadChannelsFromCache();
    }

    if (_cachedChannels == null || _cachedChannels!.isEmpty) {
      // Try to refresh channels first
      final refreshResult = await refreshLiveChannels();
      if (refreshResult.isFailure || _cachedChannels == null) {
        return [];
      }
    }

    // Extract unique categories from channels
    final categoryMap = <String, int>{};
    for (final channel in _cachedChannels!) {
      final categoryId = channel.categoryId;
      if (categoryId != null && categoryId.isNotEmpty) {
        categoryMap[categoryId] = (categoryMap[categoryId] ?? 0) + 1;
      }
    }

    // Convert to DomainCategory list
    final categories = categoryMap.entries.map((entry) {
      // Use groupTitle from first channel in this category for a better name
      final sampleChannel = _cachedChannels!.firstWhere(
        (c) => c.categoryId == entry.key,
        orElse: () => _cachedChannels!.first,
      );
      final categoryName = sampleChannel.groupTitle ?? 'Category ${entry.key}';

      return DomainCategory(
        id: entry.key,
        name: categoryName,
        channelCount: entry.value,
      );
    }).toList();

    // Sort by name
    categories.sort((a, b) => a.name.compareTo(b.name));

    return categories;
  }

  @override
  Future<ApiResult<void>> refreshLiveChannels() async {
    try {
      moduleLogger.info('Refreshing live channels', tag: 'XtreamLive');

      // Fetch streams from API
      final streamsResult = await _apiClient.getLiveStreams();
      if (streamsResult.isFailure) {
        return ApiResult.failure(streamsResult.error);
      }

      // Convert to domain channels
      _cachedChannels = streamsResult.data
          .map((s) => XtreamMappers.liveStreamToChannel(s, _apiClient))
          .toList();

      // Save to cache
      await _saveChannelsToCache(_cachedChannels!);
      await _updateCacheTimestamp();

      moduleLogger.info(
        'Refreshed ${_cachedChannels!.length} live channels',
        tag: 'XtreamLive',
      );

      return ApiResult.success(null);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to refresh live channels',
        tag: 'XtreamLive',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<void>> clearCache() async {
    try {
      moduleLogger.info('Clearing live channels cache', tag: 'XtreamLive');

      _cachedChannels = null;
      _cachedCategories = null;

      await _storage.remove(_liveChannelsCacheKey);
      await _storage.remove(_liveCategoriesCacheKey);
      await _storage.remove(_liveChannelsTimestampKey);

      moduleLogger.info('Live channels cache cleared', tag: 'XtreamLive');
      return ApiResult.success(null);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to clear live channels cache',
        tag: 'XtreamLive',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Refresh channels in background without blocking
  void _refreshChannelsInBackground() {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshingChannels) return;
    
    _isRefreshingChannels = true;
    
    // Fire and forget - don't await
    refreshLiveChannels().then((result) {
      if (result.isSuccess) {
        moduleLogger.info(
          'Background refresh completed successfully',
          tag: 'XtreamLive',
        );
      } else {
        moduleLogger.warning(
          'Background refresh failed: ${result.error.message}',
          tag: 'XtreamLive',
        );
      }
    }).catchError((error, stackTrace) {
      moduleLogger.error(
        'Background refresh error',
        tag: 'XtreamLive',
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      _isRefreshingChannels = false;
    });
  }

  /// Refresh categories in background without blocking
  void _refreshCategoriesInBackground() {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshingCategories) return;
    
    _isRefreshingCategories = true;
    
    // Fire and forget - don't await
    _apiClient.getLiveCategories().then((categoriesResult) {
      if (categoriesResult.isSuccess) {
        _cachedCategories = categoriesResult.data
            .map((c) => XtreamMappers.liveCategoryToCategory(c))
            .toList();
        _saveCategoriesToCache(_cachedCategories!);
        moduleLogger.info(
          'Background categories refresh completed',
          tag: 'XtreamLive',
        );
      } else {
        moduleLogger.warning(
          'Background categories refresh failed: ${categoriesResult.error.message}',
          tag: 'XtreamLive',
        );
      }
    }).catchError((error, stackTrace) {
      moduleLogger.error(
        'Background categories refresh error',
        tag: 'XtreamLive',
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      _isRefreshingCategories = false;
    });
  }

  /// Check if cache is stale
  Future<bool> _isCacheStale() async {
    final timestampResult = await _storage.getInt(_liveChannelsTimestampKey);

    if (timestampResult.isFailure || timestampResult.data == null) {
      return true; // No timestamp or null, consider stale
    }

    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
      timestampResult.data!,
    );
    final cacheAge = DateTime.now().difference(lastUpdate);
    final maxAge = AppConfig().cacheExpiration;

    return cacheAge > maxAge;
  }

  /// Update cache timestamp
  Future<void> _updateCacheTimestamp() async {
    await _storage.setInt(
      _liveChannelsTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Load channels from cache
  Future<void> _loadChannelsFromCache() async {
    try {
      final channelsResult = await _storage.getJsonList(_liveChannelsCacheKey);

      if (channelsResult.isSuccess && channelsResult.data != null) {
        _cachedChannels = channelsResult.data!
            .map((json) => _channelFromJson(json))
            .whereType<DomainChannel>()
            .toList();

        moduleLogger.info(
          'Loaded ${_cachedChannels!.length} live channels from cache',
          tag: 'XtreamLive',
        );
      }
    } catch (e) {
      moduleLogger.warning(
        'Failed to load live channels from cache',
        tag: 'XtreamLive',
        error: e,
      );
    }
  }

  /// Load categories from cache
  Future<void> _loadCategoriesFromCache() async {
    try {
      final categoriesResult = await _storage.getJsonList(
        _liveCategoriesCacheKey,
      );

      if (categoriesResult.isSuccess && categoriesResult.data != null) {
        _cachedCategories = categoriesResult.data!
            .map((json) => _categoryFromJson(json))
            .whereType<DomainCategory>()
            .toList();

        moduleLogger.info(
          'Loaded ${_cachedCategories!.length} live categories from cache',
          tag: 'XtreamLive',
        );
      }
    } catch (e) {
      moduleLogger.warning(
        'Failed to load live categories from cache',
        tag: 'XtreamLive',
        error: e,
      );
    }
  }

  /// Save channels to cache
  Future<void> _saveChannelsToCache(List<DomainChannel> channels) async {
    try {
      final channelsJson = channels.map((c) => _channelToJson(c)).toList();
      await _storage.setJsonList(_liveChannelsCacheKey, channelsJson);
      moduleLogger.info('Live channels saved to cache', tag: 'XtreamLive');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save live channels to cache',
        tag: 'XtreamLive',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Save categories to cache
  Future<void> _saveCategoriesToCache(List<DomainCategory> categories) async {
    try {
      final categoriesJson = categories.map((c) => _categoryToJson(c)).toList();
      await _storage.setJsonList(_liveCategoriesCacheKey, categoriesJson);
      moduleLogger.info('Live categories saved to cache', tag: 'XtreamLive');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save live categories to cache',
        tag: 'XtreamLive',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Convert channel to JSON
  Map<String, dynamic> _channelToJson(DomainChannel channel) {
    return {
      'id': channel.id,
      'name': channel.name,
      'streamUrl': channel.streamUrl,
      'logoUrl': channel.logoUrl,
      'groupTitle': channel.groupTitle,
      'categoryId': channel.categoryId,
      'type': channel.type.name,
      'metadata': channel.metadata,
    };
  }

  /// Convert JSON to channel
  DomainChannel? _channelFromJson(Map<String, dynamic> json) {
    try {
      return DomainChannel(
        id: json['id'] as String,
        name: json['name'] as String,
        streamUrl: json['streamUrl'] as String,
        logoUrl: json['logoUrl'] as String?,
        groupTitle: json['groupTitle'] as String?,
        categoryId: json['categoryId'] as String?,
        type: ContentType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ContentType.live,
        ),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      moduleLogger.warning(
        'Failed to parse channel from JSON',
        tag: 'XtreamLive',
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
        'Failed to parse category from JSON',
        tag: 'XtreamLive',
        error: e,
      );
      return null;
    }
  }

  /// Enrich channels with category names from cached categories
  Future<List<DomainChannel>> _enrichChannelsWithCategoryNames(
    List<DomainChannel> channels,
  ) async {
    // Ensure categories are loaded
    if (_cachedCategories == null) {
      await _loadCategoriesFromCache();
    }

    // If still no categories, try to fetch them
    if (_cachedCategories == null) {
      final categoriesResult = await _apiClient.getLiveCategories();
      if (categoriesResult.isSuccess) {
        _cachedCategories = categoriesResult.data
            .map((c) => XtreamMappers.liveCategoryToCategory(c))
            .toList();
      }
    }

    // Build category name map
    final categoryNameMap = <String, String>{};
    if (_cachedCategories != null) {
      for (final category in _cachedCategories!) {
        categoryNameMap[category.id] = category.name;
      }
    }

    // Enrich channels with category names
    return channels.map((channel) {
      if (channel.categoryId != null) {
        final categoryName = categoryNameMap[channel.categoryId];
        if (categoryName != null) {
          return channel.copyWith(groupTitle: categoryName);
        }
      }
      return channel;
    }).toList();
  }

  /// Enrich channels with EPG data in background (non-blocking)
  void _enrichChannelsWithEpgInBackground(List<DomainChannel> channels) {
    // Atomically check and set the flag to prevent concurrent enrichment
    if (_isEnrichingEpg) {
      moduleLogger.info(
        'EPG enrichment already in progress, skipping',
        tag: 'XtreamLive',
      );
      return;
    }
    
    // Set flag immediately to prevent race condition
    _isEnrichingEpg = true;

    // Fire and forget - don't block the main flow
    Future.microtask(() async {
      try {
        moduleLogger.info(
          'Starting background EPG enrichment for ${channels.length} channels',
          tag: 'XtreamLive',
        );

        // Create updated channels list to avoid race conditions
        final updatedChannels = <DomainChannel>[];

        for (final channel in channels) {
          try {
            // Get EPG channel ID from metadata
            final epgChannelId =
                channel.metadata?[_metadataKeyEpgChannelId] as String?;

            if (epgChannelId == null || epgChannelId.isEmpty) {
              updatedChannels.add(channel);
              continue;
            }

            // Fetch current and next program
            final epgResult = await _epgRepository!.getCurrentAndNextProgram(
              epgChannelId,
            );

            if (epgResult.isSuccess) {
              final epgPair = epgResult.data;
              final current = epgPair.current;
              final next = epgPair.next;

              // Create EPG info
              final epgInfo = EpgInfo(
                currentProgram: current?.title,
                nextProgram: next?.title,
                startTime: current?.start,
                endTime: current?.stop,
                description: current?.description,
              );

              // Add updated channel with EPG info
              updatedChannels.add(channel.copyWith(epgInfo: epgInfo));
            } else {
              updatedChannels.add(channel);
            }
          } catch (e) {
            moduleLogger.warning(
              'Failed to enrich channel ${channel.name} with EPG in background',
              tag: 'XtreamLive',
              error: e,
            );
            updatedChannels.add(channel);
          }
        }

        // Atomically update the cache with enriched channels
        _cachedChannels = updatedChannels;

        moduleLogger.info(
          'Background EPG enrichment completed',
          tag: 'XtreamLive',
        );
      } catch (e, stackTrace) {
        moduleLogger.error(
          'Error during background EPG enrichment',
          tag: 'XtreamLive',
          error: e,
          stackTrace: stackTrace,
        );
      } finally {
        _isEnrichingEpg = false;
      }
    });
  }
}

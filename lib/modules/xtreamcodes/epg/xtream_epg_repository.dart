// Xtream EPG Repository
// Repository for managing EPG data with smart caching strategy.

import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import '../../core/storage/storage_service.dart';
import '../account/xtream_api_client.dart';
import 'epg_models.dart';
import 'xmltv_parser.dart';

/// Storage keys for EPG cache
const String _epgCacheMetadataKey = 'xtream_epg_metadata';
const String _epgProgramsCacheKey = 'xtream_epg_programs';

/// Xtream EPG repository interface
abstract class IXtreamEpgRepository {
  /// Get EPG programs for a channel
  Future<ApiResult<List<EpgProgram>>> getEpgForChannel(
    String channelId, {
    DateTime? day,
  });

  /// Get current and next program for a channel
  Future<ApiResult<EpgProgramPair>> getCurrentAndNextProgram(String channelId);

  /// Refresh EPG data from server
  Future<ApiResult<void>> refreshEpg({bool force = false});

  /// Check if EPG cache is stale
  Future<bool> isCacheStale();

  /// Clear EPG cache
  Future<ApiResult<void>> clearCache();
}

/// Pair of current and next EPG programs
class EpgProgramPair {
  const EpgProgramPair({
    this.current,
    this.next,
  });

  final EpgProgram? current;
  final EpgProgram? next;
}

/// Xtream EPG repository implementation
class XtreamEpgRepository implements IXtreamEpgRepository {
  XtreamEpgRepository({
    required XtreamApiClient apiClient,
    required IXmltvParser xmltvParser,
    required IStorageService storage,
  })  : _apiClient = apiClient,
        _xmltvParser = xmltvParser,
        _storage = storage;

  final XtreamApiClient _apiClient;
  final IXmltvParser _xmltvParser;
  final IStorageService _storage;

  /// In-memory cache for fast access
  List<EpgProgram>? _cachedPrograms;
  bool _isRefreshing = false;

  @override
  Future<ApiResult<List<EpgProgram>>> getEpgForChannel(
    String channelId, {
    DateTime? day,
  }) async {
    try {
      // Try to load from cache first
      if (_cachedPrograms == null) {
        await _loadFromStorage();
      }

      // Refresh in background if cache is stale (non-blocking)
      if (await isCacheStale()) {
        // Fire and forget - refresh happens in background
        _refreshEpgInBackground();
      }

      if (_cachedPrograms == null) {
        return ApiResult.failure(
          const ApiError(
            type: ApiErrorType.notFound,
            message: 'No EPG data available',
          ),
        );
      }

      // Filter programs for the channel
      var programs = _cachedPrograms!
          .where((p) => p.channelId == channelId)
          .toList();

      // Filter by day if specified
      if (day != null) {
        final startOfDay = DateTime(day.year, day.month, day.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        programs = programs
            .where((p) => p.start.isAfter(startOfDay) && p.start.isBefore(endOfDay))
            .toList();
      }

      // Sort by start time
      programs.sort((a, b) => a.start.compareTo(b.start));

      return ApiResult.success(programs);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to get EPG for channel',
        tag: 'XtreamEpg',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<EpgProgramPair>> getCurrentAndNextProgram(
    String channelId,
  ) async {
    final result = await getEpgForChannel(channelId);

    if (result.isFailure) {
      return ApiResult.failure(result.error);
    }

    final programs = result.data;
    final now = DateTime.now();

    EpgProgram? current;
    EpgProgram? next;

    for (var i = 0; i < programs.length; i++) {
      final program = programs[i];
      
      if (program.isLive) {
        current = program;
        // Get next program if available
        if (i + 1 < programs.length) {
          next = programs[i + 1];
        }
        break;
      } else if (program.isUpcoming && current == null) {
        next = program;
        break;
      }
    }

    return ApiResult.success(EpgProgramPair(current: current, next: next));
  }

  @override
  Future<ApiResult<void>> refreshEpg({bool force = false}) async {
    // Prevent concurrent refreshes
    if (_isRefreshing) {
      moduleLogger.info('EPG refresh already in progress', tag: 'XtreamEpg');
      return ApiResult.success(null);
    }

    try {
      _isRefreshing = true;

      // Check if refresh is needed
      if (!force && !await isCacheStale()) {
        moduleLogger.info('EPG cache is still fresh', tag: 'XtreamEpg');
        return ApiResult.success(null);
      }

      moduleLogger.info('Refreshing EPG from server', tag: 'XtreamEpg');

      // Download XMLTV data
      final xmlResult = await _apiClient.downloadXmltvEpg();
      if (xmlResult.isFailure) {
        return ApiResult.failure(xmlResult.error);
      }

      // Parse XMLTV data
      final parseResult = _xmltvParser.parse(xmlResult.data);
      if (parseResult.isFailure) {
        return ApiResult.failure(parseResult.error);
      }

      final xmltvData = parseResult.data;

      // Filter programs to keep only relevant time window (today + tomorrow)
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfTomorrow = startOfToday.add(const Duration(days: 2));

      final filteredPrograms = xmltvData.programs
          .where((p) =>
              p.stop.isAfter(startOfToday) && p.start.isBefore(endOfTomorrow))
          .toList();

      // Update in-memory cache
      _cachedPrograms = filteredPrograms;

      // Save to storage
      await _saveToStorage(filteredPrograms, xmltvData.channels.length);

      moduleLogger.info(
        'EPG refreshed: ${filteredPrograms.length} programs cached',
        tag: 'XtreamEpg',
      );

      return ApiResult.success(null);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to refresh EPG',
        tag: 'XtreamEpg',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Future<bool> isCacheStale() async {
    final metadataResult = await _storage.getJson(_epgCacheMetadataKey);

    if (metadataResult.isFailure) {
      return true; // No cache, consider stale
    }

    try {
      final metadata = EpgCacheMetadata.fromJson(metadataResult.data!);
      final cacheAge = DateTime.now().difference(metadata.lastUpdated);
      final maxAge = AppConfig().epgCacheExpiration;

      return cacheAge > maxAge;
    } catch (e) {
      moduleLogger.warning(
        'Failed to parse cache metadata',
        tag: 'XtreamEpg',
        error: e,
      );
      return true;
    }
  }

  @override
  Future<ApiResult<void>> clearCache() async {
    try {
      moduleLogger.info('Clearing EPG cache', tag: 'XtreamEpg');

      _cachedPrograms = null;

      await _storage.remove(_epgCacheMetadataKey);
      await _storage.remove(_epgProgramsCacheKey);

      moduleLogger.info('EPG cache cleared', tag: 'XtreamEpg');
      return ApiResult.success(null);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to clear EPG cache',
        tag: 'XtreamEpg',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Load programs from storage
  Future<void> _loadFromStorage() async {
    try {
      final programsResult = await _storage.getJsonList(_epgProgramsCacheKey);

      if (programsResult.isSuccess && programsResult.data != null) {
        _cachedPrograms = programsResult.data!
            .map((json) => _programFromJson(json))
            .whereType<EpgProgram>()
            .toList();

        moduleLogger.info(
          'Loaded ${_cachedPrograms!.length} programs from cache',
          tag: 'XtreamEpg',
        );
      }
    } catch (e) {
      moduleLogger.warning(
        'Failed to load EPG from storage',
        tag: 'XtreamEpg',
        error: e,
      );
    }
  }

  /// Save programs to storage
  Future<void> _saveToStorage(
    List<EpgProgram> programs,
    int channelCount,
  ) async {
    try {
      // Save programs
      final programsJson = programs.map((p) => _programToJson(p)).toList();
      await _storage.setJsonList(_epgProgramsCacheKey, programsJson);

      // Save metadata
      final metadata = EpgCacheMetadata(
        lastUpdated: DateTime.now(),
        programCount: programs.length,
        channelCount: channelCount,
        startDate: programs.isNotEmpty ? programs.first.start : null,
        endDate: programs.isNotEmpty ? programs.last.stop : null,
      );
      await _storage.setJson(_epgCacheMetadataKey, metadata.toJson());

      moduleLogger.info('EPG data saved to storage', tag: 'XtreamEpg');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save EPG to storage',
        tag: 'XtreamEpg',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Refresh EPG in background without blocking
  void _refreshEpgInBackground() {
    // Fire and forget - refresh happens asynchronously
    refreshEpg().then((result) {
      if (result.isSuccess) {
        moduleLogger.info(
          'Background EPG refresh completed successfully',
          tag: 'XtreamEpg',
        );
      } else {
        moduleLogger.warning(
          'Background EPG refresh failed: ${result.error.message}',
          tag: 'XtreamEpg',
        );
      }
    }).catchError((error, stackTrace) {
      moduleLogger.error(
        'Background EPG refresh error',
        tag: 'XtreamEpg',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  /// Convert program to JSON
  Map<String, dynamic> _programToJson(EpgProgram program) {
    return {
      'channelId': program.channelId,
      'start': program.start.toIso8601String(),
      'stop': program.stop.toIso8601String(),
      'title': program.title,
      'description': program.description,
      'category': program.category,
      'icon': program.icon,
    };
  }

  /// Convert JSON to program
  EpgProgram? _programFromJson(Map<String, dynamic> json) {
    try {
      return EpgProgram(
        channelId: json['channelId'] as String,
        start: DateTime.parse(json['start'] as String),
        stop: DateTime.parse(json['stop'] as String),
        title: json['title'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
        icon: json['icon'] as String?,
      );
    } catch (e) {
      moduleLogger.warning(
        'Failed to parse program from JSON',
        tag: 'XtreamEpg',
        error: e,
      );
      return null;
    }
  }
}

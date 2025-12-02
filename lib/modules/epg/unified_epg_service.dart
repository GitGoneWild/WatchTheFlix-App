// Unified EPG Service
// High-level service for EPG operations across the application.

import '../core/logging/app_logger.dart';
import '../core/models/api_result.dart';
import '../core/models/base_models.dart';
import '../xtreamcodes/epg/epg_models.dart';
import '../xtreamcodes/epg/epg_service.dart';
import '../xtreamcodes/repositories/epg_repository_impl.dart';
import 'epg_source.dart';
import 'unified_epg_repository.dart';
import 'url_epg_provider.dart';

/// Unified EPG service that provides a high-level interface for EPG operations.
///
/// This service:
/// - Manages EPG source configuration
/// - Provides methods to fetch, refresh, and query EPG data
/// - Handles both URL-based and Xtream Codes EPG sources
/// - Integrates with local storage for persistence
class UnifiedEpgService {
  UnifiedEpgService({
    UnifiedEpgRepository? repository,
    EpgRepositoryImpl? xtreamRepository,
    EpgSourceConfig? initialConfig,
  })  : _repository = repository ??
            UnifiedEpgRepository(
              urlProvider: UrlEpgProvider(),
              xtreamRepository: xtreamRepository,
            ),
        _xtreamRepository = xtreamRepository,
        _sourceConfig = initialConfig ?? EpgSourceConfig.none() {
    if (_sourceConfig.isConfigured) {
      _repository.configure(_sourceConfig);
    }
  }
  final UnifiedEpgRepository _repository;
  final EpgRepositoryImpl? _xtreamRepository;

  /// Current EPG source configuration.
  EpgSourceConfig _sourceConfig;

  /// Xtream credentials (if using Xtream source).
  XtreamCredentialsModel? _xtreamCredentials;

  /// Get current EPG source configuration.
  EpgSourceConfig get sourceConfig => _sourceConfig;

  /// Get current Xtream credentials (if any).
  XtreamCredentialsModel? get xtreamCredentials => _xtreamCredentials;

  /// Check if EPG is configured.
  bool get isConfigured => _sourceConfig.isConfigured;

  /// Check if EPG data is available.
  bool get hasData => _repository.hasCachedData();

  // ============ Configuration Methods ============

  /// Configure EPG to use a URL source.
  ///
  /// [url] The URL to fetch EPG data from (XMLTV format).
  /// [refreshInterval] How often to refresh EPG data.
  /// [autoRefresh] Whether to enable automatic refresh.
  void configureUrl(
    String url, {
    Duration refreshInterval = const Duration(hours: 6),
    bool autoRefresh = true,
  }) {
    _sourceConfig = EpgSourceConfig.fromUrl(
      url,
      refreshInterval: refreshInterval,
      autoRefreshEnabled: autoRefresh,
    );
    _xtreamCredentials = null;
    _repository.configure(_sourceConfig);
    moduleLogger.info(
      'EPG configured for URL source: $url',
      tag: 'UnifiedEpgService',
    );
  }

  /// Configure EPG to use Xtream Codes source.
  ///
  /// [profileId] The profile ID for storage/caching.
  /// [credentials] The Xtream Codes credentials.
  /// [refreshInterval] How often to refresh EPG data.
  /// [autoRefresh] Whether to enable automatic refresh.
  void configureXtream(
    String profileId,
    XtreamCredentialsModel credentials, {
    Duration refreshInterval = const Duration(hours: 6),
    bool autoRefresh = true,
  }) {
    _sourceConfig = EpgSourceConfig.fromXtreamCodes(
      profileId,
      refreshInterval: refreshInterval,
      autoRefreshEnabled: autoRefresh,
    );
    _xtreamCredentials = credentials;
    _repository.configure(_sourceConfig);
    moduleLogger.info(
      'EPG configured for Xtream source: ${credentials.baseUrl}',
      tag: 'UnifiedEpgService',
    );
  }

  /// Clear EPG configuration.
  void clearConfiguration() {
    _sourceConfig = EpgSourceConfig.none();
    _xtreamCredentials = null;
    _repository.clearCache();
    moduleLogger.info('EPG configuration cleared', tag: 'UnifiedEpgService');
  }

  // ============ Data Fetching Methods ============

  /// Fetch EPG data from the configured source.
  ///
  /// [forceRefresh] If true, bypass cache and fetch fresh data.
  Future<ApiResult<EpgData>> fetchEpg({bool forceRefresh = false}) async {
    if (!_sourceConfig.isConfigured) {
      return ApiResult.failure(
        const ApiError(
          type: ApiErrorType.validation,
          message: 'EPG source not configured',
        ),
      );
    }

    final result = await _repository.fetchEpg(
      forceRefresh: forceRefresh,
      credentials: _xtreamCredentials,
    );

    if (result.isSuccess) {
      // Update the config with last fetch time
      _sourceConfig = _sourceConfig.copyWithLastFetch(DateTime.now());
    }

    return result;
  }

  /// Refresh EPG data (bypasses cache).
  Future<ApiResult<EpgData>> refresh() async {
    return fetchEpg(forceRefresh: true);
  }

  /// Get cached EPG data if available.
  EpgData? getCachedData() {
    return _repository.getCachedData();
  }

  // ============ EPG Query Methods ============

  /// Get current program for a channel.
  Future<ApiResult<EpgProgram?>> getCurrentProgram(String channelId) async {
    return _repository.getCurrentProgram(
      channelId,
      credentials: _xtreamCredentials,
    );
  }

  /// Get next program for a channel.
  Future<ApiResult<EpgProgram?>> getNextProgram(String channelId) async {
    return _repository.getNextProgram(
      channelId,
      credentials: _xtreamCredentials,
    );
  }

  /// Get current and next program info for display.
  Future<ApiResult<EpgInfo>> getCurrentAndNextInfo(String channelId) async {
    try {
      final epgResult = await fetchEpg();
      if (epgResult.isFailure) {
        return ApiResult.failure(epgResult.error);
      }

      final current = epgResult.data.getCurrentProgram(channelId);
      final next = epgResult.data.getNextProgram(channelId);

      return ApiResult.success(
        EpgInfo(
          currentProgram: current?.title,
          nextProgram: next?.title,
          startTime: current?.startTime,
          endTime: current?.endTime,
          description: current?.description,
        ),
      );
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get daily schedule for a channel.
  Future<ApiResult<List<EpgProgram>>> getDailySchedule(
    String channelId,
    DateTime date,
  ) async {
    return _repository.getDailySchedule(
      channelId,
      date,
      credentials: _xtreamCredentials,
    );
  }

  /// Get programs in a time range for a channel.
  Future<ApiResult<List<EpgProgram>>> getProgramsInRange(
    String channelId,
    DateTime start,
    DateTime end,
  ) async {
    return _repository.getProgramsInRange(
      channelId,
      start,
      end,
      credentials: _xtreamCredentials,
    );
  }

  /// Get all programs for a channel.
  Future<ApiResult<List<EpgProgram>>> getChannelPrograms(
    String channelId,
  ) async {
    final epgResult = await fetchEpg();
    if (epgResult.isFailure) {
      return ApiResult.failure(epgResult.error);
    }

    final programs = epgResult.data.getChannelPrograms(channelId);
    return ApiResult.success(programs);
  }

  // ============ Utility Methods ============

  /// Validate an EPG URL without fetching full content.
  Future<ApiResult<bool>> validateUrl(String url) async {
    final provider = UrlEpgProvider();
    return provider.validateUrl(url);
  }

  /// Test Xtream Codes EPG connection.
  Future<ApiResult<bool>> testXtreamConnection(
    XtreamCredentialsModel credentials,
  ) async {
    if (_xtreamRepository == null) {
      return ApiResult.failure(
        const ApiError(
          type: ApiErrorType.validation,
          message: 'Xtream repository not configured',
        ),
      );
    }

    final result = await _xtreamRepository.fetchFullXmltvEpg(credentials);
    return ApiResult.success(result.isSuccess && result.data.isNotEmpty);
  }

  /// Check if EPG data needs refresh.
  bool get needsRefresh => _sourceConfig.needsRefresh;

  /// Clear all cached EPG data.
  void clearCache() {
    _repository.clearCache();
    moduleLogger.info('EPG cache cleared', tag: 'UnifiedEpgService');
  }

  /// Get EPG statistics.
  Map<String, dynamic> getStatistics() {
    final cached = getCachedData();
    return {
      'sourceType': _sourceConfig.type.name,
      'isConfigured': isConfigured,
      'hasData': hasData,
      'channelCount': cached?.channels.length ?? 0,
      'programCount': cached?.totalPrograms ?? 0,
      'lastFetched': _sourceConfig.lastFetchedAt?.toIso8601String(),
      'needsRefresh': needsRefresh,
    };
  }
}

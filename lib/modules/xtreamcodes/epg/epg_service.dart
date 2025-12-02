// EpgService
// Service for managing Electronic Program Guide (EPG) data.
// Supports both full XMLTV EPG and per-channel short EPG.

import '../../core/logging/app_logger.dart';
import '../../core/models/api_result.dart';
import '../../core/models/base_models.dart';
import 'epg_models.dart';

/// EPG entry model for program listings (legacy format from short EPG API).
class EpgEntry {
  final String channelId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? language;

  const EpgEntry({
    required this.channelId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.language,
  });

  /// Check if this program is currently airing.
  bool get isCurrentlyAiring {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Calculate progress percentage (0.0 to 1.0).
  double get progress {
    if (!isCurrentlyAiring) return 0.0;
    final now = DateTime.now();
    final totalDuration = endTime.difference(startTime).inSeconds;
    final elapsed = now.difference(startTime).inSeconds;
    return totalDuration > 0 ? elapsed / totalDuration : 0.0;
  }

  /// Duration of the program.
  Duration get duration => endTime.difference(startTime);

  factory EpgEntry.fromJson(Map<String, dynamic> json) {
    final startTime = _parseDateTime(json['start'] ?? json['start_timestamp']);
    final endTime = _parseDateTime(json['end'] ?? json['stop_timestamp']);

    return EpgEntry(
      channelId: json['epg_id']?.toString() ?? json['channel_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? json['desc']?.toString(),
      startTime: startTime ?? DateTime.now(),
      endTime: endTime ?? DateTime.now().add(const Duration(hours: 1)),
      language: json['lang']?.toString(),
    );
  }

  /// Create from EpgProgram (from XMLTV data).
  factory EpgEntry.fromEpgProgram(EpgProgram program) {
    return EpgEntry(
      channelId: program.channelId,
      title: program.title,
      description: program.description,
      startTime: program.startTime,
      endTime: program.endTime,
      language: program.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'title': title,
      'description': description,
      'start': startTime.millisecondsSinceEpoch ~/ 1000,
      'end': endTime.millisecondsSinceEpoch ~/ 1000,
      'lang': language,
    };
  }

  /// Convert to EpgInfo domain model.
  EpgInfo toEpgInfo() {
    return EpgInfo(
      currentProgram: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final timestamp = int.tryParse(value);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    }
    return null;
  }
}

/// EPG service interface.
abstract class IEpgService {
  /// Get EPG for a specific channel using short EPG API.
  Future<ApiResult<List<EpgEntry>>> getChannelEpg(
    XtreamCredentialsModel credentials,
    String channelId, {
    int limit,
  });

  /// Get EPG for all channels using short EPG API.
  Future<ApiResult<Map<String, List<EpgEntry>>>> getAllEpg(
    XtreamCredentialsModel credentials,
  );

  /// Get current and next program for a channel.
  Future<ApiResult<EpgEntry?>> getCurrentProgram(
    XtreamCredentialsModel credentials,
    String channelId,
  );

  /// Refresh EPG data.
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials);

  /// Get full XMLTV EPG data (preferred method).
  Future<ApiResult<EpgData>> getFullEpg(XtreamCredentialsModel credentials);

  /// Get daily schedule for a channel.
  Future<ApiResult<List<EpgProgram>>> getDailySchedule(
    XtreamCredentialsModel credentials,
    String channelId,
    DateTime date,
  );
}

/// EPG service implementation.
class EpgService implements IEpgService {
  final EpgRepository _repository;

  EpgService({required EpgRepository repository}) : _repository = repository;

  @override
  Future<ApiResult<List<EpgEntry>>> getChannelEpg(
    XtreamCredentialsModel credentials,
    String channelId, {
    int limit = 10,
  }) async {
    try {
      moduleLogger.info('Fetching EPG for channel $channelId', tag: 'EPG');
      return await _repository.fetchChannelEpg(
        credentials,
        channelId,
        limit: limit,
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch channel EPG',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<Map<String, List<EpgEntry>>>> getAllEpg(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      moduleLogger.info('Fetching all EPG data', tag: 'EPG');
      return await _repository.fetchAllEpg(credentials);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch all EPG',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<EpgEntry?>> getCurrentProgram(
    XtreamCredentialsModel credentials,
    String channelId,
  ) async {
    try {
      // Try to get from full EPG first (more efficient if cached)
      final fullEpgResult = await _repository.fetchFullXmltvEpg(credentials);
      if (fullEpgResult.isSuccess && fullEpgResult.data.isNotEmpty) {
        final program = fullEpgResult.data.getCurrentProgram(channelId);
        if (program != null) {
          return ApiResult.success(EpgEntry.fromEpgProgram(program));
        }
      }

      // Fall back to short EPG API
      final result = await getChannelEpg(credentials, channelId, limit: 2);

      if (result.isFailure) {
        return ApiResult.failure(result.error);
      }

      final epgList = result.data;
      for (final entry in epgList) {
        if (entry.isCurrentlyAiring) {
          return ApiResult.success(entry);
        }
      }

      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials) async {
    try {
      moduleLogger.info('Refreshing EPG data', tag: 'EPG');
      return await _repository.refresh(credentials);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<EpgData>> getFullEpg(
    XtreamCredentialsModel credentials,
  ) async {
    try {
      moduleLogger.info('Fetching full XMLTV EPG', tag: 'EPG');
      return await _repository.fetchFullXmltvEpg(credentials);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch full EPG',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<List<EpgProgram>>> getDailySchedule(
    XtreamCredentialsModel credentials,
    String channelId,
    DateTime date,
  ) async {
    try {
      moduleLogger.info(
        'Fetching daily schedule for channel $channelId on $date',
        tag: 'EPG',
      );
      final result = await _repository.fetchFullXmltvEpg(credentials);
      if (result.isFailure) {
        return ApiResult.failure(result.error);
      }

      final schedule = result.data.getDailySchedule(channelId, date);
      return ApiResult.success(schedule);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to fetch daily schedule',
        tag: 'EPG',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get next program for a channel.
  Future<ApiResult<EpgEntry?>> getNextProgram(
    XtreamCredentialsModel credentials,
    String channelId,
  ) async {
    try {
      final result = await _repository.fetchFullXmltvEpg(credentials);
      if (result.isFailure) {
        return ApiResult.failure(result.error);
      }

      final program = result.data.getNextProgram(channelId);
      if (program != null) {
        return ApiResult.success(EpgEntry.fromEpgProgram(program));
      }
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  /// Get current and next program info for display.
  Future<ApiResult<EpgInfo>> getCurrentAndNextInfo(
    XtreamCredentialsModel credentials,
    String channelId,
  ) async {
    try {
      final result = await _repository.fetchFullXmltvEpg(credentials);
      if (result.isFailure) {
        return ApiResult.failure(result.error);
      }

      final current = result.data.getCurrentProgram(channelId);
      final next = result.data.getNextProgram(channelId);

      return ApiResult.success(EpgInfo(
        currentProgram: current?.title,
        nextProgram: next?.title,
        startTime: current?.startTime,
        endTime: current?.endTime,
        description: current?.description,
      ));
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}

/// EPG repository interface.
abstract class EpgRepository {
  /// Fetch EPG for a specific channel using short EPG API.
  Future<ApiResult<List<EpgEntry>>> fetchChannelEpg(
    XtreamCredentialsModel credentials,
    String channelId, {
    int limit,
  });

  /// Fetch EPG for all channels using short EPG API.
  Future<ApiResult<Map<String, List<EpgEntry>>>> fetchAllEpg(
    XtreamCredentialsModel credentials,
  );

  /// Fetch full XMLTV EPG data.
  Future<ApiResult<EpgData>> fetchFullXmltvEpg(
    XtreamCredentialsModel credentials,
  );

  /// Refresh cached EPG data.
  Future<ApiResult<void>> refresh(XtreamCredentialsModel credentials);
}

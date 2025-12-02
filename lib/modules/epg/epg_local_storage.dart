// EPG Local Storage
// Provides local persistence for EPG data from any source.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/app_logger.dart';
import '../xtreamcodes/epg/epg_models.dart';
import 'epg_source.dart';

/// Key prefix for EPG storage.
const String _epgStoragePrefix = 'epg_';

/// Key for EPG source configuration.
const String _epgConfigKey = '${_epgStoragePrefix}config';

/// Key prefix for EPG data storage.
const String _epgDataPrefix = '${_epgStoragePrefix}data_';

/// Key for EPG metadata.
const String _epgMetadataPrefix = '${_epgStoragePrefix}meta_';

/// EPG metadata for tracking cache state.
class EpgStorageMetadata {
  const EpgStorageMetadata({
    required this.sourceId,
    this.lastFetchedAt,
    this.channelCount = 0,
    this.programCount = 0,
    this.sourceUrl,
    this.sourceType = EpgSourceType.none,
  });

  factory EpgStorageMetadata.fromJson(Map<String, dynamic> json) {
    return EpgStorageMetadata(
      sourceId: json['sourceId'] as String? ?? '',
      lastFetchedAt: json['lastFetchedAt'] != null
          ? DateTime.tryParse(json['lastFetchedAt'] as String)
          : null,
      channelCount: json['channelCount'] as int? ?? 0,
      programCount: json['programCount'] as int? ?? 0,
      sourceUrl: json['sourceUrl'] as String?,
      sourceType: EpgSourceType.values.firstWhere(
        (e) => e.name == json['sourceType'],
        orElse: () => EpgSourceType.none,
      ),
    );
  }

  /// Profile or source identifier.
  final String sourceId;

  /// When the EPG was last fetched.
  final DateTime? lastFetchedAt;

  /// Number of channels in the EPG.
  final int channelCount;

  /// Number of programs in the EPG.
  final int programCount;

  /// Source URL (if applicable).
  final String? sourceUrl;

  /// Source type.
  final EpgSourceType sourceType;

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'lastFetchedAt': lastFetchedAt?.toIso8601String(),
        'channelCount': channelCount,
        'programCount': programCount,
        'sourceUrl': sourceUrl,
        'sourceType': sourceType.name,
      };
}

/// Local storage service for EPG data.
///
/// Uses SharedPreferences for lightweight EPG caching.
/// For larger datasets, consider using Hive or SQLite.
class EpgLocalStorage {
  SharedPreferences? _prefs;

  /// Check if storage is initialized.
  bool get isInitialized => _prefs != null;

  /// Initialize the storage.
  Future<void> initialize() async {
    if (_prefs != null) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      moduleLogger.info('EPG local storage initialized', tag: 'EpgStorage');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to initialize EPG storage',
        tag: 'EpgStorage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Ensure storage is initialized.
  void _ensureInitialized() {
    if (_prefs == null) {
      throw StateError(
          'EpgLocalStorage not initialized. Call initialize() first.');
    }
  }

  // ============ Configuration Storage ============

  /// Save EPG source configuration.
  Future<void> saveConfig(EpgSourceConfig config) async {
    _ensureInitialized();
    try {
      final json = jsonEncode(config.toJson());
      await _prefs!.setString(_epgConfigKey, json);
      moduleLogger.debug('EPG config saved', tag: 'EpgStorage');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save EPG config',
        tag: 'EpgStorage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Load EPG source configuration.
  EpgSourceConfig? loadConfig() {
    _ensureInitialized();
    try {
      final json = _prefs!.getString(_epgConfigKey);
      if (json == null) return null;

      final data = jsonDecode(json) as Map<String, dynamic>;
      return EpgSourceConfig.fromJson(data);
    } catch (e) {
      moduleLogger.warning(
        'Failed to load EPG config: $e',
        tag: 'EpgStorage',
      );
      return null;
    }
  }

  /// Clear EPG configuration.
  Future<void> clearConfig() async {
    _ensureInitialized();
    await _prefs!.remove(_epgConfigKey);
  }

  // ============ EPG Data Storage ============

  /// Save EPG data for a source.
  ///
  /// [sourceId] Unique identifier for the source (URL hash or profile ID).
  /// [data] The EPG data to save.
  Future<void> saveEpgData(String sourceId, EpgData data) async {
    _ensureInitialized();
    try {
      // Save channels
      final channelsJson = _serializeChannels(data.channels);
      await _prefs!
          .setString('${_epgDataPrefix}channels_$sourceId', channelsJson);

      // Save programs
      final programsJson = _serializePrograms(data.programs);
      await _prefs!
          .setString('${_epgDataPrefix}programs_$sourceId', programsJson);

      // Save metadata
      final metadata = EpgStorageMetadata(
        sourceId: sourceId,
        lastFetchedAt: data.fetchedAt,
        channelCount: data.channels.length,
        programCount: data.totalPrograms,
        sourceUrl: data.sourceUrl,
      );
      await _prefs!.setString(
        '$_epgMetadataPrefix$sourceId',
        jsonEncode(metadata.toJson()),
      );

      moduleLogger.info(
        'EPG data saved: ${data.channels.length} channels, ${data.totalPrograms} programs',
        tag: 'EpgStorage',
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to save EPG data',
        tag: 'EpgStorage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Load EPG data for a source.
  EpgData? loadEpgData(String sourceId) {
    _ensureInitialized();
    try {
      // Load channels
      final channelsJson =
          _prefs!.getString('${_epgDataPrefix}channels_$sourceId');
      if (channelsJson == null) return null;

      // Load programs
      final programsJson =
          _prefs!.getString('${_epgDataPrefix}programs_$sourceId');
      if (programsJson == null) return null;

      // Load metadata
      final metadataJson = _prefs!.getString('$_epgMetadataPrefix$sourceId');
      final metadata = metadataJson != null
          ? EpgStorageMetadata.fromJson(
              jsonDecode(metadataJson) as Map<String, dynamic>,
            )
          : null;

      // Deserialize
      final channels = _deserializeChannels(channelsJson);
      final programs = _deserializePrograms(programsJson);

      return EpgData(
        channels: channels,
        programs: programs,
        fetchedAt: metadata?.lastFetchedAt ?? DateTime.now().toUtc(),
        sourceUrl: metadata?.sourceUrl,
      );
    } catch (e) {
      moduleLogger.warning(
        'Failed to load EPG data: $e',
        tag: 'EpgStorage',
      );
      return null;
    }
  }

  /// Get metadata for stored EPG data.
  EpgStorageMetadata? getMetadata(String sourceId) {
    _ensureInitialized();
    try {
      final json = _prefs!.getString('$_epgMetadataPrefix$sourceId');
      if (json == null) return null;

      return EpgStorageMetadata.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if EPG data exists for a source.
  bool hasEpgData(String sourceId) {
    _ensureInitialized();
    return _prefs!.containsKey('${_epgDataPrefix}channels_$sourceId');
  }

  /// Clear EPG data for a source.
  Future<void> clearEpgData(String sourceId) async {
    _ensureInitialized();
    await _prefs!.remove('${_epgDataPrefix}channels_$sourceId');
    await _prefs!.remove('${_epgDataPrefix}programs_$sourceId');
    await _prefs!.remove('$_epgMetadataPrefix$sourceId');
    moduleLogger.debug('EPG data cleared for: $sourceId', tag: 'EpgStorage');
  }

  /// Clear all EPG data.
  Future<void> clearAll() async {
    _ensureInitialized();
    final keys =
        _prefs!.getKeys().where((k) => k.startsWith(_epgStoragePrefix));
    for (final key in keys) {
      await _prefs!.remove(key);
    }
    moduleLogger.info('All EPG data cleared', tag: 'EpgStorage');
  }

  /// Get list of stored source IDs.
  List<String> getStoredSourceIds() {
    _ensureInitialized();
    final ids = <String>{};

    for (final key in _prefs!.getKeys()) {
      if (key.startsWith(_epgMetadataPrefix)) {
        ids.add(key.substring(_epgMetadataPrefix.length));
      }
    }

    return ids.toList();
  }

  // ============ Serialization Helpers ============

  String _serializeChannels(Map<String, EpgChannel> channels) {
    final list = channels.values
        .map(
          (c) => {
            'id': c.id,
            'name': c.name,
            'iconUrl': c.iconUrl,
            'displayNames': c.displayNames,
          },
        )
        .toList();
    return jsonEncode(list);
  }

  Map<String, EpgChannel> _deserializeChannels(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    final result = <String, EpgChannel>{};

    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final channel = EpgChannel.fromXmlData(
        id: map['id'] as String,
        displayNames: (map['displayNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [map['name'] as String],
        iconUrl: map['iconUrl'] as String?,
      );
      result[channel.id] = channel;
    }

    return result;
  }

  String _serializePrograms(Map<String, List<EpgProgram>> programs) {
    final result = <String, List<Map<String, dynamic>>>{};

    for (final entry in programs.entries) {
      result[entry.key] = entry.value
          .map(
            (p) => {
              'channelId': p.channelId,
              'title': p.title,
              'description': p.description,
              'startTime': p.startTime.toIso8601String(),
              'endTime': p.endTime.toIso8601String(),
              'category': p.category,
              'language': p.language,
              'episodeNumber': p.episodeNumber,
              'iconUrl': p.iconUrl,
              'subtitle': p.subtitle,
            },
          )
          .toList();
    }

    return jsonEncode(result);
  }

  Map<String, List<EpgProgram>> _deserializePrograms(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final result = <String, List<EpgProgram>>{};

    for (final entry in map.entries) {
      final programs = (entry.value as List<dynamic>).map((item) {
        final p = item as Map<String, dynamic>;
        return EpgProgram(
          channelId: p['channelId'] as String,
          title: p['title'] as String,
          description: p['description'] as String?,
          startTime: DateTime.parse(p['startTime'] as String),
          endTime: DateTime.parse(p['endTime'] as String),
          category: p['category'] as String?,
          language: p['language'] as String?,
          episodeNumber: p['episodeNumber'] as String?,
          iconUrl: p['iconUrl'] as String?,
          subtitle: p['subtitle'] as String?,
        );
      }).toList();

      result[entry.key] = programs;
    }

    return result;
  }

  /// Generate a source ID from URL.
  static String generateSourceId(String url) {
    return 'url_${url.hashCode.abs().toRadixString(36)}';
  }

  /// Generate a source ID for Xtream profile.
  static String generateXtreamSourceId(String profileId) {
    return 'xtream_$profileId';
  }
}

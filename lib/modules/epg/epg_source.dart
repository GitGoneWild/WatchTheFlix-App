// EPG Source Configuration
// Defines the EPG data source types and configuration.

import 'package:equatable/equatable.dart';

/// EPG source type enumeration.
///
/// Specifies how EPG data should be fetched:
/// - [url] - Fetch EPG from a user-provided URL (XML/XMLTV format)
/// - [xtreamCodes] - Fetch EPG via Xtream Codes API using credentials
/// - [none] - No EPG source configured
enum EpgSourceType {
  /// EPG from a direct URL (XMLTV format).
  url,

  /// EPG from Xtream Codes API.
  xtreamCodes,

  /// No EPG source configured.
  none,
}

/// EPG source configuration model.
///
/// Encapsulates the configuration needed to fetch EPG data from
/// either a URL or Xtream Codes provider.
class EpgSourceConfig extends Equatable {
  const EpgSourceConfig({
    required this.type,
    this.epgUrl,
    this.profileId,
    this.refreshInterval = const Duration(hours: 6),
    this.autoRefreshEnabled = true,
    this.lastFetchedAt,
  });

  /// Create a URL-based EPG source configuration.
  factory EpgSourceConfig.fromUrl(
    String url, {
    Duration refreshInterval = const Duration(hours: 6),
    bool autoRefreshEnabled = true,
  }) {
    return EpgSourceConfig(
      type: EpgSourceType.url,
      epgUrl: url,
      refreshInterval: refreshInterval,
      autoRefreshEnabled: autoRefreshEnabled,
    );
  }

  /// Create an Xtream Codes EPG source configuration.
  factory EpgSourceConfig.fromXtreamCodes(
    String profileId, {
    Duration refreshInterval = const Duration(hours: 6),
    bool autoRefreshEnabled = true,
  }) {
    return EpgSourceConfig(
      type: EpgSourceType.xtreamCodes,
      profileId: profileId,
      refreshInterval: refreshInterval,
      autoRefreshEnabled: autoRefreshEnabled,
    );
  }

  /// Create an empty/disabled EPG source configuration.
  factory EpgSourceConfig.none() {
    return const EpgSourceConfig(
      type: EpgSourceType.none,
      autoRefreshEnabled: false,
    );
  }

  /// Create from JSON.
  factory EpgSourceConfig.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = EpgSourceType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => EpgSourceType.none,
    );

    return EpgSourceConfig(
      type: type,
      epgUrl: json['epgUrl'] as String?,
      profileId: json['profileId'] as String?,
      refreshInterval: Duration(
        minutes: (json['refreshIntervalMinutes'] as int?) ?? 360,
      ),
      autoRefreshEnabled: (json['autoRefreshEnabled'] as bool?) ?? true,
      lastFetchedAt: json['lastFetchedAt'] != null
          ? DateTime.tryParse(json['lastFetchedAt'] as String)
          : null,
    );
  }

  /// The type of EPG source.
  final EpgSourceType type;

  /// EPG URL (required when type is [EpgSourceType.url]).
  final String? epgUrl;

  /// Profile ID for Xtream Codes (required when type is [EpgSourceType.xtreamCodes]).
  final String? profileId;

  /// Refresh interval for automatic EPG updates.
  /// Defaults to 6 hours.
  final Duration refreshInterval;

  /// Whether to enable automatic refresh.
  final bool autoRefreshEnabled;

  /// Last successful fetch timestamp.
  final DateTime? lastFetchedAt;

  /// Check if EPG is properly configured.
  bool get isConfigured {
    switch (type) {
      case EpgSourceType.url:
        return epgUrl != null && epgUrl!.isNotEmpty;
      case EpgSourceType.xtreamCodes:
        return profileId != null && profileId!.isNotEmpty;
      case EpgSourceType.none:
        return false;
    }
  }

  /// Check if EPG data needs refresh based on refresh interval.
  bool get needsRefresh {
    if (!autoRefreshEnabled || lastFetchedAt == null) return true;
    final elapsed = DateTime.now().difference(lastFetchedAt!);
    return elapsed >= refreshInterval;
  }

  /// Create a copy with updated last fetch time.
  EpgSourceConfig copyWithLastFetch(DateTime fetchedAt) {
    return EpgSourceConfig(
      type: type,
      epgUrl: epgUrl,
      profileId: profileId,
      refreshInterval: refreshInterval,
      autoRefreshEnabled: autoRefreshEnabled,
      lastFetchedAt: fetchedAt,
    );
  }

  /// Create a copy with new values.
  EpgSourceConfig copyWith({
    EpgSourceType? type,
    String? epgUrl,
    String? profileId,
    Duration? refreshInterval,
    bool? autoRefreshEnabled,
    DateTime? lastFetchedAt,
  }) {
    return EpgSourceConfig(
      type: type ?? this.type,
      epgUrl: epgUrl ?? this.epgUrl,
      profileId: profileId ?? this.profileId,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }

  /// Convert to JSON for storage.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'epgUrl': epgUrl,
      'profileId': profileId,
      'refreshIntervalMinutes': refreshInterval.inMinutes,
      'autoRefreshEnabled': autoRefreshEnabled,
      'lastFetchedAt': lastFetchedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        type,
        epgUrl,
        profileId,
        refreshInterval,
        autoRefreshEnabled,
        lastFetchedAt,
      ];
}

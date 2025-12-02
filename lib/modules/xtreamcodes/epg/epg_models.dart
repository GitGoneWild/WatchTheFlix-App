// EPG Models
// Domain models for Electronic Program Guide data.

import 'package:equatable/equatable.dart';

/// EPG Channel model representing a channel from XMLTV data.
class EpgChannel extends Equatable {
  const EpgChannel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.displayNames = const [],
  });

  /// Create from XMLTV channel element data.
  factory EpgChannel.fromXmlData({
    required String id,
    required List<String> displayNames,
    String? iconUrl,
  }) {
    return EpgChannel(
      id: id,
      name: displayNames.isNotEmpty ? displayNames.first : id,
      iconUrl: iconUrl,
      displayNames: displayNames,
    );
  }

  /// Unique channel identifier (XMLTV id).
  final String id;

  /// Display name of the channel.
  final String name;

  /// URL to the channel logo/icon.
  final String? iconUrl;

  /// Additional display names for the channel.
  final List<String> displayNames;

  @override
  List<Object?> get props => [id, name, iconUrl, displayNames];
}

/// EPG Program model representing a single program/show.
class EpgProgram extends Equatable {
  const EpgProgram({
    required this.channelId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.category,
    this.language,
    this.episodeNumber,
    this.iconUrl,
    this.subtitle,
  });

  /// Channel ID this program belongs to.
  final String channelId;

  /// Program title.
  final String title;

  /// Program description.
  final String? description;

  /// Program start time in UTC.
  final DateTime startTime;

  /// Program end time in UTC.
  final DateTime endTime;

  /// Program category/genre.
  final String? category;

  /// Language of the program.
  final String? language;

  /// Episode number if applicable.
  final String? episodeNumber;

  /// Program icon/poster URL.
  final String? iconUrl;

  /// Subtitle or secondary title.
  final String? subtitle;

  /// Check if this program is currently airing.
  bool get isCurrentlyAiring {
    final now = DateTime.now().toUtc();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if this program is in the future.
  bool get isUpcoming {
    final now = DateTime.now().toUtc();
    return now.isBefore(startTime);
  }

  /// Check if this program has already ended.
  bool get hasEnded {
    final now = DateTime.now().toUtc();
    return now.isAfter(endTime);
  }

  /// Calculate progress percentage (0.0 to 1.0).
  double get progress {
    if (!isCurrentlyAiring) return hasEnded ? 1.0 : 0.0;
    final now = DateTime.now().toUtc();
    final totalDuration = endTime.difference(startTime).inSeconds;
    final elapsed = now.difference(startTime).inSeconds;
    return totalDuration > 0 ? (elapsed / totalDuration).clamp(0.0, 1.0) : 0.0;
  }

  /// Duration of the program.
  Duration get duration => endTime.difference(startTime);

  /// Remaining time until program ends.
  Duration get remainingTime {
    if (hasEnded) return Duration.zero;
    final now = DateTime.now().toUtc();
    if (now.isBefore(startTime)) return duration;
    return endTime.difference(now);
  }

  /// Time until program starts (for upcoming programs).
  Duration get timeUntilStart {
    if (!isUpcoming) return Duration.zero;
    final now = DateTime.now().toUtc();
    return startTime.difference(now);
  }

  @override
  List<Object?> get props => [
        channelId,
        title,
        description,
        startTime,
        endTime,
        category,
        language,
        episodeNumber,
        iconUrl,
        subtitle,
      ];
}

/// EPG data container for parsed XMLTV data.
class EpgData extends Equatable {
  const EpgData({
    required this.channels,
    required this.programs,
    required this.fetchedAt,
    this.sourceUrl,
  });

  /// Create empty EPG data.
  factory EpgData.empty() {
    return EpgData(
      channels: const {},
      programs: const {},
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  /// Map of channel ID to channel info.
  final Map<String, EpgChannel> channels;

  /// Map of channel ID to list of programs (sorted by start time).
  final Map<String, List<EpgProgram>> programs;

  /// Timestamp when this EPG data was fetched.
  final DateTime fetchedAt;

  /// Source URL of the EPG data.
  final String? sourceUrl;

  /// Check if EPG data is empty.
  bool get isEmpty => channels.isEmpty && programs.isEmpty;

  /// Check if EPG data is not empty.
  bool get isNotEmpty => !isEmpty;

  /// Get total number of programs.
  int get totalPrograms =>
      programs.values.fold(0, (sum, list) => sum + list.length);

  /// Get programs for a specific channel.
  List<EpgProgram> getChannelPrograms(String channelId) {
    return programs[channelId] ?? [];
  }

  /// Get current program for a channel.
  EpgProgram? getCurrentProgram(String channelId) {
    final channelPrograms = getChannelPrograms(channelId);
    for (final program in channelPrograms) {
      if (program.isCurrentlyAiring) {
        return program;
      }
    }
    return null;
  }

  /// Get next program for a channel (after the current one).
  EpgProgram? getNextProgram(String channelId) {
    final channelPrograms = getChannelPrograms(channelId);
    EpgProgram? current;
    for (final program in channelPrograms) {
      if (program.isCurrentlyAiring) {
        current = program;
      } else if (current != null && program.isUpcoming) {
        return program;
      } else if (program.isUpcoming && current == null) {
        // If there's no current program, return the first upcoming
        return program;
      }
    }
    return null;
  }

  /// Get programs for a channel within a time range.
  List<EpgProgram> getProgramsInRange(
    String channelId,
    DateTime start,
    DateTime end,
  ) {
    final channelPrograms = getChannelPrograms(channelId);
    return channelPrograms.where((program) {
      // Program overlaps with the range if:
      // - it starts before range ends AND
      // - it ends after range starts
      return program.startTime.isBefore(end) && program.endTime.isAfter(start);
    }).toList();
  }

  /// Get daily schedule for a channel.
  List<EpgProgram> getDailySchedule(String channelId, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day).toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));
    return getProgramsInRange(channelId, dayStart, dayEnd);
  }

  @override
  List<Object?> get props => [channels, programs, fetchedAt, sourceUrl];
}

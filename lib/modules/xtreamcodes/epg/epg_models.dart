// Xtream EPG Models
// Domain models for EPG (Electronic Program Guide) data.

import 'package:equatable/equatable.dart';

/// EPG Channel model
class EpgChannel extends Equatable {
  const EpgChannel({
    required this.id,
    required this.displayName,
    this.icon,
  });

  final String id;
  final String displayName;
  final String? icon;

  @override
  List<Object?> get props => [id, displayName, icon];
}

/// EPG Program model
class EpgProgram extends Equatable {
  const EpgProgram({
    required this.channelId,
    required this.start,
    required this.stop,
    required this.title,
    this.description,
    this.category,
    this.icon,
  });

  final String channelId;
  final DateTime start;
  final DateTime stop;
  final String title;
  final String? description;
  final String? category;
  final String? icon;

  /// Check if program is currently airing
  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(stop);
  }

  /// Check if program has ended
  bool get hasEnded => DateTime.now().isAfter(stop);

  /// Check if program hasn't started yet
  bool get isUpcoming => DateTime.now().isBefore(start);

  /// Get program progress (0.0 to 1.0)
  double get progress {
    if (hasEnded) return 1.0;
    if (isUpcoming) return 0.0;
    
    final now = DateTime.now();
    final totalDuration = stop.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return totalDuration > 0 ? elapsed / totalDuration : 0.0;
  }

  @override
  List<Object?> get props => [
        channelId,
        start,
        stop,
        title,
        description,
        category,
        icon,
      ];
}

/// EPG cache metadata
class EpgCacheMetadata extends Equatable {
  const EpgCacheMetadata({
    required this.lastUpdated,
    required this.programCount,
    required this.channelCount,
    this.startDate,
    this.endDate,
  });

  factory EpgCacheMetadata.fromJson(Map<String, dynamic> json) {
    return EpgCacheMetadata(
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      programCount: json['programCount'] as int,
      channelCount: json['channelCount'] as int,
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }

  final DateTime lastUpdated;
  final int programCount;
  final int channelCount;
  final DateTime? startDate;
  final DateTime? endDate;

  Map<String, dynamic> toJson() {
    return {
      'lastUpdated': lastUpdated.toIso8601String(),
      'programCount': programCount,
      'channelCount': channelCount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        lastUpdated,
        programCount,
        channelCount,
        startDate,
        endDate,
      ];
}

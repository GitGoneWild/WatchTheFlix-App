// Base Models
// Shared domain models used across the application modules.

import 'package:equatable/equatable.dart';

/// Content type enumeration
enum ContentType {
  live,
  movie,
  series,
}

/// Channel domain model
class DomainChannel extends Equatable {
  const DomainChannel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.groupTitle,
    this.categoryId,
    this.type = ContentType.live,
    this.metadata,
    this.epgInfo,
  });
  final String id;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? groupTitle;
  final String? categoryId;
  final ContentType type;
  final Map<String, dynamic>? metadata;
  final EpgInfo? epgInfo;

  DomainChannel copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? logoUrl,
    String? groupTitle,
    String? categoryId,
    ContentType? type,
    Map<String, dynamic>? metadata,
    EpgInfo? epgInfo,
  }) {
    return DomainChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      groupTitle: groupTitle ?? this.groupTitle,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      epgInfo: epgInfo ?? this.epgInfo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        streamUrl,
        logoUrl,
        groupTitle,
        categoryId,
        type,
        metadata,
        epgInfo,
      ];
}

/// EPG information model
class EpgInfo extends Equatable {
  const EpgInfo({
    this.currentProgram,
    this.nextProgram,
    this.startTime,
    this.endTime,
    this.description,
  });
  final String? currentProgram;
  final String? nextProgram;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? description;

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress {
    if (startTime == null || endTime == null) return 0.0;
    final now = DateTime.now();
    if (now.isBefore(startTime!)) return 0.0;
    if (now.isAfter(endTime!)) return 1.0;
    final totalDuration = endTime!.difference(startTime!).inSeconds;
    final elapsed = now.difference(startTime!).inSeconds;
    return totalDuration > 0 ? elapsed / totalDuration : 0.0;
  }

  @override
  List<Object?> get props => [
        currentProgram,
        nextProgram,
        startTime,
        endTime,
        description,
      ];
}

/// Category domain model
class DomainCategory extends Equatable {
  const DomainCategory({
    required this.id,
    required this.name,
    this.channelCount = 0,
    this.iconUrl,
    this.sortOrder,
  });
  final String id;
  final String name;
  final int channelCount;
  final String? iconUrl;
  final int? sortOrder;

  DomainCategory copyWith({
    String? id,
    String? name,
    int? channelCount,
    String? iconUrl,
    int? sortOrder,
  }) {
    return DomainCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      channelCount: channelCount ?? this.channelCount,
      iconUrl: iconUrl ?? this.iconUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, name, channelCount, iconUrl, sortOrder];
}

/// VOD (Video on Demand) item domain model
class VodItem extends Equatable {
  const VodItem({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.posterUrl,
    this.backdropUrl,
    this.description,
    this.categoryId,
    this.genre,
    this.releaseDate,
    this.rating,
    this.duration,
    this.type = ContentType.movie,
    this.metadata,
  });
  final String id;
  final String name;
  final String streamUrl;
  final String? posterUrl;
  final String? backdropUrl;
  final String? description;
  final String? categoryId;
  final String? genre;
  final String? releaseDate;
  final double? rating;
  final int? duration;
  final ContentType type;
  final Map<String, dynamic>? metadata;

  VodItem copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? posterUrl,
    String? backdropUrl,
    String? description,
    String? categoryId,
    String? genre,
    String? releaseDate,
    double? rating,
    int? duration,
    ContentType? type,
    Map<String, dynamic>? metadata,
  }) {
    return VodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      genre: genre ?? this.genre,
      releaseDate: releaseDate ?? this.releaseDate,
      rating: rating ?? this.rating,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        streamUrl,
        posterUrl,
        backdropUrl,
        description,
        categoryId,
        genre,
        releaseDate,
        rating,
        duration,
        type,
        metadata,
      ];
}

/// Series domain model
class DomainSeries extends Equatable {
  const DomainSeries({
    required this.id,
    required this.name,
    this.posterUrl,
    this.backdropUrl,
    this.description,
    this.categoryId,
    this.genre,
    this.releaseDate,
    this.rating,
    this.seasons = const [],
    this.metadata,
  });
  final String id;
  final String name;
  final String? posterUrl;
  final String? backdropUrl;
  final String? description;
  final String? categoryId;
  final String? genre;
  final String? releaseDate;
  final double? rating;
  final List<Season> seasons;
  final Map<String, dynamic>? metadata;

  int get totalEpisodes =>
      seasons.fold(0, (sum, season) => sum + season.episodes.length);

  @override
  List<Object?> get props => [
        id,
        name,
        posterUrl,
        backdropUrl,
        description,
        categoryId,
        genre,
        releaseDate,
        rating,
        seasons,
        metadata,
      ];
}

/// Season model
class Season extends Equatable {
  const Season({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.posterUrl,
    this.episodes = const [],
  });
  final String id;
  final int seasonNumber;
  final String? name;
  final String? posterUrl;
  final List<Episode> episodes;

  @override
  List<Object?> get props => [id, seasonNumber, name, posterUrl, episodes];
}

/// Episode model
class Episode extends Equatable {
  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.name,
    required this.streamUrl,
    this.description,
    this.thumbnailUrl,
    this.duration,
    this.airDate,
  });
  final String id;
  final int episodeNumber;
  final String name;
  final String streamUrl;
  final String? description;
  final String? thumbnailUrl;
  final int? duration;
  final String? airDate;

  @override
  List<Object?> get props => [
        id,
        episodeNumber,
        name,
        streamUrl,
        description,
        thumbnailUrl,
        duration,
        airDate,
      ];
}

/// Profile domain model
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    required this.createdAt,
    this.lastUpdated,
    this.isActive = true,
  });
  final String id;
  final String name;
  final ProfileType type;
  final String? url;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool isActive;

  bool get isM3U => type == ProfileType.m3uFile || type == ProfileType.m3uUrl;

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        url,
        createdAt,
        lastUpdated,
        isActive,
      ];
}

/// Profile type enumeration
enum ProfileType {
  m3uFile,
  m3uUrl,
}

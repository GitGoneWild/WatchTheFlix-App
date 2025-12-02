// XtreamHiveModels
// Hive-compatible storage models for Xtream Codes data.
// These models provide local persistence for channels, categories, movies,
// series, and EPG data.

import 'package:hive/hive.dart';

import '../../core/models/base_models.dart';
import '../epg/epg_models.dart';

part 'xtream_hive_models.g.dart';

/// Hive type IDs for Xtream models
class XtreamHiveTypeIds {
  static const int channel = 100;
  static const int category = 101;
  static const int vodItem = 102;
  static const int series = 103;
  static const int season = 104;
  static const int episode = 105;
  static const int epgEntry = 106;
  static const int syncStatus = 107;
  static const int epgProgram = 108;
  static const int contentType = 109;
}

/// Hive adapter for ContentType enum
@HiveType(typeId: XtreamHiveTypeIds.contentType)
enum HiveContentType {
  @HiveField(0)
  live,
  @HiveField(1)
  movie,
  @HiveField(2)
  series,
}

/// Extension to convert between Hive and Domain ContentType
extension HiveContentTypeExtension on HiveContentType {
  ContentType toDomain() {
    switch (this) {
      case HiveContentType.live:
        return ContentType.live;
      case HiveContentType.movie:
        return ContentType.movie;
      case HiveContentType.series:
        return ContentType.series;
    }
  }

  static HiveContentType fromDomain(ContentType type) {
    switch (type) {
      case ContentType.live:
        return HiveContentType.live;
      case ContentType.movie:
        return HiveContentType.movie;
      case ContentType.series:
        return HiveContentType.series;
    }
  }
}

/// Hive model for storing channel data locally
@HiveType(typeId: XtreamHiveTypeIds.channel)
class HiveChannel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String streamUrl;

  @HiveField(3)
  String? logoUrl;

  @HiveField(4)
  String? groupTitle;

  @HiveField(5)
  String? categoryId;

  @HiveField(6)
  HiveContentType type;

  @HiveField(7)
  Map<String, dynamic>? metadata;

  HiveChannel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.groupTitle,
    this.categoryId,
    this.type = HiveContentType.live,
    this.metadata,
  });

  /// Convert to domain model
  DomainChannel toDomain() {
    return DomainChannel(
      id: id,
      name: name,
      streamUrl: streamUrl,
      logoUrl: logoUrl,
      groupTitle: groupTitle,
      categoryId: categoryId,
      type: type.toDomain(),
      metadata: metadata,
    );
  }

  /// Create from domain model
  factory HiveChannel.fromDomain(DomainChannel channel) {
    return HiveChannel(
      id: channel.id,
      name: channel.name,
      streamUrl: channel.streamUrl,
      logoUrl: channel.logoUrl,
      groupTitle: channel.groupTitle,
      categoryId: channel.categoryId,
      type: HiveContentTypeExtension.fromDomain(channel.type),
      metadata: channel.metadata,
    );
  }
}

/// Hive model for storing category data locally
@HiveType(typeId: XtreamHiveTypeIds.category)
class HiveCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int channelCount;

  @HiveField(3)
  String? iconUrl;

  @HiveField(4)
  int? sortOrder;

  @HiveField(5)
  String categoryType; // 'live', 'movie', 'series'

  HiveCategory({
    required this.id,
    required this.name,
    this.channelCount = 0,
    this.iconUrl,
    this.sortOrder,
    required this.categoryType,
  });

  /// Convert to domain model
  DomainCategory toDomain() {
    return DomainCategory(
      id: id,
      name: name,
      channelCount: channelCount,
      iconUrl: iconUrl,
      sortOrder: sortOrder,
    );
  }

  /// Create from domain model
  factory HiveCategory.fromDomain(DomainCategory category, String type) {
    return HiveCategory(
      id: category.id,
      name: category.name,
      channelCount: category.channelCount,
      iconUrl: category.iconUrl,
      sortOrder: category.sortOrder,
      categoryType: type,
    );
  }
}

/// Hive model for storing VOD (movie) data locally
@HiveType(typeId: XtreamHiveTypeIds.vodItem)
class HiveVodItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String streamUrl;

  @HiveField(3)
  String? posterUrl;

  @HiveField(4)
  String? backdropUrl;

  @HiveField(5)
  String? description;

  @HiveField(6)
  String? categoryId;

  @HiveField(7)
  String? genre;

  @HiveField(8)
  String? releaseDate;

  @HiveField(9)
  double? rating;

  @HiveField(10)
  int? duration;

  @HiveField(11)
  Map<String, dynamic>? metadata;

  HiveVodItem({
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
    this.metadata,
  });

  /// Convert to domain model
  VodItem toDomain() {
    return VodItem(
      id: id,
      name: name,
      streamUrl: streamUrl,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      description: description,
      categoryId: categoryId,
      genre: genre,
      releaseDate: releaseDate,
      rating: rating,
      duration: duration,
      type: ContentType.movie,
      metadata: metadata,
    );
  }

  /// Create from domain model
  factory HiveVodItem.fromDomain(VodItem movie) {
    return HiveVodItem(
      id: movie.id,
      name: movie.name,
      streamUrl: movie.streamUrl,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      description: movie.description,
      categoryId: movie.categoryId,
      genre: movie.genre,
      releaseDate: movie.releaseDate,
      rating: movie.rating,
      duration: movie.duration,
      metadata: movie.metadata,
    );
  }
}

/// Hive model for storing episode data
@HiveType(typeId: XtreamHiveTypeIds.episode)
class HiveEpisode extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int episodeNumber;

  @HiveField(2)
  String name;

  @HiveField(3)
  String streamUrl;

  @HiveField(4)
  String? description;

  @HiveField(5)
  String? thumbnailUrl;

  @HiveField(6)
  int? duration;

  @HiveField(7)
  String? airDate;

  HiveEpisode({
    required this.id,
    required this.episodeNumber,
    required this.name,
    required this.streamUrl,
    this.description,
    this.thumbnailUrl,
    this.duration,
    this.airDate,
  });

  /// Convert to domain model
  Episode toDomain() {
    return Episode(
      id: id,
      episodeNumber: episodeNumber,
      name: name,
      streamUrl: streamUrl,
      description: description,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      airDate: airDate,
    );
  }

  /// Create from domain model
  factory HiveEpisode.fromDomain(Episode episode) {
    return HiveEpisode(
      id: episode.id,
      episodeNumber: episode.episodeNumber,
      name: episode.name,
      streamUrl: episode.streamUrl,
      description: episode.description,
      thumbnailUrl: episode.thumbnailUrl,
      duration: episode.duration,
      airDate: episode.airDate,
    );
  }
}

/// Hive model for storing season data
@HiveType(typeId: XtreamHiveTypeIds.season)
class HiveSeason extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int seasonNumber;

  @HiveField(2)
  String? name;

  @HiveField(3)
  String? posterUrl;

  @HiveField(4)
  List<HiveEpisode> episodes;

  HiveSeason({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.posterUrl,
    this.episodes = const [],
  });

  /// Convert to domain model
  Season toDomain() {
    return Season(
      id: id,
      seasonNumber: seasonNumber,
      name: name,
      posterUrl: posterUrl,
      episodes: episodes.map((e) => e.toDomain()).toList(),
    );
  }

  /// Create from domain model
  factory HiveSeason.fromDomain(Season season) {
    return HiveSeason(
      id: season.id,
      seasonNumber: season.seasonNumber,
      name: season.name,
      posterUrl: season.posterUrl,
      episodes: season.episodes.map((e) => HiveEpisode.fromDomain(e)).toList(),
    );
  }
}

/// Hive model for storing series data locally
@HiveType(typeId: XtreamHiveTypeIds.series)
class HiveSeries extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? posterUrl;

  @HiveField(3)
  String? backdropUrl;

  @HiveField(4)
  String? description;

  @HiveField(5)
  String? categoryId;

  @HiveField(6)
  String? genre;

  @HiveField(7)
  String? releaseDate;

  @HiveField(8)
  double? rating;

  @HiveField(9)
  List<HiveSeason> seasons;

  @HiveField(10)
  Map<String, dynamic>? metadata;

  HiveSeries({
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

  /// Convert to domain model
  DomainSeries toDomain() {
    return DomainSeries(
      id: id,
      name: name,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      description: description,
      categoryId: categoryId,
      genre: genre,
      releaseDate: releaseDate,
      rating: rating,
      seasons: seasons.map((s) => s.toDomain()).toList(),
      metadata: metadata,
    );
  }

  /// Create from domain model
  factory HiveSeries.fromDomain(DomainSeries series) {
    return HiveSeries(
      id: series.id,
      name: series.name,
      posterUrl: series.posterUrl,
      backdropUrl: series.backdropUrl,
      description: series.description,
      categoryId: series.categoryId,
      genre: series.genre,
      releaseDate: series.releaseDate,
      rating: series.rating,
      seasons: series.seasons.map((s) => HiveSeason.fromDomain(s)).toList(),
      metadata: series.metadata,
    );
  }
}

/// Hive model for storing EPG program data
@HiveType(typeId: XtreamHiveTypeIds.epgProgram)
class HiveEpgProgram extends HiveObject {
  @HiveField(0)
  String channelId;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime startTime;

  @HiveField(4)
  DateTime endTime;

  @HiveField(5)
  String? category;

  @HiveField(6)
  String? language;

  @HiveField(7)
  String? episodeNumber;

  @HiveField(8)
  String? iconUrl;

  @HiveField(9)
  String? subtitle;

  HiveEpgProgram({
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

  /// Convert to domain model
  EpgProgram toDomain() {
    return EpgProgram(
      channelId: channelId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      category: category,
      language: language,
      episodeNumber: episodeNumber,
      iconUrl: iconUrl,
      subtitle: subtitle,
    );
  }

  /// Create from domain model
  factory HiveEpgProgram.fromDomain(EpgProgram program) {
    return HiveEpgProgram(
      channelId: program.channelId,
      title: program.title,
      description: program.description,
      startTime: program.startTime,
      endTime: program.endTime,
      category: program.category,
      language: program.language,
      episodeNumber: program.episodeNumber,
      iconUrl: program.iconUrl,
      subtitle: program.subtitle,
    );
  }
}

/// Sync status for tracking data freshness
@HiveType(typeId: XtreamHiveTypeIds.syncStatus)
class HiveSyncStatus extends HiveObject {
  @HiveField(0)
  String profileId;

  @HiveField(1)
  DateTime? lastChannelSync;

  @HiveField(2)
  DateTime? lastMovieSync;

  @HiveField(3)
  DateTime? lastSeriesSync;

  @HiveField(4)
  DateTime? lastEpgSync;

  @HiveField(5)
  DateTime? lastCategorySync;

  @HiveField(6)
  bool isInitialSyncComplete;

  @HiveField(7)
  int? channelCount;

  @HiveField(8)
  int? movieCount;

  @HiveField(9)
  int? seriesCount;

  @HiveField(10)
  int? epgProgramCount;

  HiveSyncStatus({
    required this.profileId,
    this.lastChannelSync,
    this.lastMovieSync,
    this.lastSeriesSync,
    this.lastEpgSync,
    this.lastCategorySync,
    this.isInitialSyncComplete = false,
    this.channelCount,
    this.movieCount,
    this.seriesCount,
    this.epgProgramCount,
  });

  /// Check if channels need refresh based on TTL
  bool needsChannelRefresh(Duration ttl) {
    if (lastChannelSync == null) return true;
    return DateTime.now().difference(lastChannelSync!) > ttl;
  }

  /// Check if movies need refresh based on TTL
  bool needsMovieRefresh(Duration ttl) {
    if (lastMovieSync == null) return true;
    return DateTime.now().difference(lastMovieSync!) > ttl;
  }

  /// Check if series need refresh based on TTL
  bool needsSeriesRefresh(Duration ttl) {
    if (lastSeriesSync == null) return true;
    return DateTime.now().difference(lastSeriesSync!) > ttl;
  }

  /// Check if EPG needs refresh based on TTL
  bool needsEpgRefresh(Duration ttl) {
    if (lastEpgSync == null) return true;
    return DateTime.now().difference(lastEpgSync!) > ttl;
  }

  /// Update channel sync timestamp
  void updateChannelSync(int count) {
    lastChannelSync = DateTime.now();
    channelCount = count;
  }

  /// Update movie sync timestamp
  void updateMovieSync(int count) {
    lastMovieSync = DateTime.now();
    movieCount = count;
  }

  /// Update series sync timestamp
  void updateSeriesSync(int count) {
    lastSeriesSync = DateTime.now();
    seriesCount = count;
  }

  /// Update EPG sync timestamp
  void updateEpgSync(int count) {
    lastEpgSync = DateTime.now();
    epgProgramCount = count;
  }

  /// Update category sync timestamp
  void updateCategorySync() {
    lastCategorySync = DateTime.now();
  }

  /// Mark initial sync as complete
  void markInitialSyncComplete() {
    isInitialSyncComplete = true;
  }
}

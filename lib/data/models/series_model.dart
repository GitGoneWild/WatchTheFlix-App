import '../../domain/entities/series.dart';

/// Series model for data layer
class SeriesModel {
  const SeriesModel({
    required this.id,
    required this.name,
    this.posterUrl,
    this.backdropUrl,
    this.categoryId,
    this.description,
    this.releaseDate,
    this.rating,
    this.genre,
    this.seasons,
    this.metadata,
  });

  /// Create from JSON
  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    return SeriesModel(
      id: json['series_id']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['name'] ?? json['title'] ?? '') as String,
      posterUrl: (json['cover'] ?? json['poster_url']) as String?,
      backdropUrl: (json['backdrop_path'] ?? json['backdrop_url']) as String?,
      categoryId: json['category_id']?.toString(),
      description: (json['plot'] ?? json['description']) as String?,
      releaseDate: (json['releaseDate'] ?? json['release_date']) as String?,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      genre: _parseGenre(json['genre']),
      seasons: json['seasons'] != null
          ? (json['seasons'] as List)
              .map((s) => SeasonModel.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create from domain entity
  factory SeriesModel.fromEntity(Series entity) {
    return SeriesModel(
      id: entity.id,
      name: entity.name,
      posterUrl: entity.posterUrl,
      backdropUrl: entity.backdropUrl,
      categoryId: entity.categoryId,
      description: entity.description,
      releaseDate: entity.releaseDate,
      rating: entity.rating,
      genre: entity.genre,
      seasons: entity.seasons?.map((s) => SeasonModel.fromEntity(s)).toList(),
      metadata: entity.metadata,
    );
  }
  final String id;
  final String name;
  final String? posterUrl;
  final String? backdropUrl;
  final String? categoryId;
  final String? description;
  final String? releaseDate;
  final double? rating;
  final String? genre;
  final List<SeasonModel>? seasons;
  final Map<String, dynamic>? metadata;

  /// Parse genre field that can be String, List, or null
  static String? _parseGenre(dynamic genre) {
    if (genre == null) return null;
    if (genre is String) return genre;
    if (genre is List) return genre.join(', ');
    return genre.toString();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'poster_url': posterUrl,
      'backdrop_url': backdropUrl,
      'category_id': categoryId,
      'description': description,
      'release_date': releaseDate,
      'rating': rating,
      'genre': genre,
      'seasons': seasons?.map((s) => s.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// Convert to domain entity
  Series toEntity() {
    return Series(
      id: id,
      name: name,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      categoryId: categoryId,
      description: description,
      releaseDate: releaseDate,
      rating: rating,
      genre: genre,
      seasons: seasons?.map((s) => s.toEntity()).toList(),
      metadata: metadata,
    );
  }
}

/// Season model
class SeasonModel {
  const SeasonModel({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.posterUrl,
    this.episodes,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id']?.toString() ?? '',
      seasonNumber: (json['season_number'] ?? 1) as int,
      name: json['name'] as String?,
      posterUrl: (json['cover'] ?? json['poster_url']) as String?,
      episodes: json['episodes'] != null
          ? (json['episodes'] as List)
              .map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  factory SeasonModel.fromEntity(Season entity) {
    return SeasonModel(
      id: entity.id,
      seasonNumber: entity.seasonNumber,
      name: entity.name,
      posterUrl: entity.posterUrl,
      episodes:
          entity.episodes?.map((e) => EpisodeModel.fromEntity(e)).toList(),
    );
  }
  final String id;
  final int seasonNumber;
  final String? name;
  final String? posterUrl;
  final List<EpisodeModel>? episodes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'season_number': seasonNumber,
      'name': name,
      'poster_url': posterUrl,
      'episodes': episodes?.map((e) => e.toJson()).toList(),
    };
  }

  Season toEntity() {
    return Season(
      id: id,
      seasonNumber: seasonNumber,
      name: name,
      posterUrl: posterUrl,
      episodes: episodes?.map((e) => e.toEntity()).toList(),
    );
  }
}

/// Episode model
class EpisodeModel {
  const EpisodeModel({
    required this.id,
    required this.episodeNumber,
    required this.name,
    required this.streamUrl,
    this.posterUrl,
    this.description,
    this.duration,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id']?.toString() ?? '',
      episodeNumber: (json['episode_num'] ?? 1) as int,
      name: (json['title'] ?? json['name'] ?? '') as String,
      streamUrl: (json['stream_url'] ?? '') as String,
      posterUrl:
          (json['info']?['movie_image'] ?? json['poster_url']) as String?,
      description: (json['info']?['plot'] ?? json['description']) as String?,
      duration: (json['info']?['duration_secs'] ?? json['duration']) as int?,
    );
  }

  factory EpisodeModel.fromEntity(Episode entity) {
    return EpisodeModel(
      id: entity.id,
      episodeNumber: entity.episodeNumber,
      name: entity.name,
      streamUrl: entity.streamUrl,
      posterUrl: entity.posterUrl,
      description: entity.description,
      duration: entity.duration,
    );
  }
  final String id;
  final int episodeNumber;
  final String name;
  final String streamUrl;
  final String? posterUrl;
  final String? description;
  final int? duration;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'episode_number': episodeNumber,
      'name': name,
      'stream_url': streamUrl,
      'poster_url': posterUrl,
      'description': description,
      'duration': duration,
    };
  }

  Episode toEntity() {
    return Episode(
      id: id,
      episodeNumber: episodeNumber,
      name: name,
      streamUrl: streamUrl,
      posterUrl: posterUrl,
      description: description,
      duration: duration,
    );
  }
}

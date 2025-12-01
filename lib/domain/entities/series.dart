import 'package:equatable/equatable.dart';

/// Series entity
class Series extends Equatable {
  final String id;
  final String name;
  final String? posterUrl;
  final String? backdropUrl;
  final String? categoryId;
  final String? description;
  final String? releaseDate;
  final double? rating;
  final String? genre;
  final List<Season>? seasons;
  final Map<String, dynamic>? metadata;

  const Series({
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

  /// Get total episode count
  int get totalEpisodes {
    if (seasons == null) return 0;
    return seasons!.fold(0, (sum, season) => sum + (season.episodes?.length ?? 0));
  }

  Series copyWith({
    String? id,
    String? name,
    String? posterUrl,
    String? backdropUrl,
    String? categoryId,
    String? description,
    String? releaseDate,
    double? rating,
    String? genre,
    List<Season>? seasons,
    Map<String, dynamic>? metadata,
  }) {
    return Series(
      id: id ?? this.id,
      name: name ?? this.name,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      releaseDate: releaseDate ?? this.releaseDate,
      rating: rating ?? this.rating,
      genre: genre ?? this.genre,
      seasons: seasons ?? this.seasons,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        posterUrl,
        backdropUrl,
        categoryId,
        description,
        releaseDate,
        rating,
        genre,
        seasons,
        metadata,
      ];
}

/// Season entity
class Season extends Equatable {
  final String id;
  final int seasonNumber;
  final String? name;
  final String? posterUrl;
  final List<Episode>? episodes;

  const Season({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.posterUrl,
    this.episodes,
  });

  @override
  List<Object?> get props => [id, seasonNumber, name, posterUrl, episodes];
}

/// Episode entity
class Episode extends Equatable {
  final String id;
  final int episodeNumber;
  final String name;
  final String streamUrl;
  final String? posterUrl;
  final String? description;
  final int? duration;

  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.name,
    required this.streamUrl,
    this.posterUrl,
    this.description,
    this.duration,
  });

  @override
  List<Object?> get props => [
        id,
        episodeNumber,
        name,
        streamUrl,
        posterUrl,
        description,
        duration,
      ];
}

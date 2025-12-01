import 'package:equatable/equatable.dart';

/// Movie entity
class Movie extends Equatable {
  final String id;
  final String name;
  final String streamUrl;
  final String? posterUrl;
  final String? backdropUrl;
  final String? categoryId;
  final String? description;
  final String? releaseDate;
  final double? rating;
  final int? duration;
  final String? genre;
  final String? director;
  final List<String>? cast;
  final Map<String, dynamic>? metadata;

  const Movie({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.posterUrl,
    this.backdropUrl,
    this.categoryId,
    this.description,
    this.releaseDate,
    this.rating,
    this.duration,
    this.genre,
    this.director,
    this.cast,
    this.metadata,
  });

  Movie copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? posterUrl,
    String? backdropUrl,
    String? categoryId,
    String? description,
    String? releaseDate,
    double? rating,
    int? duration,
    String? genre,
    String? director,
    List<String>? cast,
    Map<String, dynamic>? metadata,
  }) {
    return Movie(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      releaseDate: releaseDate ?? this.releaseDate,
      rating: rating ?? this.rating,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      director: director ?? this.director,
      cast: cast ?? this.cast,
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
        categoryId,
        description,
        releaseDate,
        rating,
        duration,
        genre,
        director,
        cast,
        metadata,
      ];
}

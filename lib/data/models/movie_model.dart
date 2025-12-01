import '../../domain/entities/movie.dart';

/// Movie model for data layer
class MovieModel {
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

  const MovieModel({
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

  /// Create from JSON
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['stream_id']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['name'] ?? json['title'] ?? '') as String,
      streamUrl: (json['stream_url'] ?? '') as String,
      posterUrl: json['stream_icon'] as String? ??
          json['cover'] as String? ??
          json['poster_url'] as String?,
      backdropUrl:
          json['cover_big'] as String? ?? json['backdrop_url'] as String?,
      categoryId: json['category_id']?.toString(),
      description: json['plot'] as String? ?? json['description'] as String?,
      releaseDate:
          json['releaseDate'] as String? ?? json['release_date'] as String?,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      duration: json['duration_secs'] as int? ?? json['duration'] as int?,
      genre: _parseGenre(json['genre']),
      director: json['director'] as String?,
      cast: _parseCast(json['cast']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Parse genre field that can be String, List, or null
  static String? _parseGenre(dynamic genre) {
    if (genre == null) return null;
    if (genre is String) return genre;
    if (genre is List) return genre.join(', ');
    return genre.toString();
  }

  /// Parse cast field that can be String, List, or null
  static List<String>? _parseCast(dynamic cast) {
    if (cast == null) return null;
    if (cast is String) {
      return cast.split(',').map((e) => e.trim()).toList();
    }
    if (cast is List) {
      return cast.map((e) => e.toString()).toList();
    }
    return null;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stream_url': streamUrl,
      'poster_url': posterUrl,
      'backdrop_url': backdropUrl,
      'category_id': categoryId,
      'description': description,
      'release_date': releaseDate,
      'rating': rating,
      'duration': duration,
      'genre': genre,
      'director': director,
      'cast': cast,
      'metadata': metadata,
    };
  }

  /// Convert to domain entity
  Movie toEntity() {
    return Movie(
      id: id,
      name: name,
      streamUrl: streamUrl,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      categoryId: categoryId,
      description: description,
      releaseDate: releaseDate,
      rating: rating,
      duration: duration,
      genre: genre,
      director: director,
      cast: cast,
      metadata: metadata,
    );
  }

  /// Create from domain entity
  factory MovieModel.fromEntity(Movie entity) {
    return MovieModel(
      id: entity.id,
      name: entity.name,
      streamUrl: entity.streamUrl,
      posterUrl: entity.posterUrl,
      backdropUrl: entity.backdropUrl,
      categoryId: entity.categoryId,
      description: entity.description,
      releaseDate: entity.releaseDate,
      rating: entity.rating,
      duration: entity.duration,
      genre: entity.genre,
      director: entity.director,
      cast: entity.cast,
      metadata: entity.metadata,
    );
  }
}

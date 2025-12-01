// XtreamToDomainMappers
// Centralized mapping functions for converting Xtream API responses to domain models.
// Keeps raw Xtream types separate from UI/domain types.

import '../../core/models/base_models.dart';
import '../account/xtream_account_models.dart';

/// Mapper class for converting Xtream API responses to domain models
class XtreamToDomainMappers {
  XtreamToDomainMappers._();

  /// Map Xtream channel response to DomainChannel
  static DomainChannel mapChannel(
    Map<String, dynamic> json,
    String streamUrl,
  ) {
    return DomainChannel(
      id: json['stream_id']?.toString() ?? json['num']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      streamUrl: streamUrl,
      logoUrl: json['stream_icon']?.toString() ?? json['cover']?.toString(),
      groupTitle: json['category_name']?.toString(),
      categoryId: json['category_id']?.toString(),
      type: ContentType.live,
      metadata: _extractMetadata(json, [
        'stream_id',
        'name',
        'stream_icon',
        'cover',
        'category_name',
        'category_id',
      ]),
    );
  }

  /// Map Xtream category response to DomainCategory
  static DomainCategory mapCategory(Map<String, dynamic> json) {
    return DomainCategory(
      id: json['category_id']?.toString() ?? '',
      name: json['category_name']?.toString() ?? '',
      channelCount: _parseInt(json['num']),
      iconUrl: json['category_icon']?.toString(),
      sortOrder: _parseInt(json['parent_id']),
    );
  }

  /// Map Xtream movie response to VodItem
  static VodItem mapMovie(
    Map<String, dynamic> json,
    String streamUrl,
  ) {
    return VodItem(
      id: json['stream_id']?.toString() ?? json['num']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      streamUrl: streamUrl,
      posterUrl: json['stream_icon']?.toString() ?? json['cover']?.toString(),
      backdropUrl: json['cover_big']?.toString() ?? json['backdrop_path']?.toString(),
      description: json['plot']?.toString() ?? json['description']?.toString(),
      categoryId: json['category_id']?.toString(),
      genre: json['genre']?.toString(),
      releaseDate: json['releaseDate']?.toString() ?? json['release_date']?.toString(),
      rating: _parseRating(json['rating']),
      duration: _parseInt(json['duration_secs']),
      type: ContentType.movie,
      metadata: _extractMetadata(json, [
        'stream_id',
        'name',
        'stream_icon',
        'cover',
        'cover_big',
        'backdrop_path',
        'plot',
        'description',
        'category_id',
        'genre',
        'releaseDate',
        'release_date',
        'rating',
        'duration_secs',
      ]),
    );
  }

  /// Map Xtream series response to DomainSeries
  static DomainSeries mapSeries(
    Map<String, dynamic> json, {
    List<Season> seasons = const [],
  }) {
    return DomainSeries(
      id: json['series_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      posterUrl: json['cover']?.toString(),
      backdropUrl: _parseBackdropPath(json['backdrop_path']),
      description: json['plot']?.toString(),
      categoryId: json['category_id']?.toString(),
      genre: json['genre']?.toString(),
      releaseDate: json['releaseDate']?.toString() ?? json['release_date']?.toString(),
      rating: _parseRating(json['rating']),
      seasons: seasons,
      metadata: _extractMetadata(json, [
        'series_id',
        'name',
        'cover',
        'backdrop_path',
        'plot',
        'category_id',
        'genre',
        'releaseDate',
        'release_date',
        'rating',
      ]),
    );
  }

  /// Map Xtream series info response to DomainSeries with seasons and episodes
  static DomainSeries mapSeriesWithEpisodes(
    Map<String, dynamic> json,
    String Function(String streamId, String extension) buildStreamUrl,
  ) {
    final info = json['info'] ?? {};
    final episodesMap = json['episodes'] as Map<String, dynamic>? ?? {};

    final seasons = <Season>[];
    episodesMap.forEach((seasonNumber, episodeList) {
      if (episodeList is! List) return;

      final episodes = episodeList.map((e) {
        final streamId = e['id']?.toString() ?? '';
        final extension = e['container_extension']?.toString() ?? 'mp4';
        return mapEpisode(e as Map<String, dynamic>, buildStreamUrl(streamId, extension));
      }).toList();

      seasons.add(Season(
        id: seasonNumber,
        seasonNumber: int.tryParse(seasonNumber) ?? 1,
        name: 'Season $seasonNumber',
        episodes: episodes,
      ));
    });

    return mapSeries(info, seasons: seasons);
  }

  /// Map Xtream episode response to Episode
  static Episode mapEpisode(Map<String, dynamic> json, String streamUrl) {
    return Episode(
      id: json['id']?.toString() ?? '',
      episodeNumber: _parseInt(json['episode_num'], defaultValue: 1),
      name: json['title']?.toString() ?? json['name']?.toString() ?? '',
      streamUrl: streamUrl,
      description: json['info']?['plot']?.toString() ?? json['plot']?.toString(),
      thumbnailUrl: json['info']?['movie_image']?.toString() ?? json['cover']?.toString(),
      duration: _parseInt(json['info']?['duration_secs']),
      airDate: json['info']?['releasedate']?.toString(),
    );
  }

  /// Map Xtream EPG entry to EpgInfo
  static EpgInfo mapEpgEntry(Map<String, dynamic> json) {
    final startTime = _parseDateTime(json['start'] ?? json['start_timestamp']);
    final endTime = _parseDateTime(json['end'] ?? json['stop_timestamp']);

    return EpgInfo(
      currentProgram: json['title']?.toString(),
      description: json['description']?.toString() ?? json['desc']?.toString(),
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Map account overview from login response
  static XtreamAccountOverview mapAccountOverview(Map<String, dynamic> json) {
    return XtreamAccountOverview.fromJson(json);
  }

  // Helper methods
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double? _parseRating(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String) {
      final timestamp = int.tryParse(value);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String? _parseBackdropPath(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isNotEmpty ? value : null;
    if (value is List && value.isNotEmpty) {
      return value.first?.toString();
    }
    return null;
  }

  static Map<String, dynamic>? _extractMetadata(
    Map<String, dynamic> json,
    List<String> excludeKeys,
  ) {
    final metadata = <String, dynamic>{};
    json.forEach((key, value) {
      if (!excludeKeys.contains(key) && value != null) {
        metadata[key] = value;
      }
    });
    return metadata.isNotEmpty ? metadata : null;
  }
}

// Xtream Mappers
// Mappers to convert Xtream API models to domain models.

import '../../core/models/base_models.dart';
import '../account/xtream_api_client.dart';
import '../models/xtream_api_models.dart';

/// Mapper class for Xtream to Domain conversions
class XtreamMappers {
  /// Convert Xtream live stream to DomainChannel
  static DomainChannel liveStreamToChannel(
    XtreamLiveStream stream,
    XtreamApiClient apiClient,
  ) {
    return DomainChannel(
      id: 'xtream_live_${stream.streamId}',
      name: stream.name,
      streamUrl: apiClient.getLiveStreamUrl(stream.streamId),
      logoUrl: stream.streamIcon.isNotEmpty ? stream.streamIcon : null,
      groupTitle: null, // Will be enriched with category name from repository
      categoryId: stream.categoryId,
      type: ContentType.live,
      metadata: {
        'streamId': stream.streamId,
        'epgChannelId': stream.epgChannelId,
        'streamType': stream.streamType,
        'tvArchive': stream.tvArchive,
        'tvArchiveDuration': stream.tvArchiveDuration,
        'added': stream.added,
      },
    );
  }

  /// Convert Xtream live category to DomainCategory
  static DomainCategory liveCategoryToCategory(XtreamLiveCategory category) {
    return DomainCategory(
      id: category.categoryId,
      name: category.categoryName,
      channelCount: 0, // Will be updated when channels are loaded
    );
  }

  /// Convert Xtream VOD stream to VodItem
  static VodItem vodStreamToVodItem(
    XtreamVodStream stream,
    XtreamApiClient apiClient,
  ) {
    // Parse rating
    double? rating;
    try {
      rating = double.tryParse(stream.rating);
    } catch (_) {
      rating = null;
    }

    final extension = stream.containerExtension ?? 'mp4';

    return VodItem(
      id: 'xtream_vod_${stream.streamId}',
      name: stream.name,
      streamUrl: apiClient.getVodStreamUrl(stream.streamId, extension),
      posterUrl: stream.streamIcon.isNotEmpty ? stream.streamIcon : null,
      categoryId: stream.categoryId,
      rating: rating,
      type: ContentType.movie,
      metadata: {
        'streamId': stream.streamId,
        'streamType': stream.streamType,
        'containerExtension': extension,
        'added': stream.added,
      },
    );
  }

  /// Convert Xtream VOD info to VodItem (with detailed information)
  static VodItem vodInfoToVodItem(
    XtreamVodInfo info,
    XtreamApiClient apiClient,
  ) {
    // Parse rating
    double? rating;
    try {
      rating = info.info.rating != null 
          ? double.tryParse(info.info.rating!) 
          : null;
    } catch (_) {
      rating = null;
    }

    // Parse duration
    int? duration;
    try {
      duration = info.info.durationSecs != null
          ? int.tryParse(info.info.durationSecs!)
          : null;
    } catch (_) {
      duration = null;
    }

    final extension = info.movieData.containerExtension;

    return VodItem(
      id: 'xtream_vod_${info.movieData.streamId}',
      name: info.info.name ?? info.movieData.name,
      streamUrl: apiClient.getVodStreamUrl(info.movieData.streamId, extension),
      posterUrl: info.info.cover,
      backdropUrl: info.info.backdropPath,
      description: info.info.plot,
      categoryId: info.movieData.categoryId,
      genre: info.info.genre,
      releaseDate: info.info.releaseDate,
      rating: rating,
      duration: duration,
      type: ContentType.movie,
      metadata: {
        'streamId': info.movieData.streamId,
        'tmdbId': info.info.tmdbId,
        'containerExtension': extension,
        'cast': info.info.cast,
        'director': info.info.director,
        'added': info.movieData.added,
      },
    );
  }

  /// Convert Xtream VOD category to DomainCategory
  static DomainCategory vodCategoryToCategory(XtreamVodCategory category) {
    return DomainCategory(
      id: category.categoryId,
      name: category.categoryName,
      channelCount: 0,
    );
  }

  /// Convert Xtream series to DomainSeries
  static DomainSeries seriesToDomainSeries(
    XtreamSeries series,
    XtreamApiClient apiClient,
  ) {
    // Parse rating
    double? rating;
    try {
      rating = double.tryParse(series.rating);
    } catch (_) {
      rating = null;
    }

    return DomainSeries(
      id: 'xtream_series_${series.seriesId}',
      name: series.name,
      posterUrl: series.cover.isNotEmpty ? series.cover : null,
      backdropUrl: series.backdropPath,
      description: series.plot,
      categoryId: series.categoryId,
      genre: series.genre,
      releaseDate: series.releaseDate,
      rating: rating,
      metadata: {
        'seriesId': series.seriesId,
        'cast': series.cast,
        'director': series.director,
        'lastModified': series.lastModified,
      },
    );
  }

  /// Convert Xtream series info to DomainSeries (with seasons and episodes)
  static DomainSeries seriesInfoToDoMainSeries(
    XtreamSeriesInfo info,
    String seriesId,
    XtreamApiClient apiClient,
  ) {
    // Parse rating
    double? rating;
    try {
      rating = info.info.rating != null 
          ? double.tryParse(info.info.rating!) 
          : null;
    } catch (_) {
      rating = null;
    }

    // Convert seasons
    final seasons = info.seasons.map((s) {
      final seasonNum = int.tryParse(s.seasonNumber) ?? 0;
      final episodes = info.episodes[s.seasonNumber] ?? [];

      return Season(
        id: 'xtream_season_${seriesId}_${s.seasonNumber}',
        seasonNumber: seasonNum,
        name: s.name,
        posterUrl: s.coverTmdb,
        episodes: episodes.map((e) => _episodeToEpisode(e, apiClient)).toList(),
      );
    }).toList();

    return DomainSeries(
      id: 'xtream_series_$seriesId',
      name: info.info.name ?? '',
      posterUrl: info.info.cover,
      backdropUrl: info.info.backdropPath,
      description: info.info.plot,
      genre: info.info.genre,
      releaseDate: info.info.releaseDate,
      rating: rating,
      seasons: seasons,
      metadata: {
        'seriesId': seriesId,
        'cast': info.info.cast,
        'director': info.info.director,
      },
    );
  }

  /// Convert Xtream episode to Episode
  static Episode _episodeToEpisode(
    XtreamEpisode episode,
    XtreamApiClient apiClient,
  ) {
    final episodeNum = int.tryParse(episode.episodeNum) ?? 0;
    final extension = episode.containerExtension;

    // Parse duration
    int? duration;
    try {
      duration = episode.info?.durationSecs != null
          ? int.tryParse(episode.info!.durationSecs!)
          : null;
    } catch (_) {
      duration = null;
    }

    return Episode(
      id: 'xtream_episode_${episode.id}',
      episodeNumber: episodeNum,
      name: episode.info?.name ?? episode.title,
      streamUrl: apiClient.getSeriesStreamUrl(episode.id, extension),
      description: episode.info?.overview,
      duration: duration,
      airDate: episode.info?.airDate ?? episode.added,
    );
  }

  /// Convert Xtream series category to DomainCategory
  static DomainCategory seriesCategoryToCategory(
    XtreamSeriesCategory category,
  ) {
    return DomainCategory(
      id: category.categoryId,
      name: category.categoryName,
      channelCount: 0,
    );
  }
}

// Xtream API Response Models
// Data transfer objects for Xtream Codes API responses.

/// Xtream authentication response
class XtreamAuthResponse {
  const XtreamAuthResponse({
    required this.userInfo,
    required this.serverInfo,
  });

  factory XtreamAuthResponse.fromJson(Map<String, dynamic> json) {
    return XtreamAuthResponse(
      userInfo: XtreamUserInfo.fromJson(json['user_info'] as Map<String, dynamic>),
      serverInfo: XtreamServerInfo.fromJson(json['server_info'] as Map<String, dynamic>),
    );
  }

  final XtreamUserInfo userInfo;
  final XtreamServerInfo serverInfo;
}

/// Xtream user information
class XtreamUserInfo {
  const XtreamUserInfo({
    required this.username,
    required this.password,
    required this.status,
    required this.expDate,
    required this.isTrial,
    required this.activeCons,
    required this.maxConnections,
    this.message,
    this.auth,
  });

  factory XtreamUserInfo.fromJson(Map<String, dynamic> json) {
    return XtreamUserInfo(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      status: json['status'] as String? ?? '',
      expDate: json['exp_date'] as String? ?? '',
      isTrial: json['is_trial'] as String? ?? '0',
      activeCons: json['active_cons'] as String? ?? '0',
      maxConnections: json['max_connections'] as String? ?? '0',
      message: json['message'] as String?,
      auth: json['auth'] as int?,
    );
  }

  final String username;
  final String password;
  final String status;
  final String expDate;
  final String isTrial;
  final String activeCons;
  final String maxConnections;
  final String? message;
  final int? auth;

  bool get isActive => status == 'Active' || auth == 1;
  bool get isExpired {
    if (expDate.isEmpty) return false;
    try {
      final timestamp = int.tryParse(expDate);
      if (timestamp == null) return false;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return expiryDate.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}

/// Xtream server information
class XtreamServerInfo {
  const XtreamServerInfo({
    required this.url,
    required this.port,
    required this.httpsPort,
    required this.serverProtocol,
    required this.rtmpPort,
    required this.timestampNow,
    this.timeNow,
  });

  factory XtreamServerInfo.fromJson(Map<String, dynamic> json) {
    return XtreamServerInfo(
      url: json['url'] as String? ?? '',
      port: json['port'] as String? ?? '',
      httpsPort: json['https_port'] as String? ?? '',
      serverProtocol: json['server_protocol'] as String? ?? 'http',
      rtmpPort: json['rtmp_port'] as String? ?? '',
      timestampNow: json['timestamp_now'] as int? ?? 0,
      timeNow: json['time_now'] as String?,
    );
  }

  final String url;
  final String port;
  final String httpsPort;
  final String serverProtocol;
  final String rtmpPort;
  final int timestampNow;
  final String? timeNow;
}

/// Xtream live stream category
class XtreamLiveCategory {
  const XtreamLiveCategory({
    required this.categoryId,
    required this.categoryName,
    this.parentId,
  });

  factory XtreamLiveCategory.fromJson(Map<String, dynamic> json) {
    return XtreamLiveCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] as String? ?? '',
      parentId: json['parent_id']?.toString(),
    );
  }

  final String categoryId;
  final String categoryName;
  final String? parentId;
}

/// Xtream live stream
class XtreamLiveStream {
  const XtreamLiveStream({
    required this.num,
    required this.name,
    required this.streamType,
    required this.streamId,
    required this.streamIcon,
    required this.epgChannelId,
    required this.added,
    required this.categoryId,
    this.customSid,
    this.tvArchive,
    this.directSource,
    this.tvArchiveDuration,
  });

  factory XtreamLiveStream.fromJson(Map<String, dynamic> json) {
    return XtreamLiveStream(
      num: json['num']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      streamType: json['stream_type'] as String? ?? '',
      streamId: json['stream_id']?.toString() ?? '',
      streamIcon: json['stream_icon'] as String? ?? '',
      epgChannelId: json['epg_channel_id'] as String? ?? '',
      added: json['added'] as String? ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      customSid: json['custom_sid'] as String?,
      tvArchive: json['tv_archive']?.toString(),
      directSource: json['direct_source'] as String?,
      tvArchiveDuration: json['tv_archive_duration']?.toString(),
    );
  }

  final String num;
  final String name;
  final String streamType;
  final String streamId;
  final String streamIcon;
  final String epgChannelId;
  final String added;
  final String categoryId;
  final String? customSid;
  final String? tvArchive;
  final String? directSource;
  final String? tvArchiveDuration;
}

/// Xtream VOD category
class XtreamVodCategory {
  const XtreamVodCategory({
    required this.categoryId,
    required this.categoryName,
    this.parentId,
  });

  factory XtreamVodCategory.fromJson(Map<String, dynamic> json) {
    return XtreamVodCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] as String? ?? '',
      parentId: json['parent_id']?.toString(),
    );
  }

  final String categoryId;
  final String categoryName;
  final String? parentId;
}

/// Xtream VOD stream
class XtreamVodStream {
  const XtreamVodStream({
    required this.num,
    required this.name,
    required this.streamType,
    required this.streamId,
    required this.streamIcon,
    required this.rating,
    required this.categoryId,
    required this.added,
    this.containerExtension,
    this.customSid,
    this.directSource,
  });

  factory XtreamVodStream.fromJson(Map<String, dynamic> json) {
    return XtreamVodStream(
      num: json['num']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      streamType: json['stream_type'] as String? ?? '',
      streamId: json['stream_id']?.toString() ?? '',
      streamIcon: json['stream_icon'] as String? ?? '',
      rating: json['rating']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      added: json['added'] as String? ?? '',
      containerExtension: json['container_extension'] as String?,
      customSid: json['custom_sid'] as String?,
      directSource: json['direct_source'] as String?,
    );
  }

  final String num;
  final String name;
  final String streamType;
  final String streamId;
  final String streamIcon;
  final String rating;
  final String categoryId;
  final String added;
  final String? containerExtension;
  final String? customSid;
  final String? directSource;
}

/// Xtream VOD info
class XtreamVodInfo {
  const XtreamVodInfo({
    required this.info,
    required this.movieData,
  });

  factory XtreamVodInfo.fromJson(Map<String, dynamic> json) {
    return XtreamVodInfo(
      info: XtreamVodInfoDetails.fromJson(json['info'] as Map<String, dynamic>),
      movieData: XtreamMovieData.fromJson(json['movie_data'] as Map<String, dynamic>),
    );
  }

  final XtreamVodInfoDetails info;
  final XtreamMovieData movieData;
}

/// Xtream VOD info details
class XtreamVodInfoDetails {
  const XtreamVodInfoDetails({
    this.tmdbId,
    this.name,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.durationSecs,
    this.rating,
    this.backdropPath,
  });

  factory XtreamVodInfoDetails.fromJson(Map<String, dynamic> json) {
    return XtreamVodInfoDetails(
      tmdbId: json['tmdb_id']?.toString(),
      name: json['name'] as String?,
      cover: json['cover'] as String?,
      plot: json['plot'] as String?,
      cast: json['cast'] as String?,
      director: json['director'] as String?,
      genre: json['genre'] as String?,
      releaseDate: json['releasedate'] as String?,
      durationSecs: json['duration_secs']?.toString(),
      rating: json['rating']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
    );
  }

  final String? tmdbId;
  final String? name;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final String? durationSecs;
  final String? rating;
  final String? backdropPath;
}

/// Xtream movie data
class XtreamMovieData {
  const XtreamMovieData({
    required this.streamId,
    required this.name,
    required this.added,
    required this.categoryId,
    required this.containerExtension,
    this.customSid,
    this.directSource,
  });

  factory XtreamMovieData.fromJson(Map<String, dynamic> json) {
    return XtreamMovieData(
      streamId: json['stream_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      added: json['added'] as String? ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      containerExtension: json['container_extension'] as String? ?? '',
      customSid: json['custom_sid'] as String?,
      directSource: json['direct_source'] as String?,
    );
  }

  final String streamId;
  final String name;
  final String added;
  final String categoryId;
  final String containerExtension;
  final String? customSid;
  final String? directSource;
}

/// Xtream series category
class XtreamSeriesCategory {
  const XtreamSeriesCategory({
    required this.categoryId,
    required this.categoryName,
    this.parentId,
  });

  factory XtreamSeriesCategory.fromJson(Map<String, dynamic> json) {
    return XtreamSeriesCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] as String? ?? '',
      parentId: json['parent_id']?.toString(),
    );
  }

  final String categoryId;
  final String categoryName;
  final String? parentId;
}

/// Xtream series
class XtreamSeries {
  const XtreamSeries({
    required this.num,
    required this.name,
    required this.seriesId,
    required this.cover,
    required this.plot,
    required this.cast,
    required this.director,
    required this.genre,
    required this.releaseDate,
    required this.lastModified,
    required this.rating,
    required this.categoryId,
    this.backdropPath,
  });

  factory XtreamSeries.fromJson(Map<String, dynamic> json) {
    return XtreamSeries(
      num: json['num']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      seriesId: json['series_id']?.toString() ?? '',
      cover: json['cover'] as String? ?? '',
      plot: json['plot'] as String? ?? '',
      cast: json['cast'] as String? ?? '',
      director: json['director'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      releaseDate: json['releaseDate'] as String? ?? '',
      lastModified: json['last_modified'] as String? ?? '',
      rating: json['rating']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      backdropPath: json['backdrop_path']?.toString(),
    );
  }

  final String num;
  final String name;
  final String seriesId;
  final String cover;
  final String plot;
  final String cast;
  final String director;
  final String genre;
  final String releaseDate;
  final String lastModified;
  final String rating;
  final String categoryId;
  final String? backdropPath;
}

/// Xtream series info
class XtreamSeriesInfo {
  const XtreamSeriesInfo({
    required this.seasons,
    required this.info,
    required this.episodes,
  });

  factory XtreamSeriesInfo.fromJson(Map<String, dynamic> json) {
    final seasonsData = json['seasons'] as List<dynamic>? ?? [];
    final episodesData = json['episodes'] as Map<String, dynamic>? ?? {};
    
    return XtreamSeriesInfo(
      seasons: seasonsData
          .map((s) => XtreamSeasonInfo.fromJson(s as Map<String, dynamic>))
          .toList(),
      info: XtreamSeriesInfoDetails.fromJson(json['info'] as Map<String, dynamic>),
      episodes: episodesData.map((key, value) {
        final episodesList = (value as List<dynamic>)
            .map((e) => XtreamEpisode.fromJson(e as Map<String, dynamic>))
            .toList();
        return MapEntry(key, episodesList);
      }),
    );
  }

  final List<XtreamSeasonInfo> seasons;
  final XtreamSeriesInfoDetails info;
  final Map<String, List<XtreamEpisode>> episodes;
}

/// Xtream season info
class XtreamSeasonInfo {
  const XtreamSeasonInfo({
    required this.airDate,
    required this.episodeCount,
    required this.id,
    required this.name,
    required this.overview,
    required this.seasonNumber,
    this.coverTmdb,
  });

  factory XtreamSeasonInfo.fromJson(Map<String, dynamic> json) {
    return XtreamSeasonInfo(
      airDate: json['air_date'] as String? ?? '',
      episodeCount: json['episode_count']?.toString() ?? '0',
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      seasonNumber: json['season_number']?.toString() ?? '0',
      coverTmdb: json['cover_tmdb'] as String?,
    );
  }

  final String airDate;
  final String episodeCount;
  final String id;
  final String name;
  final String overview;
  final String seasonNumber;
  final String? coverTmdb;
}

/// Xtream series info details
class XtreamSeriesInfoDetails {
  const XtreamSeriesInfoDetails({
    this.name,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.rating,
    this.backdropPath,
  });

  factory XtreamSeriesInfoDetails.fromJson(Map<String, dynamic> json) {
    return XtreamSeriesInfoDetails(
      name: json['name'] as String?,
      cover: json['cover'] as String?,
      plot: json['plot'] as String?,
      cast: json['cast'] as String?,
      director: json['director'] as String?,
      genre: json['genre'] as String?,
      releaseDate: json['releaseDate'] as String?,
      rating: json['rating']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
    );
  }

  final String? name;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final String? rating;
  final String? backdropPath;
}

/// Xtream episode
class XtreamEpisode {
  const XtreamEpisode({
    required this.id,
    required this.episodeNum,
    required this.title,
    required this.containerExtension,
    this.info,
    this.customSid,
    this.added,
    this.season,
    this.directSource,
  });

  factory XtreamEpisode.fromJson(Map<String, dynamic> json) {
    return XtreamEpisode(
      id: json['id']?.toString() ?? '',
      episodeNum: json['episode_num']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      containerExtension: json['container_extension'] as String? ?? '',
      info: json['info'] != null 
          ? XtreamEpisodeInfo.fromJson(json['info'] as Map<String, dynamic>)
          : null,
      customSid: json['custom_sid'] as String?,
      added: json['added'] as String?,
      season: json['season']?.toString(),
      directSource: json['direct_source'] as String?,
    );
  }

  final String id;
  final String episodeNum;
  final String title;
  final String containerExtension;
  final XtreamEpisodeInfo? info;
  final String? customSid;
  final String? added;
  final String? season;
  final String? directSource;
}

/// Xtream episode info
class XtreamEpisodeInfo {
  const XtreamEpisodeInfo({
    this.airDate,
    this.crew,
    this.rating,
    this.name,
    this.overview,
    this.seasonNumber,
    this.episodeNumber,
    this.durationSecs,
  });

  factory XtreamEpisodeInfo.fromJson(Map<String, dynamic> json) {
    return XtreamEpisodeInfo(
      airDate: json['air_date'] as String?,
      crew: json['crew'] as String?,
      rating: json['rating']?.toString(),
      name: json['name'] as String?,
      overview: json['overview'] as String?,
      seasonNumber: json['season_number']?.toString(),
      episodeNumber: json['episode_number']?.toString(),
      durationSecs: json['duration_secs']?.toString(),
    );
  }

  final String? airDate;
  final String? crew;
  final String? rating;
  final String? name;
  final String? overview;
  final String? seasonNumber;
  final String? episodeNumber;
  final String? durationSecs;
}

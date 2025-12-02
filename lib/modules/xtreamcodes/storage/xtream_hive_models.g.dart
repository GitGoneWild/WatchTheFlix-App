// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xtream_hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveContentTypeAdapter extends TypeAdapter<HiveContentType> {
  @override
  final int typeId = 109;

  @override
  HiveContentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HiveContentType.live;
      case 1:
        return HiveContentType.movie;
      case 2:
        return HiveContentType.series;
      default:
        return HiveContentType.live;
    }
  }

  @override
  void write(BinaryWriter writer, HiveContentType obj) {
    switch (obj) {
      case HiveContentType.live:
        writer.writeByte(0);
        break;
      case HiveContentType.movie:
        writer.writeByte(1);
        break;
      case HiveContentType.series:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveContentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveChannelAdapter extends TypeAdapter<HiveChannel> {
  @override
  final int typeId = 100;

  @override
  HiveChannel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveChannel(
      id: fields[0] as String,
      name: fields[1] as String,
      streamUrl: fields[2] as String,
      logoUrl: fields[3] as String?,
      groupTitle: fields[4] as String?,
      categoryId: fields[5] as String?,
      type: fields[6] as HiveContentType,
      metadata: (fields[7] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveChannel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.streamUrl)
      ..writeByte(3)
      ..write(obj.logoUrl)
      ..writeByte(4)
      ..write(obj.groupTitle)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveCategoryAdapter extends TypeAdapter<HiveCategory> {
  @override
  final int typeId = 101;

  @override
  HiveCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      channelCount: fields[2] as int,
      iconUrl: fields[3] as String?,
      sortOrder: fields[4] as int?,
      categoryType: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCategory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.channelCount)
      ..writeByte(3)
      ..write(obj.iconUrl)
      ..writeByte(4)
      ..write(obj.sortOrder)
      ..writeByte(5)
      ..write(obj.categoryType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveVodItemAdapter extends TypeAdapter<HiveVodItem> {
  @override
  final int typeId = 102;

  @override
  HiveVodItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveVodItem(
      id: fields[0] as String,
      name: fields[1] as String,
      streamUrl: fields[2] as String,
      posterUrl: fields[3] as String?,
      backdropUrl: fields[4] as String?,
      description: fields[5] as String?,
      categoryId: fields[6] as String?,
      genre: fields[7] as String?,
      releaseDate: fields[8] as String?,
      rating: fields[9] as double?,
      duration: fields[10] as int?,
      metadata: (fields[11] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveVodItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.streamUrl)
      ..writeByte(3)
      ..write(obj.posterUrl)
      ..writeByte(4)
      ..write(obj.backdropUrl)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.genre)
      ..writeByte(8)
      ..write(obj.releaseDate)
      ..writeByte(9)
      ..write(obj.rating)
      ..writeByte(10)
      ..write(obj.duration)
      ..writeByte(11)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveVodItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSeriesAdapter extends TypeAdapter<HiveSeries> {
  @override
  final int typeId = 103;

  @override
  HiveSeries read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSeries(
      id: fields[0] as String,
      name: fields[1] as String,
      posterUrl: fields[2] as String?,
      backdropUrl: fields[3] as String?,
      description: fields[4] as String?,
      categoryId: fields[5] as String?,
      genre: fields[6] as String?,
      releaseDate: fields[7] as String?,
      rating: fields[8] as double?,
      seasons: (fields[9] as List).cast<HiveSeason>(),
      metadata: (fields[10] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveSeries obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.posterUrl)
      ..writeByte(3)
      ..write(obj.backdropUrl)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.genre)
      ..writeByte(7)
      ..write(obj.releaseDate)
      ..writeByte(8)
      ..write(obj.rating)
      ..writeByte(9)
      ..write(obj.seasons)
      ..writeByte(10)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSeriesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSeasonAdapter extends TypeAdapter<HiveSeason> {
  @override
  final int typeId = 104;

  @override
  HiveSeason read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSeason(
      id: fields[0] as String,
      seasonNumber: fields[1] as int,
      name: fields[2] as String?,
      posterUrl: fields[3] as String?,
      episodes: (fields[4] as List).cast<HiveEpisode>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveSeason obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.seasonNumber)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.posterUrl)
      ..writeByte(4)
      ..write(obj.episodes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSeasonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveEpisodeAdapter extends TypeAdapter<HiveEpisode> {
  @override
  final int typeId = 105;

  @override
  HiveEpisode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveEpisode(
      id: fields[0] as String,
      episodeNumber: fields[1] as int,
      name: fields[2] as String,
      streamUrl: fields[3] as String,
      description: fields[4] as String?,
      thumbnailUrl: fields[5] as String?,
      duration: fields[6] as int?,
      airDate: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveEpisode obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.episodeNumber)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.streamUrl)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.thumbnailUrl)
      ..writeByte(6)
      ..write(obj.duration)
      ..writeByte(7)
      ..write(obj.airDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveEpisodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveEpgProgramAdapter extends TypeAdapter<HiveEpgProgram> {
  @override
  final int typeId = 108;

  @override
  HiveEpgProgram read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveEpgProgram(
      channelId: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime,
      category: fields[5] as String?,
      language: fields[6] as String?,
      episodeNumber: fields[7] as String?,
      iconUrl: fields[8] as String?,
      subtitle: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveEpgProgram obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.channelId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.language)
      ..writeByte(7)
      ..write(obj.episodeNumber)
      ..writeByte(8)
      ..write(obj.iconUrl)
      ..writeByte(9)
      ..write(obj.subtitle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveEpgProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSyncStatusAdapter extends TypeAdapter<HiveSyncStatus> {
  @override
  final int typeId = 107;

  @override
  HiveSyncStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSyncStatus(
      profileId: fields[0] as String,
      lastChannelSync: fields[1] as DateTime?,
      lastMovieSync: fields[2] as DateTime?,
      lastSeriesSync: fields[3] as DateTime?,
      lastEpgSync: fields[4] as DateTime?,
      lastCategorySync: fields[5] as DateTime?,
      isInitialSyncComplete: fields[6] as bool,
      channelCount: fields[7] as int?,
      movieCount: fields[8] as int?,
      seriesCount: fields[9] as int?,
      epgProgramCount: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSyncStatus obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.profileId)
      ..writeByte(1)
      ..write(obj.lastChannelSync)
      ..writeByte(2)
      ..write(obj.lastMovieSync)
      ..writeByte(3)
      ..write(obj.lastSeriesSync)
      ..writeByte(4)
      ..write(obj.lastEpgSync)
      ..writeByte(5)
      ..write(obj.lastCategorySync)
      ..writeByte(6)
      ..write(obj.isInitialSyncComplete)
      ..writeByte(7)
      ..write(obj.channelCount)
      ..writeByte(8)
      ..write(obj.movieCount)
      ..writeByte(9)
      ..write(obj.seriesCount)
      ..writeByte(10)
      ..write(obj.epgProgramCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

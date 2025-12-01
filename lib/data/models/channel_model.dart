import '../../domain/entities/channel.dart';

/// Channel model for data layer
class ChannelModel {
  final String id;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? groupTitle;
  final String? categoryId;
  final String type;
  final Map<String, dynamic>? metadata;
  final EpgInfoModel? epgInfo;

  const ChannelModel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.groupTitle,
    this.categoryId,
    this.type = 'live',
    this.metadata,
    this.epgInfo,
  });

  /// Create from JSON
  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id']?.toString() ?? json['stream_id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      streamUrl: json['stream_url'] ?? json['url'] ?? '',
      logoUrl: json['logo_url'] ?? json['stream_icon'] ?? json['tvg_logo'],
      groupTitle: json['group_title'] ?? json['category_name'],
      categoryId: json['category_id']?.toString(),
      type: json['type'] ?? 'live',
      metadata: json['metadata'],
      epgInfo: json['epg_info'] != null
          ? EpgInfoModel.fromJson(json['epg_info'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stream_url': streamUrl,
      'logo_url': logoUrl,
      'group_title': groupTitle,
      'category_id': categoryId,
      'type': type,
      'metadata': metadata,
      'epg_info': epgInfo?.toJson(),
    };
  }

  /// Convert to domain entity
  Channel toEntity() {
    return Channel(
      id: id,
      name: name,
      streamUrl: streamUrl,
      logoUrl: logoUrl,
      groupTitle: groupTitle,
      categoryId: categoryId,
      type: _parseContentType(type),
      metadata: metadata,
      epgInfo: epgInfo?.toEntity(),
    );
  }

  /// Create from domain entity
  factory ChannelModel.fromEntity(Channel entity) {
    return ChannelModel(
      id: entity.id,
      name: entity.name,
      streamUrl: entity.streamUrl,
      logoUrl: entity.logoUrl,
      groupTitle: entity.groupTitle,
      categoryId: entity.categoryId,
      type: entity.type.name,
      metadata: entity.metadata,
      epgInfo: entity.epgInfo != null
          ? EpgInfoModel.fromEntity(entity.epgInfo!)
          : null,
    );
  }

  ContentType _parseContentType(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return ContentType.movie;
      case 'series':
        return ContentType.series;
      default:
        return ContentType.live;
    }
  }
}

/// EPG info model
class EpgInfoModel {
  final String? currentProgram;
  final String? nextProgram;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? description;

  const EpgInfoModel({
    this.currentProgram,
    this.nextProgram,
    this.startTime,
    this.endTime,
    this.description,
  });

  factory EpgInfoModel.fromJson(Map<String, dynamic> json) {
    return EpgInfoModel(
      currentProgram: json['current_program'],
      nextProgram: json['next_program'],
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'])
          : null,
      endTime:
          json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_program': currentProgram,
      'next_program': nextProgram,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'description': description,
    };
  }

  EpgInfo toEntity() {
    return EpgInfo(
      currentProgram: currentProgram,
      nextProgram: nextProgram,
      startTime: startTime,
      endTime: endTime,
      description: description,
    );
  }

  factory EpgInfoModel.fromEntity(EpgInfo entity) {
    return EpgInfoModel(
      currentProgram: entity.currentProgram,
      nextProgram: entity.nextProgram,
      startTime: entity.startTime,
      endTime: entity.endTime,
      description: entity.description,
    );
  }
}

import 'package:equatable/equatable.dart';

/// Content type enumeration
enum ContentType {
  live,
  movie,
  series,
}

/// Channel entity
class Channel extends Equatable {
  const Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.groupTitle,
    this.categoryId,
    this.type = ContentType.live,
    this.metadata,
    this.epgInfo,
  });
  final String id;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? groupTitle;
  final String? categoryId;
  final ContentType type;
  final Map<String, dynamic>? metadata;
  final EpgInfo? epgInfo;

  Channel copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? logoUrl,
    String? groupTitle,
    String? categoryId,
    ContentType? type,
    Map<String, dynamic>? metadata,
    EpgInfo? epgInfo,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      groupTitle: groupTitle ?? this.groupTitle,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      epgInfo: epgInfo ?? this.epgInfo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        streamUrl,
        logoUrl,
        groupTitle,
        categoryId,
        type,
        metadata,
        epgInfo,
      ];
}

/// EPG (Electronic Program Guide) info
class EpgInfo extends Equatable {
  const EpgInfo({
    this.currentProgram,
    this.nextProgram,
    this.startTime,
    this.endTime,
    this.description,
  });
  final String? currentProgram;
  final String? nextProgram;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? description;

  @override
  List<Object?> get props => [
        currentProgram,
        nextProgram,
        startTime,
        endTime,
        description,
      ];
}

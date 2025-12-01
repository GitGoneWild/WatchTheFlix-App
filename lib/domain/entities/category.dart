import 'package:equatable/equatable.dart';

/// Category entity
class Category extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final int channelCount;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.channelCount = 0,
  });

  Category copyWith({
    String? id,
    String? name,
    String? parentId,
    int? channelCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      channelCount: channelCount ?? this.channelCount,
    );
  }

  @override
  List<Object?> get props => [id, name, parentId, channelCount];
}

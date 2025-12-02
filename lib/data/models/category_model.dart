import '../../domain/entities/category.dart';

/// Category model for data layer
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.channelCount = 0,
  });

  /// Create from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['category_id']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['category_name'] ?? json['name'] ?? '') as String,
      parentId: json['parent_id']?.toString(),
      channelCount: (json['channel_count'] ?? 0) as int,
    );
  }

  /// Create from domain entity
  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      parentId: entity.parentId,
      channelCount: entity.channelCount,
    );
  }
  final String id;
  final String name;
  final String? parentId;
  final int channelCount;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'channel_count': channelCount,
    };
  }

  /// Convert to domain entity
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      parentId: parentId,
      channelCount: channelCount,
    );
  }
}

import '../../domain/entities/inventory_category_entity.dart';

class InventoryCategoryModel extends InventoryCategoryEntity {
  final bool isDeleted;

  const InventoryCategoryModel({
    required super.id,
    required super.name,
    super.description,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced,
    this.isDeleted = false,
  });

  factory InventoryCategoryModel.fromEntity(InventoryCategoryEntity entity) {
    return InventoryCategoryModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: entity.isSynced,
    );
  }

  factory InventoryCategoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryCategoryModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
      isSynced: map['isSynced'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toRemoteMap() {
    final map = toMap();
    map['isSynced'] = true;
    return map;
  }
}

import '../../domain/entities/inventory_product_entity.dart';

class InventoryProductModel extends InventoryProductEntity {
  final bool isDeleted;

  const InventoryProductModel({
    required super.id,
    required super.sku,
    super.barcode,
    required super.name,
    required super.categoryId,
    required super.categoryName,
    required super.supplierId,
    required super.supplierName,
    required super.purchasePrice,
    required super.sellingPrice,
    required super.currentQuantity,
    required super.minQuantity,
    required super.unit,
    super.notes,
    super.isAvailable,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced,
    super.totalSoldQuantity,
    this.isDeleted = false,
  });

  factory InventoryProductModel.fromEntity(InventoryProductEntity entity) {
    return InventoryProductModel(
      id: entity.id,
      sku: entity.sku,
      barcode: entity.barcode,
      name: entity.name,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      purchasePrice: entity.purchasePrice,
      sellingPrice: entity.sellingPrice,
      currentQuantity: entity.currentQuantity,
      minQuantity: entity.minQuantity,
      unit: entity.unit,
      notes: entity.notes,
      isAvailable: entity.isAvailable,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: entity.isSynced,
      totalSoldQuantity: entity.totalSoldQuantity,
    );
  }

  factory InventoryProductModel.fromMap(Map<String, dynamic> map) {
    return InventoryProductModel(
      id: map['id'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      barcode: map['barcode'] as String?,
      name: map['name'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      supplierName: map['supplierName'] as String? ?? '',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      currentQuantity: (map['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      minQuantity: (map['minQuantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
      notes: map['notes'] as String?,
      isAvailable: map['isAvailable'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
      isSynced: map['isSynced'] as bool? ?? false,
      totalSoldQuantity: (map['totalSoldQuantity'] as num?)?.toDouble() ?? 0.0,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'currentQuantity': currentQuantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'notes': notes,
      'isAvailable': isAvailable,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSynced': isSynced,
      'totalSoldQuantity': totalSoldQuantity,
    };
  }

  Map<String, dynamic> toRemoteMap() {
    final map = toMap();
    map['isSynced'] = true;
    return map;
  }

  Map<String, dynamic> toRemoteUpdateMap() {
    return {
      'id': id,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'minQuantity': minQuantity,
      'unit': unit,
      'notes': notes,
      'isAvailable': isAvailable,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSynced': true,
    };
  }
}

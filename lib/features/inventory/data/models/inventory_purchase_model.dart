import '../../domain/entities/inventory_purchase_entity.dart';

class InventoryPurchaseItemModel extends InventoryPurchaseItemEntity {
  const InventoryPurchaseItemModel({
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.purchasePrice,
    required super.totalPrice,
  });

  factory InventoryPurchaseItemModel.fromEntity(InventoryPurchaseItemEntity entity) {
    return InventoryPurchaseItemModel(
      productId: entity.productId,
      productName: entity.productName,
      quantity: entity.quantity,
      purchasePrice: entity.purchasePrice,
      totalPrice: entity.totalPrice,
    );
  }

  factory InventoryPurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryPurchaseItemModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'totalPrice': totalPrice,
    };
  }
}

class InventoryPurchaseModel extends InventoryPurchaseEntity {
  final bool isDeleted;

  const InventoryPurchaseModel({
    required super.id,
    required super.supplierId,
    required super.supplierName,
    required super.items,
    required super.totalAmount,
    super.notes,
    required super.createdAt,
    super.isSynced,
    super.paymentMethod = 'cash',
    super.paidAmount = 0.0,
    this.isDeleted = false,
  });

  factory InventoryPurchaseModel.fromEntity(InventoryPurchaseEntity entity) {
    return InventoryPurchaseModel(
      id: entity.id,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      items: entity.items,
      totalAmount: entity.totalAmount,
      notes: entity.notes,
      createdAt: entity.createdAt,
      isSynced: entity.isSynced,
      paymentMethod: entity.paymentMethod,
      paidAmount: entity.paidAmount,
    );
  }

  factory InventoryPurchaseModel.fromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((e) => InventoryPurchaseItemModel.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int);
      } else {
        try {
          parsedDate = DateTime.parse(map['createdAt'].toString());
        } catch (_) {}
      }
    }

    return InventoryPurchaseModel(
      id: map['id'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      supplierName: map['supplierName'] as String? ?? '',
      items: itemsList,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      createdAt: parsedDate,
      isSynced: map['isSynced'] as bool? ?? false,
      paymentMethod: map['paymentMethod'] as String? ?? 'cash',
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'items': items.map((i) => InventoryPurchaseItemModel.fromEntity(i).toMap()).toList(),
      'totalAmount': totalAmount,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isSynced': isSynced,
      'paymentMethod': paymentMethod,
      'paidAmount': paidAmount,
    };
  }

  Map<String, dynamic> toRemoteMap() {
    final map = toMap();
    map['isSynced'] = true;
    return map;
  }
}

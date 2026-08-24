import '../../domain/entities/inventory_supplier_entity.dart';

class InventorySupplierModel extends InventorySupplierEntity {
  final bool isDeleted;

  const InventorySupplierModel({
    required super.id,
    required super.name,
    super.companyName,
    super.taxNumber,
    required super.phone,
    required super.address,
    super.email,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced,
    this.isDeleted = false,
  });

  factory InventorySupplierModel.fromEntity(InventorySupplierEntity entity) {
    return InventorySupplierModel(
      id: entity.id,
      name: entity.name,
      companyName: entity.companyName,
      taxNumber: entity.taxNumber,
      phone: entity.phone,
      address: entity.address,
      email: entity.email,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: entity.isSynced,
    );
  }

  factory InventorySupplierModel.fromMap(Map<String, dynamic> map) {
    return InventorySupplierModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      companyName: map['companyName'] as String?,
      taxNumber: map['taxNumber'] as String?,
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      email: map['email'] as String?,
      notes: map['notes'] as String?,
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
      'companyName': companyName,
      'taxNumber': taxNumber,
      'phone': phone,
      'address': address,
      'email': email,
      'notes': notes,
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

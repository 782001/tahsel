import 'package:equatable/equatable.dart';

class InventoryProductEntity extends Equatable {
  final String id;
  final String sku;
  final String? barcode;
  final String name;
  final String categoryId;
  final String categoryName;
  final String supplierId;
  final String supplierName;
  final double purchasePrice;
  final double sellingPrice;
  final double currentQuantity;
  final double minQuantity;
  final String unit;
  final String? notes;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final double totalSoldQuantity;

  const InventoryProductEntity({
    required this.id,
    required this.sku,
    this.barcode,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.supplierId,
    required this.supplierName,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentQuantity,
    required this.minQuantity,
    required this.unit,
    this.notes,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.totalSoldQuantity = 0.0,
  });

  bool get isLowStock => currentQuantity <= minQuantity;

  InventoryProductEntity copyWith({
    String? id,
    String? sku,
    String? barcode,
    String? name,
    String? categoryId,
    String? categoryName,
    String? supplierId,
    String? supplierName,
    double? purchasePrice,
    double? sellingPrice,
    double? currentQuantity,
    double? minQuantity,
    String? unit,
    String? notes,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    double? totalSoldQuantity,
  }) {
    return InventoryProductEntity(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      totalSoldQuantity: totalSoldQuantity ?? this.totalSoldQuantity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sku,
        barcode,
        name,
        categoryId,
        categoryName,
        supplierId,
        supplierName,
        purchasePrice,
        sellingPrice,
        currentQuantity,
        minQuantity,
        unit,
        notes,
        isAvailable,
        createdAt,
        updatedAt,
        isSynced,
        totalSoldQuantity,
      ];
}

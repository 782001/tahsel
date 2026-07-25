import 'package:equatable/equatable.dart';

class InventoryPurchaseItemEntity extends Equatable {
  final String productId;
  final String productName;
  final double quantity;
  final double purchasePrice;
  final double totalPrice;

  const InventoryPurchaseItemEntity({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.totalPrice,
  });

  double get subtotal => totalPrice;

  @override
  List<Object?> get props => [productId, productName, quantity, purchasePrice, totalPrice];
}

class InventoryPurchaseEntity extends Equatable {
  final String id;
  final String supplierId;
  final String supplierName;
  final List<InventoryPurchaseItemEntity> items;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final bool isSynced;
  final String paymentMethod; // 'cash', 'card', 'debt'
  final double paidAmount;

  const InventoryPurchaseEntity({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    this.isSynced = false,
    this.paymentMethod = 'cash',
    this.paidAmount = 0.0,
  });

  double get remainingDebt =>
      paymentMethod == 'debt' ? (totalAmount - paidAmount).clamp(0.0, double.infinity) : 0.0;

  InventoryPurchaseEntity copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    List<InventoryPurchaseItemEntity>? items,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    bool? isSynced,
    String? paymentMethod,
    double? paidAmount,
  }) {
    return InventoryPurchaseEntity(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        supplierId,
        supplierName,
        items,
        totalAmount,
        notes,
        createdAt,
        isSynced,
        paymentMethod,
        paidAmount,
      ];
}

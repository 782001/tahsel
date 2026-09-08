import 'package:equatable/equatable.dart';
import 'package:tahsel/core/services/profile/business_profile_service.dart';

class InventoryPurchaseItemEntity extends Equatable {
  final String productId;
  final String productName;
  final double quantity;
  final double purchasePrice;
  final double totalPrice;
  final String? unit;

  const InventoryPurchaseItemEntity({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.totalPrice,
    this.unit,
  });

  double get subtotal => totalPrice;

  InventoryPurchaseItemEntity copyWith({
    String? productId,
    String? productName,
    double? quantity,
    double? purchasePrice,
    double? totalPrice,
    String? unit,
  }) {
    return InventoryPurchaseItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      totalPrice: totalPrice ?? this.totalPrice,
      unit: unit ?? this.unit,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    quantity,
    purchasePrice,
    totalPrice,
    unit,
  ];
}

class InventoryPurchaseEntity extends Equatable {
  final String id;
  final String supplierId;
  final String supplierName;
  final List<InventoryPurchaseItemEntity> items;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final String paymentMethod; // 'cash', 'card', 'debt'
  final double paidAmount;
  final double? taxRate;

  const InventoryPurchaseEntity({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.paymentMethod = 'cash',
    this.paidAmount = 0.0,
    this.taxRate,
  });

  /// The effective tax rate for this purchase invoice.
  /// Falls back to the merchant's business profile tax rate if not explicitly set on the purchase.
  double get effectiveTaxRate =>
      taxRate ?? BusinessProfileService.instance.cachedProfile?.taxRate ?? 0.0;

  /// Tax amount extracted backwards from totalAmount (which is tax-inclusive).
  /// Formula: totalAmount * (rate / 100.0)
  double get calculatedTaxAmount {
    final rate = effectiveTaxRate;
    if (rate <= 0) return 0.0;
    return totalAmount * (rate / 100.0);
  }

  /// Total before tax = totalAmount - calculatedTaxAmount
  double get totalBeforeTaxAmount {
    final tax = calculatedTaxAmount;
    final b = totalAmount - tax;
    return b > 0 ? b : 0.0;
  }

  double get remainingDebt =>
      paymentMethod == 'debt' ? (totalAmount - paidAmount).clamp(0.0, double.infinity) : 0.0;

  int get itemsCount => items.length;

  double get totalQuantity =>
      items.fold<double>(0.0, (sum, i) => sum + i.quantity);

  InventoryPurchaseEntity copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    List<InventoryPurchaseItemEntity>? items,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? paymentMethod,
    double? paidAmount,
    double? taxRate,
  }) {
    return InventoryPurchaseEntity(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      taxRate: taxRate ?? this.taxRate,
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
        updatedAt,
        isSynced,
        paymentMethod,
        paidAmount,
        taxRate,
      ];
}

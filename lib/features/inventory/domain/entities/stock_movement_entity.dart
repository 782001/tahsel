import 'package:equatable/equatable.dart';

enum StockMovementType {
  purchase,
  invoiceSale,
  invoiceReturn,
  manualAdjustment,
  purchaseReturn,
}

class StockMovementEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;
  final double quantity; // Positive for addition, negative for reduction
  final double previousQuantity;
  final double newQuantity;
  final String? referenceId; // Purchase ID or Invoice ID
  final String? notes;
  final DateTime createdAt;
  final bool isSynced;

  const StockMovementEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    this.referenceId,
    this.notes,
    required this.createdAt,
    this.isSynced = false,
  });

  StockMovementEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    StockMovementType? type,
    double? quantity,
    double? previousQuantity,
    double? newQuantity,
    String? referenceId,
    String? notes,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return StockMovementEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      referenceId: referenceId ?? this.referenceId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        type,
        quantity,
        previousQuantity,
        newQuantity,
        referenceId,
        notes,
        createdAt,
        isSynced,
      ];
}

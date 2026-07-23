import '../../domain/entities/stock_movement_entity.dart';

class StockMovementModel extends StockMovementEntity {
  const StockMovementModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.type,
    required super.quantity,
    required super.previousQuantity,
    required super.newQuantity,
    super.referenceId,
    super.notes,
    required super.createdAt,
    super.isSynced,
  });

  factory StockMovementModel.fromEntity(StockMovementEntity entity) {
    return StockMovementModel(
      id: entity.id,
      productId: entity.productId,
      productName: entity.productName,
      type: entity.type,
      quantity: entity.quantity,
      previousQuantity: entity.previousQuantity,
      newQuantity: entity.newQuantity,
      referenceId: entity.referenceId,
      notes: entity.notes,
      createdAt: entity.createdAt,
      isSynced: entity.isSynced,
    );
  }

  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    return StockMovementModel(
      id: map['id'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      type: StockMovementType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => StockMovementType.manualAdjustment,
      ),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      previousQuantity: (map['previousQuantity'] as num?)?.toDouble() ?? 0.0,
      newQuantity: (map['newQuantity'] as num?)?.toDouble() ?? 0.0,
      referenceId: map['referenceId'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'quantity': quantity,
      'previousQuantity': previousQuantity,
      'newQuantity': newQuantity,
      'referenceId': referenceId,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toRemoteMap() {
    final map = toMap();
    map['isSynced'] = true;
    return map;
  }
}

import '../entities/stock_movement_entity.dart';

class BestSellerSyncHelper {
  /// Recalculates total sold quantities for legacy products from movement history.
  static Map<String, double> computeTotalSoldFromMovements(
    List<StockMovementEntity> movements,
  ) {
    final Map<String, double> salesMap = {};
    for (final m in movements) {
      if (m.type == StockMovementType.invoiceSale) {
        final current = salesMap[m.productId] ?? 0.0;
        salesMap[m.productId] = current + m.quantity.abs();
      } else if (m.type == StockMovementType.invoiceReturn) {
        final current = salesMap[m.productId] ?? 0.0;
        salesMap[m.productId] = (current - m.quantity.abs()).clamp(0, double.infinity);
      }
    }
    return salesMap;
  }
}

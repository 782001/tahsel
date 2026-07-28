import '../entities/inventory_product_entity.dart';

abstract class BestSellerHelper {
  /// Computes the Set of Top 20 best-selling product IDs in-memory with ZERO extra Firebase costs.
  static Set<String> getTop20BestSellerIds(List<InventoryProductEntity> products) {
    if (products.isEmpty) return <String>{};

    final soldProducts =
        products.where((p) => p.totalSoldQuantity > 0).toList();
    soldProducts.sort(
      (a, b) => b.totalSoldQuantity.compareTo(a.totalSoldQuantity),
    );

    return soldProducts.take(20).map((p) => p.id).toSet();
  }
}

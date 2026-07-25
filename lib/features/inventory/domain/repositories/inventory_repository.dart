import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/inventory_category_entity.dart';
import '../entities/inventory_product_entity.dart';
import '../entities/inventory_purchase_entity.dart';
import '../entities/inventory_supplier_entity.dart';
import '../entities/stock_movement_entity.dart';

abstract class InventoryRepository {
  // Products
  Future<Either<Failure, List<InventoryProductEntity>>> getProducts({
    String? query,
    String? categoryId,
    String? supplierId,
  });
  Future<Either<Failure, InventoryProductEntity?>> getProductById(String id);
  Future<Either<Failure, void>> saveProduct(InventoryProductEntity product);
  Future<Either<Failure, void>> deleteProduct(String id);
  Future<Either<Failure, List<InventoryProductEntity>>> getLowStockProducts();

  // Categories
  Future<Either<Failure, List<InventoryCategoryEntity>>> getCategories();
  Future<Either<Failure, void>> saveCategory(InventoryCategoryEntity category);
  Future<Either<Failure, void>> deleteCategory(String id);

  // Suppliers
  Future<Either<Failure, List<InventorySupplierEntity>>> getSuppliers();
  Future<Either<Failure, void>> saveSupplier(InventorySupplierEntity supplier);
  Future<Either<Failure, void>> deleteSupplier(String id);

  // Purchases
  Future<Either<Failure, List<InventoryPurchaseEntity>>> getPurchases({String? supplierId});
  Future<Either<Failure, void>> createPurchase(InventoryPurchaseEntity purchase);
  Future<Either<Failure, void>> updatePurchase({
    required InventoryPurchaseEntity oldPurchase,
    required InventoryPurchaseEntity newPurchase,
  });
  Future<Either<Failure, void>> deletePurchase(InventoryPurchaseEntity purchase);

  // Stock Movements & Adjustments
  Future<Either<Failure, List<StockMovementEntity>>> getStockMovements({String? productId});
  Future<Either<Failure, void>> createManualAdjustment({
    required String productId,
    required double adjustmentQuantity,
    required String reason,
  });
  Future<Either<Failure, void>> processInvoiceStockChange({
    required String invoiceId,
    required List<Map<String, dynamic>> items,
    required StockMovementType type,
  });

  // Sync
  Future<Either<Failure, void>> syncInventoryData();
}

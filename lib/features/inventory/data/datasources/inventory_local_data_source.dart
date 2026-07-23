import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_category_model.dart';
import '../models/inventory_product_model.dart';
import '../models/inventory_purchase_model.dart';
import '../models/inventory_supplier_model.dart';
import '../models/stock_movement_model.dart';

abstract class InventoryLocalDataSource {
  // Products
  Future<List<InventoryProductModel>> getProducts();
  Future<InventoryProductModel?> getProductById(String id);
  Future<void> saveProduct(InventoryProductModel product);
  Future<void> deleteProduct(String id);
  Future<List<InventoryProductModel>> getUnsyncedProducts();

  // Categories
  Future<List<InventoryCategoryModel>> getCategories();
  Future<void> saveCategory(InventoryCategoryModel category);
  Future<void> deleteCategory(String id);
  Future<List<InventoryCategoryModel>> getUnsyncedCategories();

  // Suppliers
  Future<List<InventorySupplierModel>> getSuppliers();
  Future<void> saveSupplier(InventorySupplierModel supplier);
  Future<void> deleteSupplier(String id);
  Future<List<InventorySupplierModel>> getUnsyncedSuppliers();

  // Purchases
  Future<List<InventoryPurchaseModel>> getPurchases();
  Future<void> savePurchase(InventoryPurchaseModel purchase);
  Future<List<InventoryPurchaseModel>> getUnsyncedPurchases();

  // Stock Movements
  Future<List<StockMovementModel>> getStockMovements();
  Future<void> saveStockMovement(StockMovementModel movement);
  Future<List<StockMovementModel>> getUnsyncedStockMovements();
}

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  static const String productsBoxName = 'inventory_products_box';
  static const String categoriesBoxName = 'inventory_categories_box';
  static const String suppliersBoxName = 'inventory_suppliers_box';
  static const String purchasesBoxName = 'inventory_purchases_box';
  static const String stockMovementsBoxName = 'inventory_stock_movements_box';

  Future<Box<String>> _getBox(String name) async {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox<String>(name);
    }
    return Hive.box<String>(name);
  }

  // --- PRODUCTS ---
  @override
  Future<List<InventoryProductModel>> getProducts() async {
    final box = await _getBox(productsBoxName);
    final List<InventoryProductModel> result = [];
    for (final item in box.values) {
      if (item.isNotEmpty) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        result.add(InventoryProductModel.fromMap(map));
      }
    }
    return result;
  }

  @override
  Future<InventoryProductModel?> getProductById(String id) async {
    final box = await _getBox(productsBoxName);
    final jsonStr = box.get(id);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    return InventoryProductModel.fromMap(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> saveProduct(InventoryProductModel product) async {
    final box = await _getBox(productsBoxName);
    await box.put(product.id, jsonEncode(product.toMap()));
  }

  @override
  Future<void> deleteProduct(String id) async {
    final box = await _getBox(productsBoxName);
    await box.delete(id);
  }

  @override
  Future<List<InventoryProductModel>> getUnsyncedProducts() async {
    final all = await getProducts();
    return all.where((p) => !p.isSynced).toList();
  }

  // --- CATEGORIES ---
  @override
  Future<List<InventoryCategoryModel>> getCategories() async {
    final box = await _getBox(categoriesBoxName);
    final List<InventoryCategoryModel> result = [];
    for (final item in box.values) {
      if (item.isNotEmpty) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        result.add(InventoryCategoryModel.fromMap(map));
      }
    }
    return result;
  }

  @override
  Future<void> saveCategory(InventoryCategoryModel category) async {
    final box = await _getBox(categoriesBoxName);
    await box.put(category.id, jsonEncode(category.toMap()));
  }

  @override
  Future<void> deleteCategory(String id) async {
    final box = await _getBox(categoriesBoxName);
    await box.delete(id);
  }

  @override
  Future<List<InventoryCategoryModel>> getUnsyncedCategories() async {
    final all = await getCategories();
    return all.where((c) => !c.isSynced).toList();
  }

  // --- SUPPLIERS ---
  @override
  Future<List<InventorySupplierModel>> getSuppliers() async {
    final box = await _getBox(suppliersBoxName);
    final List<InventorySupplierModel> result = [];
    for (final item in box.values) {
      if (item.isNotEmpty) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        result.add(InventorySupplierModel.fromMap(map));
      }
    }
    return result;
  }

  @override
  Future<void> saveSupplier(InventorySupplierModel supplier) async {
    final box = await _getBox(suppliersBoxName);
    await box.put(supplier.id, jsonEncode(supplier.toMap()));
  }

  @override
  Future<void> deleteSupplier(String id) async {
    final box = await _getBox(suppliersBoxName);
    await box.delete(id);
  }

  @override
  Future<List<InventorySupplierModel>> getUnsyncedSuppliers() async {
    final all = await getSuppliers();
    return all.where((s) => !s.isSynced).toList();
  }

  // --- PURCHASES ---
  @override
  Future<List<InventoryPurchaseModel>> getPurchases() async {
    final box = await _getBox(purchasesBoxName);
    final List<InventoryPurchaseModel> result = [];
    for (final item in box.values) {
      if (item.isNotEmpty) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        result.add(InventoryPurchaseModel.fromMap(map));
      }
    }
    return result;
  }

  @override
  Future<void> savePurchase(InventoryPurchaseModel purchase) async {
    final box = await _getBox(purchasesBoxName);
    await box.put(purchase.id, jsonEncode(purchase.toMap()));
  }

  @override
  Future<List<InventoryPurchaseModel>> getUnsyncedPurchases() async {
    final all = await getPurchases();
    return all.where((p) => !p.isSynced).toList();
  }

  // --- STOCK MOVEMENTS ---
  @override
  Future<List<StockMovementModel>> getStockMovements() async {
    final box = await _getBox(stockMovementsBoxName);
    final List<StockMovementModel> result = [];
    for (final item in box.values) {
      if (item.isNotEmpty) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        result.add(StockMovementModel.fromMap(map));
      }
    }
    return result;
  }

  @override
  Future<void> saveStockMovement(StockMovementModel movement) async {
    final box = await _getBox(stockMovementsBoxName);
    await box.put(movement.id, jsonEncode(movement.toMap()));
  }

  @override
  Future<List<StockMovementModel>> getUnsyncedStockMovements() async {
    final all = await getStockMovements();
    return all.where((m) => !m.isSynced).toList();
  }
}

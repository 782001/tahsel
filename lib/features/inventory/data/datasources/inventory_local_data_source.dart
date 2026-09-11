import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tahsel/core/utils/app_strings.dart';
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
  Future<void> deletePurchase(String id);
  Future<List<InventoryPurchaseModel>> getUnsyncedPurchases();

  // Stock Movements
  Future<List<StockMovementModel>> getStockMovements();
  Future<void> saveStockMovement(StockMovementModel movement);
  Future<List<StockMovementModel>> getUnsyncedStockMovements();

  // Sync Metadata
  Future<int?> getLastProductsSyncTimestamp();
  Future<void> saveLastProductsSyncTimestamp(int timestamp);
  Future<int?> getLastPurchasesSyncTimestamp();
  Future<void> saveLastPurchasesSyncTimestamp(int timestamp);

  // Session & Multi-tenant management
  Future<void> closeUserBoxes([String? explicitUid]);
  Future<void> clearAllLocalDataForUser(String uid);
}

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  static const String productsBoxName = 'inventory_products_box';
  static const String categoriesBoxName = 'inventory_categories_box';
  static const String suppliersBoxName = 'inventory_suppliers_box';
  static const String purchasesBoxName = 'inventory_purchases_box';
  static const String stockMovementsBoxName = 'inventory_stock_movements_box';
  static const String metaBoxName = 'inventory_meta_box';

  String get _currentUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    if (AppStrings.userToken.isNotEmpty) return AppStrings.userToken;
    return 'default_user';
  }

  Future<Box<String>> _getBox(String baseName) async {
    final uid = _currentUid;
    final userBoxName = '${baseName}_$uid';

    // ── One-Time Auto-Migration from legacy un-suffixed box ───────────────────
    if (!Hive.isBoxOpen(userBoxName) && !await Hive.boxExists(userBoxName)) {
      if (await Hive.boxExists(baseName)) {
        try {
          final legacyBox = await Hive.openBox<String>(baseName);
          if (legacyBox.isNotEmpty) {
            final userBox = await Hive.openBox<String>(userBoxName);
            for (final key in legacyBox.keys) {
              final val = legacyBox.get(key);
              if (val != null) {
                await userBox.put(key, val);
              }
            }
            await legacyBox.clear();
            await legacyBox.close();
            return userBox;
          } else {
            await legacyBox.close();
          }
        } catch (_) {}
      }
    }

    if (!Hive.isBoxOpen(userBoxName)) {
      return await Hive.openBox<String>(userBoxName);
    }
    return Hive.box<String>(userBoxName);
  }

  // --- PRODUCTS ---
  @override
  Future<List<InventoryProductModel>> getProducts() async {
    final box = await _getBox(productsBoxName);
    final List<InventoryProductModel> result = [];
    for (final item in box.values) {
      if (item.isNotEmpty) {
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          result.add(InventoryProductModel.fromMap(map));
        } catch (_) {
          // Resilience: skip corrupted JSON item so the whole catalog does not crash
        }
      }
    }
    return result;
  }

  @override
  Future<InventoryProductModel?> getProductById(String id) async {
    final box = await _getBox(productsBoxName);
    final jsonStr = box.get(id);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return InventoryProductModel.fromMap(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
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
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          result.add(InventoryCategoryModel.fromMap(map));
        } catch (_) {
          // Resilience: skip corrupted JSON item
        }
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
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          result.add(InventorySupplierModel.fromMap(map));
        } catch (_) {
          // Resilience: skip corrupted JSON item
        }
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
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          result.add(InventoryPurchaseModel.fromMap(map));
        } catch (_) {
          // Resilience: skip corrupted JSON item
        }
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
  Future<void> deletePurchase(String id) async {
    final box = await _getBox(purchasesBoxName);
    await box.delete(id);
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
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          result.add(StockMovementModel.fromMap(map));
        } catch (_) {
          // Resilience: skip corrupted JSON item
        }
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

  // --- SYNC METADATA ---
  @override
  Future<int?> getLastProductsSyncTimestamp() async {
    final box = await _getBox(metaBoxName);
    final val = box.get('last_products_sync_timestamp');
    if (val == null || val.isEmpty) return null;
    return int.tryParse(val);
  }

  @override
  Future<void> saveLastProductsSyncTimestamp(int timestamp) async {
    final box = await _getBox(metaBoxName);
    await box.put('last_products_sync_timestamp', timestamp.toString());
  }

  @override
  Future<int?> getLastPurchasesSyncTimestamp() async {
    final box = await _getBox(metaBoxName);
    final val = box.get('last_purchases_sync_timestamp');
    if (val == null || val.isEmpty) return null;
    return int.tryParse(val);
  }

  @override
  Future<void> saveLastPurchasesSyncTimestamp(int timestamp) async {
    final box = await _getBox(metaBoxName);
    await box.put('last_purchases_sync_timestamp', timestamp.toString());
  }

  // --- SESSION & MULTI-TENANT MANAGEMENT ---
  @override
  Future<void> closeUserBoxes([String? explicitUid]) async {
    final uid = (explicitUid != null && explicitUid.isNotEmpty)
        ? explicitUid
        : _currentUid;
    final boxNames = [
      '${productsBoxName}_$uid',
      '${categoriesBoxName}_$uid',
      '${suppliersBoxName}_$uid',
      '${purchasesBoxName}_$uid',
      '${stockMovementsBoxName}_$uid',
      '${metaBoxName}_$uid',
      productsBoxName,
      categoriesBoxName,
      suppliersBoxName,
      purchasesBoxName,
      stockMovementsBoxName,
      metaBoxName,
    ];
    for (final name in boxNames) {
      if (Hive.isBoxOpen(name)) {
        try {
          await Hive.box<String>(name).close();
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> clearAllLocalDataForUser(String uid) async {
    final boxNames = [
      '${productsBoxName}_$uid',
      '${categoriesBoxName}_$uid',
      '${suppliersBoxName}_$uid',
      '${purchasesBoxName}_$uid',
      '${stockMovementsBoxName}_$uid',
      '${metaBoxName}_$uid',
    ];
    for (final name in boxNames) {
      try {
        final box = Hive.isBoxOpen(name)
            ? Hive.box<String>(name)
            : await Hive.openBox<String>(name);
        await box.clear();
      } catch (_) {}
    }
  }
}

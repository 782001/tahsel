import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_category_model.dart';
import '../models/inventory_product_model.dart';
import '../models/inventory_purchase_model.dart';
import '../models/inventory_supplier_model.dart';
import '../models/stock_movement_model.dart';

abstract class InventoryRemoteDataSource {
  Future<void> syncCategories(String uid, List<InventoryCategoryModel> categories);
  Future<List<InventoryCategoryModel>> fetchCategoriesFromRemote(String uid);
  Future<void> deleteCategoryFromRemote(String uid, String categoryId);

  Future<void> syncSuppliers(String uid, List<InventorySupplierModel> suppliers);
  Future<List<InventorySupplierModel>> fetchSuppliersFromRemote(String uid);
  Future<void> deleteSupplierFromRemote(String uid, String supplierId);

  Future<void> syncProducts(String uid, List<InventoryProductModel> products);
  Future<List<InventoryProductModel>> fetchProductsFromRemote(
    String uid, {
    int limit = 15,
  });
  Future<void> updateProductQuantityInRemote(
    String uid,
    String productId,
    double deltaQuantity,
  );
  Future<void> deleteProductFromRemote(String uid, String productId);

  Future<void> syncPurchases(String uid, List<InventoryPurchaseModel> purchases);
  Future<List<InventoryPurchaseModel>> fetchPurchasesFromRemote(
    String uid, {
    int limit = 15,
  });
  Future<void> deletePurchaseFromRemote(String uid, String purchaseId);

  Future<void> syncStockMovements(String uid, List<StockMovementModel> movements);
  Future<List<StockMovementModel>> fetchStockMovementsFromRemote(String uid);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final FirebaseFirestore firestore;

  InventoryRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _getCol(String uid, String subCol) {
    return firestore.collection('users').doc(uid).collection(subCol);
  }

  // Helper for batch chunking (Firestore limit is 500)
  Future<void> _commitChunked<T>(
    CollectionReference col,
    List<T> items,
    String Function(T) getId,
    Map<String, dynamic> Function(T) toMap,
  ) async {
    const chunkSize = 400;
    for (var i = 0; i < items.length; i += chunkSize) {
      final end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
      final chunk = items.sublist(i, end);
      final batch = firestore.batch();
      for (final item in chunk) {
        batch.set(col.doc(getId(item)), toMap(item), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  // --- PRODUCTS ---
  @override
  Future<void> syncProducts(String uid, List<InventoryProductModel> products) async {
    if (products.isEmpty) return;
    final col = _getCol(uid, 'inventory_products');
    await _commitChunked<InventoryProductModel>(
      col,
      products,
      (p) => p.id,
      (p) => p.toRemoteMap(),
    );
  }

  @override
  Future<List<InventoryProductModel>> fetchProductsFromRemote(
    String uid, {
    int limit = 15,
  }) async {
    final snapshot = await _getCol(uid, 'inventory_products')
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final map = doc.data() as Map<String, dynamic>;
      map['id'] = doc.id;
      return InventoryProductModel.fromMap(map);
    }).toList();
  }

  @override
  Future<void> updateProductQuantityInRemote(
    String uid,
    String productId,
    double deltaQuantity,
  ) async {
    final docRef = _getCol(uid, 'inventory_products').doc(productId);
    await docRef.set({
      'currentQuantity': FieldValue.increment(deltaQuantity),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  // --- CATEGORIES ---
  @override
  Future<void> syncCategories(String uid, List<InventoryCategoryModel> categories) async {
    if (categories.isEmpty) return;
    final col = _getCol(uid, 'inventory_categories');
    await _commitChunked<InventoryCategoryModel>(
      col,
      categories,
      (c) => c.id,
      (c) => c.toRemoteMap(),
    );
  }

  @override
  Future<List<InventoryCategoryModel>> fetchCategoriesFromRemote(String uid) async {
    final snapshot = await _getCol(uid, 'inventory_categories').get();
    return snapshot.docs.map((doc) {
      final map = doc.data() as Map<String, dynamic>;
      map['id'] = doc.id;
      return InventoryCategoryModel.fromMap(map);
    }).toList();
  }

  // --- SUPPLIERS ---
  @override
  Future<void> syncSuppliers(String uid, List<InventorySupplierModel> suppliers) async {
    if (suppliers.isEmpty) return;
    final col = _getCol(uid, 'inventory_suppliers');
    await _commitChunked<InventorySupplierModel>(
      col,
      suppliers,
      (s) => s.id,
      (s) => s.toRemoteMap(),
    );
  }

  @override
  Future<List<InventorySupplierModel>> fetchSuppliersFromRemote(String uid) async {
    final snapshot = await _getCol(uid, 'inventory_suppliers').get();
    return snapshot.docs.map((doc) {
      final map = doc.data() as Map<String, dynamic>;
      map['id'] = doc.id;
      return InventorySupplierModel.fromMap(map);
    }).toList();
  }

  // --- PURCHASES ---
  @override
  Future<void> syncPurchases(String uid, List<InventoryPurchaseModel> purchases) async {
    if (purchases.isEmpty) return;
    final col = _getCol(uid, 'inventory_purchases');
    await _commitChunked<InventoryPurchaseModel>(
      col,
      purchases,
      (p) => p.id,
      (p) => p.toRemoteMap(),
    );
  }

  @override
  Future<List<InventoryPurchaseModel>> fetchPurchasesFromRemote(
    String uid, {
    int limit = 15,
  }) async {
    final snapshot = await _getCol(uid, 'inventory_purchases')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final map = doc.data() as Map<String, dynamic>;
      map['id'] = doc.id;
      return InventoryPurchaseModel.fromMap(map);
    }).toList();
  }

  // --- STOCK MOVEMENTS ---
  @override
  Future<void> syncStockMovements(String uid, List<StockMovementModel> movements) async {
    if (movements.isEmpty) return;
    final col = _getCol(uid, 'inventory_stock_movements');
    await _commitChunked<StockMovementModel>(
      col,
      movements,
      (m) => m.id,
      (m) => m.toRemoteMap(),
    );
  }

  @override
  Future<List<StockMovementModel>> fetchStockMovementsFromRemote(String uid) async {
    final snapshot = await _getCol(uid, 'inventory_stock_movements').get();
    return snapshot.docs.map((doc) {
      final map = doc.data() as Map<String, dynamic>;
      map['id'] = doc.id;
      return StockMovementModel.fromMap(map);
    }).toList();
  }

  @override
  Future<void> deleteCategoryFromRemote(String uid, String categoryId) async {
    await _getCol(uid, 'inventory_categories').doc(categoryId).delete();
  }

  @override
  Future<void> deleteSupplierFromRemote(String uid, String supplierId) async {
    await _getCol(uid, 'inventory_suppliers').doc(supplierId).delete();
  }

  @override
  Future<void> deleteProductFromRemote(String uid, String productId) async {
    await _getCol(uid, 'inventory_products').doc(productId).delete();
  }

  @override
  Future<void> deletePurchaseFromRemote(String uid, String purchaseId) async {
    await _getCol(uid, 'inventory_purchases').doc(purchaseId).delete();
  }
}

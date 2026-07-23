import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_category_model.dart';
import '../models/inventory_product_model.dart';
import '../models/inventory_purchase_model.dart';
import '../models/inventory_supplier_model.dart';
import '../models/stock_movement_model.dart';

abstract class InventoryRemoteDataSource {
  Future<void> syncProducts(String uid, List<InventoryProductModel> products);
  Future<List<InventoryProductModel>> fetchProductsFromRemote(String uid);

  Future<void> syncCategories(String uid, List<InventoryCategoryModel> categories);
  Future<List<InventoryCategoryModel>> fetchCategoriesFromRemote(String uid);

  Future<void> syncSuppliers(String uid, List<InventorySupplierModel> suppliers);
  Future<List<InventorySupplierModel>> fetchSuppliersFromRemote(String uid);

  Future<void> syncPurchases(String uid, List<InventoryPurchaseModel> purchases);
  Future<List<InventoryPurchaseModel>> fetchPurchasesFromRemote(String uid);

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

  // --- PRODUCTS ---
  @override
  Future<void> syncProducts(String uid, List<InventoryProductModel> products) async {
    final batch = firestore.batch();
    final col = _getCol(uid, 'inventory_products');
    for (final p in products) {
      batch.set(col.doc(p.id), p.toRemoteMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<List<InventoryProductModel>> fetchProductsFromRemote(String uid) async {
    final snapshot = await _getCol(uid, 'inventory_products').get();
    return snapshot.docs.map((doc) {
      final map = doc.data() as Map<String, dynamic>;
      map['id'] = doc.id;
      return InventoryProductModel.fromMap(map);
    }).toList();
  }

  // --- CATEGORIES ---
  @override
  Future<void> syncCategories(String uid, List<InventoryCategoryModel> categories) async {
    final batch = firestore.batch();
    final col = _getCol(uid, 'inventory_categories');
    for (final c in categories) {
      batch.set(col.doc(c.id), c.toRemoteMap(), SetOptions(merge: true));
    }
    await batch.commit();
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
    final batch = firestore.batch();
    final col = _getCol(uid, 'inventory_suppliers');
    for (final s in suppliers) {
      batch.set(col.doc(s.id), s.toRemoteMap(), SetOptions(merge: true));
    }
    await batch.commit();
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
    final batch = firestore.batch();
    final col = _getCol(uid, 'inventory_purchases');
    for (final p in purchases) {
      batch.set(col.doc(p.id), p.toRemoteMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<List<InventoryPurchaseModel>> fetchPurchasesFromRemote(String uid) async {
    final snapshot = await _getCol(uid, 'inventory_purchases').get();
    return snapshot.docs.map((doc) {
      final map = doc.data() as Map<String, dynamic>;
      map['id'] = doc.id;
      return InventoryPurchaseModel.fromMap(map);
    }).toList();
  }

  // --- STOCK MOVEMENTS ---
  @override
  Future<void> syncStockMovements(String uid, List<StockMovementModel> movements) async {
    final batch = firestore.batch();
    final col = _getCol(uid, 'inventory_stock_movements');
    for (final m in movements) {
      batch.set(col.doc(m.id), m.toRemoteMap(), SetOptions(merge: true));
    }
    await batch.commit();
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
}

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';

import '../../domain/entities/inventory_category_entity.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/entities/inventory_purchase_entity.dart';
import '../../domain/entities/inventory_supplier_entity.dart';
import '../../domain/entities/stock_movement_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_data_source.dart';
import '../datasources/inventory_remote_data_source.dart';
import '../models/inventory_category_model.dart';
import '../models/inventory_product_model.dart';
import '../models/inventory_purchase_model.dart';
import '../models/inventory_supplier_model.dart';
import '../models/stock_movement_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource localDataSource;
  final InventoryRemoteDataSource remoteDataSource;
  final InternetConnectionChecker connectionChecker;

  InventoryRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectionChecker,
  });

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  // --- PRODUCTS ---
  @override
  Future<Either<Failure, List<InventoryProductEntity>>> getProducts({
    String? query,
    String? categoryId,
    String? supplierId,
  }) async {
    try {
      List<InventoryProductModel> products = await localDataSource
          .getProducts();

      // If local is empty and connected, try initial pull from remote
      if (products.isEmpty &&
          await connectionChecker.hasConnection &&
          _currentUid != null) {
        try {
          final remoteProducts = await remoteDataSource.fetchProductsFromRemote(
            _currentUid!,
          );
          for (final p in remoteProducts) {
            await localDataSource.saveProduct(p);
          }
          products = remoteProducts;
        } catch (_) {}
      }

      List<InventoryProductEntity> resultList = products
          .map((p) => p as InventoryProductEntity)
          .toList();

      // Filter by query (Name, SKU, Barcode)
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        resultList = resultList.where((p) {
          final nameMatch = p.name.toLowerCase().contains(q);
          final skuMatch = p.sku.toLowerCase().contains(q);
          final barcodeMatch = p.barcode?.toLowerCase().contains(q) ?? false;
          final catMatch = p.categoryName.toLowerCase().contains(q);
          final supMatch = p.supplierName.toLowerCase().contains(q);
          return nameMatch || skuMatch || barcodeMatch || catMatch || supMatch;
        }).toList();
      }

      // Filter by Category
      if (categoryId != null && categoryId.isNotEmpty) {
        resultList = resultList
            .where((p) => p.categoryId == categoryId)
            .toList();
      }

      // Filter by Supplier
      if (supplierId != null && supplierId.isNotEmpty) {
        resultList = resultList
            .where((p) => p.supplierId == supplierId)
            .toList();
      }

      // Sort by newest updated
      resultList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return Right(resultList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InventoryProductEntity?>> getProductById(
    String id,
  ) async {
    try {
      final product = await localDataSource.getProductById(id);
      return Right(product);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveProduct(
    InventoryProductEntity product,
  ) async {
    try {
      final existing = await localDataSource.getProductById(product.id);
      // Preserve quantity if existing product (quantity must only change via stock movements)
      final finalQuantity = existing != null
          ? existing.currentQuantity
          : product.currentQuantity;

      final model = InventoryProductModel.fromEntity(
        product.copyWith(
          currentQuantity: finalQuantity,
          updatedAt: DateTime.now(),
          isSynced: false,
        ),
      );

      await localDataSource.saveProduct(model);

      // If new product created with initial stock > 0, log an initial stock movement
      if (existing == null && finalQuantity > 0) {
        final initialMovement = StockMovementModel(
          id: 'sm_init_${DateTime.now().microsecondsSinceEpoch}_${product.id}',
          productId: product.id,
          productName: product.name,
          type: StockMovementType.manualAdjustment,
          quantity: finalQuantity,
          previousQuantity: 0.0,
          newQuantity: finalQuantity,
          notes: 'رصيد أولي (Initial Stock)',
          createdAt: DateTime.now(),
          isSynced: false,
        );
        await localDataSource.saveStockMovement(initialMovement);
      }

      _triggerBackgroundSync();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await localDataSource.deleteProduct(id);
      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          await remoteDataSource.deleteProductFromRemote(_currentUid!, id);
        } catch (_) {}
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InventoryProductEntity>>>
  getLowStockProducts() async {
    try {
      final products = await localDataSource.getProducts();
      final lowStock = products
          .where((p) => p.isLowStock)
          .map((p) => p as InventoryProductEntity)
          .toList();
      return Right(lowStock);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // --- CATEGORIES ---
  @override
  Future<Either<Failure, List<InventoryCategoryEntity>>> getCategories() async {
    try {
      List<InventoryCategoryModel> categories = await localDataSource
          .getCategories();
      if (categories.isEmpty &&
          await connectionChecker.hasConnection &&
          _currentUid != null) {
        try {
          final remoteCats = await remoteDataSource.fetchCategoriesFromRemote(
            _currentUid!,
          );
          for (final c in remoteCats) {
            await localDataSource.saveCategory(c);
          }
          categories = remoteCats;
        } catch (_) {}
      }
      List<InventoryCategoryEntity> resultList = categories
          .map((c) => c as InventoryCategoryEntity)
          .toList();
      resultList.sort((a, b) => a.name.compareTo(b.name));
      return Right(resultList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCategory(
    InventoryCategoryEntity category,
  ) async {
    try {
      final model = InventoryCategoryModel.fromEntity(
        category.copyWith(updatedAt: DateTime.now(), isSynced: false),
      );
      await localDataSource.saveCategory(model);

      // Cascade update categoryName in all products belonging to this categoryId
      final allProducts = await localDataSource.getProducts();
      final affectedProducts = allProducts.where((p) => p.categoryId == category.id).toList();
      for (final p in affectedProducts) {
        if (p.categoryName != category.name) {
          final updated = p.copyWith(
            categoryName: category.name,
            updatedAt: DateTime.now(),
            isSynced: false,
          );
          await localDataSource.saveProduct(InventoryProductModel.fromEntity(updated));
        }
      }

      _triggerBackgroundSync();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await localDataSource.deleteCategory(id);
      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          await remoteDataSource.deleteCategoryFromRemote(_currentUid!, id);
        } catch (_) {}
      }

      // Cascade update affected products: reset categoryId and categoryName to empty
      final allProducts = await localDataSource.getProducts();
      final affectedProducts = allProducts.where((p) => p.categoryId == id).toList();
      for (final p in affectedProducts) {
        final updated = p.copyWith(
          categoryId: '',
          categoryName: '',
          updatedAt: DateTime.now(),
          isSynced: false,
        );
        await localDataSource.saveProduct(InventoryProductModel.fromEntity(updated));
      }
      _triggerBackgroundSync();

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // --- SUPPLIERS ---
  @override
  Future<Either<Failure, List<InventorySupplierEntity>>> getSuppliers() async {
    try {
      List<InventorySupplierModel> suppliers = await localDataSource
          .getSuppliers();
      if (suppliers.isEmpty &&
          await connectionChecker.hasConnection &&
          _currentUid != null) {
        try {
          final remoteSuppliers = await remoteDataSource
              .fetchSuppliersFromRemote(_currentUid!);
          for (final s in remoteSuppliers) {
            await localDataSource.saveSupplier(s);
          }
          suppliers = remoteSuppliers;
        } catch (_) {}
      }
      List<InventorySupplierEntity> resultList = suppliers
          .map((s) => s as InventorySupplierEntity)
          .toList();
      resultList.sort((a, b) => a.name.compareTo(b.name));
      return Right(resultList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSupplier(
    InventorySupplierEntity supplier,
  ) async {
    try {
      final model = InventorySupplierModel.fromEntity(
        supplier.copyWith(updatedAt: DateTime.now(), isSynced: false),
      );
      await localDataSource.saveSupplier(model);

      // Cascade update supplierName in all products belonging to this supplierId
      final allProducts = await localDataSource.getProducts();
      final affectedProducts = allProducts.where((p) => p.supplierId == supplier.id).toList();
      for (final p in affectedProducts) {
        if (p.supplierName != supplier.name) {
          final updated = p.copyWith(
            supplierName: supplier.name,
            updatedAt: DateTime.now(),
            isSynced: false,
          );
          await localDataSource.saveProduct(InventoryProductModel.fromEntity(updated));
        }
      }

      // Cascade update supplierName in all purchase invoices belonging to this supplierId
      final allPurchases = await localDataSource.getPurchases();
      final affectedPurchases = allPurchases.where((pur) => pur.supplierId == supplier.id).toList();
      for (final pur in affectedPurchases) {
        if (pur.supplierName != supplier.name) {
          final updated = pur.copyWith(
            supplierName: supplier.name,
            isSynced: false,
          );
          await localDataSource.savePurchase(InventoryPurchaseModel.fromEntity(updated));
        }
      }

      _triggerBackgroundSync();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSupplier(String id) async {
    try {
      await localDataSource.deleteSupplier(id);
      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          await remoteDataSource.deleteSupplierFromRemote(_currentUid!, id);
        } catch (_) {}
      }

      // Cascade update affected products: reset supplierId and supplierName to empty
      final allProducts = await localDataSource.getProducts();
      final affectedProducts = allProducts.where((p) => p.supplierId == id).toList();
      for (final p in affectedProducts) {
        final updated = p.copyWith(
          supplierId: '',
          supplierName: '',
          updatedAt: DateTime.now(),
          isSynced: false,
        );
        await localDataSource.saveProduct(InventoryProductModel.fromEntity(updated));
      }
      _triggerBackgroundSync();

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // --- PURCHASES ---
  @override
  Future<Either<Failure, List<InventoryPurchaseEntity>>> getPurchases({
    String? supplierId,
  }) async {
    try {
      List<InventoryPurchaseModel> purchases = await localDataSource
          .getPurchases();
      if (purchases.isEmpty &&
          await connectionChecker.hasConnection &&
          _currentUid != null) {
        try {
          final remotePurchases = await remoteDataSource
              .fetchPurchasesFromRemote(_currentUid!);
          for (final p in remotePurchases) {
            await localDataSource.savePurchase(p);
          }
          purchases = remotePurchases;
        } catch (_) {}
      }

      List<InventoryPurchaseEntity> resultList = purchases
          .map((p) => p as InventoryPurchaseEntity)
          .toList();

      if (supplierId != null && supplierId.isNotEmpty) {
        resultList = resultList
            .where((p) => p.supplierId == supplierId)
            .toList();
      }

      resultList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(resultList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createPurchase(
    InventoryPurchaseEntity purchase,
  ) async {
    try {
      // 1. Save Purchase Record
      final purchaseModel = InventoryPurchaseModel.fromEntity(
        purchase.copyWith(isSynced: false),
      );
      await localDataSource.savePurchase(purchaseModel);

      // 2. For each item: Increase product quantity & record StockMovement
      for (var i = 0; i < purchase.items.length; i++) {
        final item = purchase.items[i];
        final product = await localDataSource.getProductById(item.productId);
        if (product != null) {
          final prevQty = product.currentQuantity;
          final newQty = prevQty + item.quantity;

          // Update Product
          final updatedProduct = InventoryProductModel.fromEntity(
            product.copyWith(
              currentQuantity: newQty,
              purchasePrice: item.purchasePrice,
              updatedAt: DateTime.now(),
              isSynced: false,
            ),
          );
          await localDataSource.saveProduct(updatedProduct);

          // Create Movement with collision-free ID
          final movement = StockMovementModel(
            id: 'sm_pur_${DateTime.now().microsecondsSinceEpoch}_${i}_${item.productId}',
            productId: item.productId,
            productName: item.productName,
            type: StockMovementType.purchase,
            quantity: item.quantity,
            previousQuantity: prevQty,
            newQuantity: newQty,
            referenceId: purchase.id,
            notes: 'Purchase from ${purchase.supplierName}',
            createdAt: DateTime.now(),
            isSynced: false,
          );
          await localDataSource.saveStockMovement(movement);
        }
      }

      _triggerBackgroundSync();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // --- STOCK MOVEMENTS ---
  @override
  Future<Either<Failure, List<StockMovementEntity>>> getStockMovements({
    String? productId,
  }) async {
    try {
      List<StockMovementModel> movements = await localDataSource
          .getStockMovements();
      if (movements.isEmpty &&
          await connectionChecker.hasConnection &&
          _currentUid != null) {
        try {
          final remoteMovements = await remoteDataSource
              .fetchStockMovementsFromRemote(_currentUid!);
          for (final m in remoteMovements) {
            await localDataSource.saveStockMovement(m);
          }
          movements = remoteMovements;
        } catch (_) {}
      }

      List<StockMovementEntity> resultList = movements
          .map((m) => m as StockMovementEntity)
          .toList();

      if (productId != null && productId.isNotEmpty) {
        resultList = resultList.where((m) => m.productId == productId).toList();
      }

      resultList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(resultList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createManualAdjustment({
    required String productId,
    required double adjustmentQuantity,
    required String reason,
  }) async {
    try {
      final product = await localDataSource.getProductById(productId);
      if (product == null) return const Left(CacheFailure('Product not found'));

      final prevQty = product.currentQuantity;
      final newQty = prevQty + adjustmentQuantity;

      // Update product quantity
      final updatedProduct = InventoryProductModel.fromEntity(
        product.copyWith(
          currentQuantity: newQty,
          updatedAt: DateTime.now(),
          isSynced: false,
        ),
      );
      await localDataSource.saveProduct(updatedProduct);

      // Save Stock Movement with collision-free ID
      final movement = StockMovementModel(
        id: 'sm_adj_${DateTime.now().microsecondsSinceEpoch}_$productId',
        productId: product.id,
        productName: product.name,
        type: StockMovementType.manualAdjustment,
        quantity: adjustmentQuantity,
        previousQuantity: prevQty,
        newQuantity: newQty,
        notes: reason,
        createdAt: DateTime.now(),
        isSynced: false,
      );
      await localDataSource.saveStockMovement(movement);

      _triggerBackgroundSync();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> processInvoiceStockChange({
    required String invoiceId,
    required List<Map<String, dynamic>> items,
    required StockMovementType type,
  }) async {
    try {
      final allProducts = await localDataSource.getProducts();

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final itemId = item['id'] as String? ?? '';
        final itemName =
            (item['description'] as String? ?? item['name'] as String? ?? '')
                .trim()
                .toLowerCase();
        final qtyChange = (item['quantity'] as num?)?.toDouble() ?? 0.0;
        if (qtyChange == 0) continue;

        // Find matching inventory product by ID, SKU, Barcode, or exact Name match
        InventoryProductModel? matchingProduct;
        for (final p in allProducts) {
          if ((itemId.isNotEmpty && p.id == itemId) ||
              (p.sku.isNotEmpty && p.sku.toLowerCase() == itemName) ||
              (p.barcode != null &&
                  p.barcode!.isNotEmpty &&
                  p.barcode!.toLowerCase() == itemName) ||
              (p.name.isNotEmpty && p.name.trim().toLowerCase() == itemName)) {
            matchingProduct = p;
            break;
          }
        }

        if (matchingProduct != null) {
          final prevQty = matchingProduct.currentQuantity;
          // Sales decrease stock (-qtyChange), Returns increase stock (+qtyChange)
          final double delta = (type == StockMovementType.invoiceSale)
              ? -qtyChange.abs()
              : qtyChange.abs();
          final newQty = prevQty + delta;

          // Update Product
          final updated = InventoryProductModel.fromEntity(
            matchingProduct.copyWith(
              currentQuantity: newQty,
              updatedAt: DateTime.now(),
              isSynced: false,
            ),
          );
          await localDataSource.saveProduct(updated);

          // Record Movement with collision-free ID
          final movement = StockMovementModel(
            id: 'sm_inv_${DateTime.now().microsecondsSinceEpoch}_${i}_${matchingProduct.id}',
            productId: matchingProduct.id,
            productName: matchingProduct.name,
            type: type,
            quantity: delta,
            previousQuantity: prevQty,
            newQuantity: newQty,
            referenceId: invoiceId,
            notes: type == StockMovementType.invoiceSale
                ? 'Invoice Sale #$invoiceId'
                : 'Invoice Return #$invoiceId',
            createdAt: DateTime.now(),
            isSynced: false,
          );
          await localDataSource.saveStockMovement(movement);
        }
      }

      _triggerBackgroundSync();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // --- SYNC ---
  @override
  Future<Either<Failure, void>> syncInventoryData() async {
    try {
      if (!await connectionChecker.hasConnection || _currentUid == null) {
        return const Right(null);
      }
      final uid = _currentUid!;

      // Sync Unsynced Products
      final unsyncedProducts = await localDataSource.getUnsyncedProducts();
      if (unsyncedProducts.isNotEmpty) {
        await remoteDataSource.syncProducts(uid, unsyncedProducts);
        for (final p in unsyncedProducts) {
          await localDataSource.saveProduct(
            InventoryProductModel.fromEntity(p.copyWith(isSynced: true)),
          );
        }
      }

      // Sync Unsynced Categories
      final unsyncedCategories = await localDataSource.getUnsyncedCategories();
      if (unsyncedCategories.isNotEmpty) {
        await remoteDataSource.syncCategories(uid, unsyncedCategories);
        for (final c in unsyncedCategories) {
          await localDataSource.saveCategory(
            InventoryCategoryModel.fromEntity(c.copyWith(isSynced: true)),
          );
        }
      }

      // Sync Unsynced Suppliers
      final unsyncedSuppliers = await localDataSource.getUnsyncedSuppliers();
      if (unsyncedSuppliers.isNotEmpty) {
        await remoteDataSource.syncSuppliers(uid, unsyncedSuppliers);
        for (final s in unsyncedSuppliers) {
          await localDataSource.saveSupplier(
            InventorySupplierModel.fromEntity(s.copyWith(isSynced: true)),
          );
        }
      }

      // Sync Unsynced Purchases
      final unsyncedPurchases = await localDataSource.getUnsyncedPurchases();
      if (unsyncedPurchases.isNotEmpty) {
        await remoteDataSource.syncPurchases(uid, unsyncedPurchases);
        for (final p in unsyncedPurchases) {
          await localDataSource.savePurchase(
            InventoryPurchaseModel.fromEntity(p.copyWith(isSynced: true)),
          );
        }
      }

      // Sync Unsynced Stock Movements
      final unsyncedMovements = await localDataSource
          .getUnsyncedStockMovements();
      if (unsyncedMovements.isNotEmpty) {
        await remoteDataSource.syncStockMovements(uid, unsyncedMovements);
        for (final m in unsyncedMovements) {
          await localDataSource.saveStockMovement(
            StockMovementModel.fromEntity(m.copyWith(isSynced: true)),
          );
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  void _triggerBackgroundSync() {
    connectionChecker.hasConnection.then((hasConn) {
      if (hasConn) {
        syncInventoryData();
      }
    });
  }
}

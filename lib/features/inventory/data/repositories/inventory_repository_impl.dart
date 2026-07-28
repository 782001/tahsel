import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:get_it/get_it.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/features/expenses/domain/entities/expense_entity.dart';
import 'package:tahsel/features/expenses/domain/repositories/expense_repository.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

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
  final ExpenseRepository? expenseRepository;
  final MyDebtRepository? myDebtRepository;

  InventoryRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectionChecker,
    this.expenseRepository,
    this.myDebtRepository,
  });

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  // --- PRODUCTS ---
  @override
  Future<Either<Failure, List<InventoryProductEntity>>> getProducts({
    String? query,
    String? categoryId,
    String? supplierId,
    int limit = 15,
  }) async {
    try {
      List<InventoryProductModel> products = await localDataSource
          .getProducts();

      // Reconcile with remote server if connected so all devices see updates
      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          final remoteProducts = await remoteDataSource.fetchProductsFromRemote(
            _currentUid!,
            limit: limit,
          );
          for (final p in remoteProducts) {
            final existing = await localDataSource.getProductById(p.id);
            if (existing == null || existing.isSynced) {
              await localDataSource.saveProduct(p);
            }
          }
          products = await localDataSource.getProducts();
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
    int limit = 15,
  }) async {
    try {
      List<InventoryPurchaseModel> purchases =
          await localDataSource.getPurchases();
      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          final remotePurchases = await remoteDataSource
              .fetchPurchasesFromRemote(_currentUid!, limit: limit);
          for (final p in remotePurchases) {
            final matches = purchases.where((x) => x.id == p.id);
            final localItem = matches.isNotEmpty ? matches.first : null;
            // Only update local from remote if local item does not exist or local item is synced
            if (localItem == null || localItem.isSynced) {
              await localDataSource.savePurchase(p);
            }
          }
          purchases = await localDataSource.getPurchases();
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

  Future<void> _syncPurchaseToExpenses(InventoryPurchaseEntity purchase) async {
    try {
      final repo = expenseRepository ??
          (GetIt.I.isRegistered<ExpenseRepository>()
              ? GetIt.I<ExpenseRepository>()
              : null);
      if (repo == null) return;

      final uid = _currentUid ?? AppStrings.userToken;
      if (uid.isEmpty) return;

      final cleanId = purchase.id.replaceAll('pur_', '');
      final expenseId = 'exp_pur_$cleanId';
      final monthKey = DateFormatter.formatNumericMonth(purchase.createdAt);
      final categoryName = AppStrings.inventoryPurchases.tr();
      final description =
          '${AppStrings.purchaseInvoiceNum.tr()} #$cleanId - ${purchase.supplierName}';

      final expense = ExpenseEntity(
        id: expenseId,
        uid: uid,
        amount: purchase.totalAmount,
        category: categoryName.isNotEmpty ? categoryName : 'مشتريات مخزون',
        description: description,
        createdAt: purchase.createdAt,
        monthKey: monthKey,
      );

      await repo.addExpense(expense);
    } catch (_) {}
  }

  Future<void> _removePurchaseFromExpenses(
    InventoryPurchaseEntity purchase,
  ) async {
    try {
      final repo = expenseRepository ??
          (GetIt.I.isRegistered<ExpenseRepository>()
              ? GetIt.I<ExpenseRepository>()
              : null);
      if (repo == null) return;

      final uid = _currentUid ?? AppStrings.userToken;
      if (uid.isEmpty) return;

      final cleanId = purchase.id.replaceAll('pur_', '');
      final expenseId = 'exp_pur_$cleanId';
      await repo.deleteExpense(uid, expenseId);
    } catch (_) {}
  }

  Future<void> _updatePurchaseInExpenses({
    required InventoryPurchaseEntity oldPurchase,
    required InventoryPurchaseEntity newPurchase,
  }) async {
    try {
      await _removePurchaseFromExpenses(oldPurchase);
      await _syncPurchaseToExpenses(newPurchase);
    } catch (_) {}
  }

  Future<void> _syncPurchaseToMyDebts(InventoryPurchaseEntity purchase) async {
    try {
      final repo = myDebtRepository ??
          (GetIt.I.isRegistered<MyDebtRepository>()
              ? GetIt.I<MyDebtRepository>()
              : null);
      if (repo == null) return;

      final uid = _currentUid ?? AppStrings.userToken;
      if (uid.isEmpty) return;

      final cleanId = purchase.id.replaceAll('pur_', '');
      final debtId = 'debt_pur_$cleanId';

      if (purchase.paymentMethod == 'debt') {
        final remainingAmount = purchase.totalAmount - purchase.paidAmount;

        final debtItem = MyDebtItemEntity(
          id: debtId,
          uid: uid,
          operationId: purchase.id,
          personName: purchase.supplierName,
          totalAmount: purchase.totalAmount,
          paidAmount: purchase.paidAmount,
          remainingAmount: remainingAmount,
          details: '${AppStrings.purchaseInvoiceNum.tr()} #$cleanId',
          operationType: AppStrings.inventoryPurchases.tr().isNotEmpty
              ? AppStrings.inventoryPurchases.tr()
              : 'مشتريات مخزون',
          timestamp: purchase.createdAt,
          lastUpdatedAt: DateTime.now(),
          isPaid: remainingAmount <= 0,
        );

        await repo.addMyDebtItem(debtItem);
      } else {
        await repo.deleteMyDebtItem(uid, debtId);
      }
    } catch (_) {}
  }

  Future<void> _removePurchaseFromMyDebts(
    InventoryPurchaseEntity purchase,
  ) async {
    try {
      final repo = myDebtRepository ??
          (GetIt.I.isRegistered<MyDebtRepository>()
              ? GetIt.I<MyDebtRepository>()
              : null);
      if (repo == null) return;

      final uid = _currentUid ?? AppStrings.userToken;
      if (uid.isEmpty) return;

      final cleanId = purchase.id.replaceAll('pur_', '');
      final debtId = 'debt_pur_$cleanId';
      await repo.deleteMyDebtItem(uid, debtId);
    } catch (_) {}
  }

  Future<void> _updatePurchaseInMyDebts({
    required InventoryPurchaseEntity oldPurchase,
    required InventoryPurchaseEntity newPurchase,
  }) async {
    try {
      if (newPurchase.paymentMethod == 'debt') {
        await _syncPurchaseToMyDebts(newPurchase);
      } else {
        await _removePurchaseFromMyDebts(oldPurchase);
      }
    } catch (_) {}
  }

  @override
  Future<Either<Failure, void>> createPurchase(
    InventoryPurchaseEntity purchase,
  ) async {
    try {
      // 1. Save Purchase Record locally
      final purchaseModel = InventoryPurchaseModel.fromEntity(
        purchase.copyWith(isSynced: false),
      );
      await localDataSource.savePurchase(purchaseModel);

      // Immediate remote sync if connected
      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          final syncedModel = InventoryPurchaseModel.fromEntity(
            purchase.copyWith(isSynced: true),
          );
          await remoteDataSource.syncPurchases(_currentUid!, [syncedModel]);
          await localDataSource.savePurchase(syncedModel);
        } catch (_) {}
      }

      // 2. Sync to Expenses & My Debts
      await _syncPurchaseToExpenses(purchase);
      await _syncPurchaseToMyDebts(purchase);

      // 3. For each item: Increase product quantity & record StockMovement
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

  @override
  Future<Either<Failure, void>> deletePurchase(
    InventoryPurchaseEntity purchase,
  ) async {
    try {
      // 1. Delete purchase record locally
      await localDataSource.deletePurchase(purchase.id);

      // 2. Remove expense & My Debt records
      await _removePurchaseFromExpenses(purchase);
      await _removePurchaseFromMyDebts(purchase);

      // Remote delete if connected
      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          await remoteDataSource.deletePurchaseFromRemote(
            _currentUid!,
            purchase.id,
          );
        } catch (_) {}
      }

      // 3. Revert stock quantity for each item in the purchase
      for (final item in purchase.items) {
        final product = await localDataSource.getProductById(item.productId);
        if (product != null) {
          final prevQty = product.currentQuantity;
          final newQty = (prevQty - item.quantity).clamp(0.0, double.infinity);

          final updatedProduct = InventoryProductModel.fromEntity(
            product.copyWith(
              currentQuantity: newQty,
              updatedAt: DateTime.now(),
              isSynced: false,
            ),
          );
          await localDataSource.saveProduct(updatedProduct);

          // Save cancellation stock movement
          final movement = StockMovementModel(
            id: 'sm_cancel_pur_${DateTime.now().microsecondsSinceEpoch}_${item.productId}',
            productId: item.productId,
            productName: item.productName,
            type: StockMovementType.manualAdjustment,
            quantity: item.quantity,
            previousQuantity: prevQty,
            newQuantity: newQty,
            notes: 'إلغاء فاتورة شراء رقم #${purchase.id.replaceAll("pur_", "")}',
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

  @override
  Future<Either<Failure, void>> updatePurchase({
    required InventoryPurchaseEntity oldPurchase,
    required InventoryPurchaseEntity newPurchase,
  }) async {
    try {
      // 1. Save updated purchase model locally
      final model = InventoryPurchaseModel.fromEntity(
        newPurchase.copyWith(isSynced: false),
      );
      await localDataSource.savePurchase(model);

      // Immediate remote sync if connected
      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          final syncedModel = InventoryPurchaseModel.fromEntity(
            newPurchase.copyWith(isSynced: true),
          );
          await remoteDataSource.syncPurchases(_currentUid!, [syncedModel]);
          await localDataSource.savePurchase(syncedModel);
        } catch (_) {}
      }

      // 2. Update expense & My Debt records
      await _updatePurchaseInExpenses(
        oldPurchase: oldPurchase,
        newPurchase: newPurchase,
      );
      await _updatePurchaseInMyDebts(
        oldPurchase: oldPurchase,
        newPurchase: newPurchase,
      );

      // 3. Revert quantities of old items, add quantities of new items
      final Map<String, double> deltaQtyMap = {};
      final Map<String, double> latestPricesMap = {};

      for (final oldItem in oldPurchase.items) {
        deltaQtyMap[oldItem.productId] =
            (deltaQtyMap[oldItem.productId] ?? 0.0) - oldItem.quantity;
      }

      for (final newItem in newPurchase.items) {
        deltaQtyMap[newItem.productId] =
            (deltaQtyMap[newItem.productId] ?? 0.0) + newItem.quantity;
        latestPricesMap[newItem.productId] = newItem.purchasePrice;
      }

      for (final entry in deltaQtyMap.entries) {
        final productId = entry.key;
        final deltaQty = entry.value;

        final product = await localDataSource.getProductById(productId);
        if (product != null) {
          final prevQty = product.currentQuantity;
          final newQty = (prevQty + deltaQty).clamp(0.0, double.infinity);
          final newPrice = latestPricesMap[productId] ?? product.purchasePrice;

          final updatedProduct = InventoryProductModel.fromEntity(
            product.copyWith(
              currentQuantity: newQty,
              purchasePrice: newPrice,
              updatedAt: DateTime.now(),
              isSynced: false,
            ),
          );
          await localDataSource.saveProduct(updatedProduct);

          if (deltaQty != 0) {
            final movement = StockMovementModel(
              id: 'sm_edit_pur_${DateTime.now().microsecondsSinceEpoch}_$productId',
              productId: productId,
              productName: product.name,
              type: StockMovementType.manualAdjustment,
              quantity: deltaQty.abs(),
              previousQuantity: prevQty,
              newQuantity: newQty,
              notes: 'تعديل فاتورة شراء رقم #${newPurchase.id.replaceAll("pur_", "")}',
              createdAt: DateTime.now(),
              isSynced: false,
            );
            await localDataSource.saveStockMovement(movement);
          }
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
    int? limit,
  }) async {
    try {
      List<StockMovementModel> movements = await localDataSource
          .getStockMovements();
      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          final remoteMovements = await remoteDataSource
              .fetchStockMovementsFromRemote(_currentUid!, limit: limit);
          for (final m in remoteMovements) {
            final matches = movements.where((x) => x.id == m.id);
            final localItem = matches.isNotEmpty ? matches.first : null;
            if (localItem == null || localItem.isSynced) {
              await localDataSource.saveStockMovement(m);
            }
          }
          movements = await localDataSource.getStockMovements();
        } catch (_) {}
      }

      List<StockMovementEntity> resultList = movements
          .map((m) => m as StockMovementEntity)
          .toList();

      if (productId != null && productId.isNotEmpty) {
        resultList = resultList.where((m) => m.productId == productId).toList();
      }

      resultList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (limit != null && resultList.length > limit) {
        resultList = resultList.take(limit).toList();
      }
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

      if (await connectionChecker.hasConnection && _currentUid != null) {
        try {
          await remoteDataSource.updateProductQuantityInRemote(
            _currentUid!,
            product.id,
            adjustmentQuantity,
          );
        } catch (_) {}
      }

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
          final double delta = (type == StockMovementType.invoiceSale)
              ? -qtyChange.abs()
              : qtyChange.abs();
          final double newQty = prevQty + delta;

          final double deltaSold = (type == StockMovementType.invoiceSale)
              ? qtyChange.abs()
              : -qtyChange.abs();
          final newSoldQty =
              (matchingProduct.totalSoldQuantity + deltaSold)
                  .clamp(0.0, double.infinity);

          // Update Product
          final updated = InventoryProductModel.fromEntity(
            matchingProduct.copyWith(
              currentQuantity: newQty,
              totalSoldQuantity: newSoldQty,
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

          if (await connectionChecker.hasConnection && _currentUid != null) {
            try {
              await remoteDataSource.updateProductQuantityInRemote(
                _currentUid!,
                matchingProduct.id,
                delta,
              );
            } catch (_) {}
          }
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

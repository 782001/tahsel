import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../data/datasources/inventory_local_data_source.dart';
import '../data/datasources/inventory_remote_data_source.dart';
import '../data/repositories/inventory_repository_impl.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/usecases/inventory_category_usecases.dart';
import '../domain/usecases/inventory_product_usecases.dart';
import '../domain/usecases/inventory_purchase_usecases.dart';
import '../domain/usecases/inventory_supplier_usecases.dart';
import '../domain/usecases/stock_movement_usecases.dart';
import '../presentation/cubits/inventory_categories_cubit.dart';
import '../presentation/cubits/inventory_dashboard_cubit.dart';
import '../presentation/cubits/inventory_products_cubit.dart';
import '../presentation/cubits/inventory_purchases_cubit.dart';
import '../presentation/cubits/inventory_stock_movements_cubit.dart';
import '../presentation/cubits/inventory_suppliers_cubit.dart';

class InventoryInjection {
  static void init(GetIt sl) {
    if (!sl.isRegistered<InternetConnectionChecker>()) {
      sl.registerLazySingleton<InternetConnectionChecker>(
        () => InternetConnectionChecker(),
      );
    }

    // Data sources
    if (!sl.isRegistered<InventoryLocalDataSource>()) {
      sl.registerLazySingleton<InventoryLocalDataSource>(
        () => InventoryLocalDataSourceImpl(),
      );
    }
    if (!sl.isRegistered<InventoryRemoteDataSource>()) {
      sl.registerLazySingleton<InventoryRemoteDataSource>(
        () => InventoryRemoteDataSourceImpl(),
      );
    }

    // Repository
    if (!sl.isRegistered<InventoryRepository>()) {
      sl.registerLazySingleton<InventoryRepository>(
        () => InventoryRepositoryImpl(
          localDataSource: sl<InventoryLocalDataSource>(),
          remoteDataSource: sl<InventoryRemoteDataSource>(),
          connectionChecker: sl<InternetConnectionChecker>(),
        ),
      );
    }

    // Use cases - Products
    sl.registerLazySingleton(
      () => GetInventoryProductsUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => SaveInventoryProductUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => DeleteInventoryProductUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => GetLowStockProductsUseCase(sl<InventoryRepository>()),
    );

    // Use cases - Categories
    sl.registerLazySingleton(
      () => GetInventoryCategoriesUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => SaveInventoryCategoryUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => DeleteInventoryCategoryUseCase(sl<InventoryRepository>()),
    );

    // Use cases - Suppliers
    sl.registerLazySingleton(
      () => GetInventorySuppliersUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => SaveInventorySupplierUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => DeleteInventorySupplierUseCase(sl<InventoryRepository>()),
    );

    // Use cases - Purchases
    sl.registerLazySingleton(
      () => GetInventoryPurchasesUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => CreateInventoryPurchaseUseCase(sl<InventoryRepository>()),
    );

    // Use cases - Movements & Sync
    sl.registerLazySingleton(
      () => GetStockMovementsUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => CreateManualStockAdjustmentUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => ProcessInvoiceStockUseCase(sl<InventoryRepository>()),
    );
    sl.registerLazySingleton(
      () => SyncInventoryDataUseCase(sl<InventoryRepository>()),
    );

    // Cubits
    sl.registerFactory(
      () => InventoryDashboardCubit(
        getProductsUseCase: sl<GetInventoryProductsUseCase>(),
        getLowStockProductsUseCase: sl<GetLowStockProductsUseCase>(),
      ),
    );

    sl.registerFactory(
      () => InventoryProductsCubit(
        getProductsUseCase: sl<GetInventoryProductsUseCase>(),
        saveProductUseCase: sl<SaveInventoryProductUseCase>(),
        deleteProductUseCase: sl<DeleteInventoryProductUseCase>(),
      ),
    );

    sl.registerFactory(
      () => InventoryCategoriesCubit(
        getCategoriesUseCase: sl<GetInventoryCategoriesUseCase>(),
        saveCategoryUseCase: sl<SaveInventoryCategoryUseCase>(),
        deleteCategoryUseCase: sl<DeleteInventoryCategoryUseCase>(),
      ),
    );

    sl.registerFactory(
      () => InventorySuppliersCubit(
        getSuppliersUseCase: sl<GetInventorySuppliersUseCase>(),
        saveSupplierUseCase: sl<SaveInventorySupplierUseCase>(),
        deleteSupplierUseCase: sl<DeleteInventorySupplierUseCase>(),
        getPurchasesUseCase: sl<GetInventoryPurchasesUseCase>(),
        getProductsUseCase: sl<GetInventoryProductsUseCase>(),
      ),
    );

    sl.registerFactory(
      () => InventoryPurchasesCubit(
        getPurchasesUseCase: sl<GetInventoryPurchasesUseCase>(),
        createPurchaseUseCase: sl<CreateInventoryPurchaseUseCase>(),
      ),
    );

    sl.registerFactory(
      () => InventoryStockMovementsCubit(
        getStockMovementsUseCase: sl<GetStockMovementsUseCase>(),
        createManualAdjustmentUseCase:
            sl<CreateManualStockAdjustmentUseCase>(),
      ),
    );
  }
}

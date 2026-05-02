import 'package:tahsel/core/services/injection_container.dart';
import '../data/datasources/product_remote_data_source.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/usecases/get_products_usecase.dart';
import '../domain/usecases/save_product_usecase.dart';
import '../presentation/cubit/product_cubit.dart';

void initProductInjection() {
  // Cubit
  sl.registerFactory(
    () => ProductCubit(getProductsUseCase: sl(), saveProductUseCase: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => SaveProductUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(firestore: sl()),
  );
}

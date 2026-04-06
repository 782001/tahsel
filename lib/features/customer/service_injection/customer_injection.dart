import 'package:tahsel/core/services/injection_container.dart';
import '../data/datasources/customer_remote_data_source.dart';
import '../data/repositories/customer_repository_impl.dart';
import '../domain/repositories/customer_repository.dart';
import '../domain/usecases/get_customers_usecase.dart';
import '../domain/usecases/save_customer_usecase.dart';
import '../presentation/cubit/customer_cubit.dart';


void initCustomerInjection() {
  // Cubit
  sl.registerFactory(() => CustomerCubit(
        getCustomersUseCase: sl(),
        saveCustomerUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));
  sl.registerLazySingleton(() => SaveCustomerUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(firestore: sl()),
  );
}

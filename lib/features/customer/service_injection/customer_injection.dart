import 'package:tahsel/core/services/injection_container.dart';
import '../data/datasources/customer_remote_data_source.dart';
import '../data/repositories/customer_repository_impl.dart';
import '../domain/repositories/customer_repository.dart';
import '../domain/usecases/get_customer_operations_usecase.dart';
import '../domain/usecases/get_customers_usecase.dart';
import '../domain/usecases/save_customer_usecase.dart';
import '../domain/usecases/update_customer_phone_usecase.dart';
import '../domain/usecases/update_customer_preference_usecase.dart';
import '../presentation/cubit/customer_cubit.dart';
import '../presentation/cubit/customer_reports/customer_reports_cubit.dart';
import '../presentation/cubit/customer_details/customer_details_cubit.dart';

void initCustomerInjection() {
  // Cubit
  sl.registerFactory(
    () => CustomerCubit(
      getCustomersUseCase: sl(),
      saveCustomerUseCase: sl(),
      updateCustomerPhoneUseCase: sl(),
      updateCustomerPreferenceUseCase: sl(),
    ),
  );

  sl.registerFactory(() => CustomerReportsCubit(getCustomersUseCase: sl()));

  sl.registerFactory(
    () => CustomerDetailsCubit(getCustomerOperationsUseCase: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));
  sl.registerLazySingleton(() => SaveCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerPhoneUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerPreferenceUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerOperationsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(firestore: sl()),
  );
}

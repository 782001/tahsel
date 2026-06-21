import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/services/injection_container.dart';

import '../data/datasources/employee_remote_data_source.dart';
import '../data/repositories/employee_repository_impl.dart';
import '../domain/repositories/employee_repository.dart';
import '../domain/services/employee_operation_guard.dart';
import '../domain/usecases/advance_usecases.dart';
import '../domain/usecases/employee_usecases.dart';
import '../presentation/cubit/employee_cubit.dart';

class EmployeeInjection {
  static void init() {
    // Cubit
    sl.registerLazySingleton(
      () => EmployeeCubit(
        addEmployeeUseCase: sl(),
        editEmployeeUseCase: sl(),
        getEmployeesUseCase: sl(),
        searchEmployeesUseCase: sl(),
        checkInUseCase: sl(),
        checkOutUseCase: sl(),
        getAttendanceUseCase: sl(),
        paySalaryUseCase: sl(),
        getPayrollUseCase: sl(),
        requestAdvanceUseCase: sl(),
        getAdvancesUseCase: sl(),
        settleAdvancesUseCase: sl(),
        getEmployeeUseCase: sl(),
      ),
    );

    // Service/Guard
    sl.registerLazySingleton(() => const EmployeeOperationGuard());

    // Use cases
    sl.registerLazySingleton(() => AddEmployeeUseCase(repository: sl()));
    sl.registerLazySingleton(() => EditEmployeeUseCase(repository: sl()));
    sl.registerLazySingleton(() => GetEmployeesUseCase(repository: sl()));
    sl.registerLazySingleton(() => SearchEmployeesUseCase(repository: sl()));
    sl.registerLazySingleton(
      () => CheckInUseCase(repository: sl(), guard: sl()),
    );
    sl.registerLazySingleton(
      () => CheckOutUseCase(repository: sl(), guard: sl()),
    );
    sl.registerLazySingleton(() => GetAttendanceUseCase(repository: sl()));
    sl.registerLazySingleton(
      () => PaySalaryUseCase(repository: sl(), guard: sl()),
    );
    sl.registerLazySingleton(() => GetPayrollUseCase(repository: sl()));
    sl.registerLazySingleton(
      () => RequestAdvanceUseCase(repository: sl(), guard: sl()),
    );
    sl.registerLazySingleton(() => GetAdvancesUseCase(repository: sl()));
    sl.registerLazySingleton(() => SettleAdvancesUseCase(repository: sl()));
    sl.registerLazySingleton(() => GetEmployeeUseCase(repository: sl()));

    // Repository
    sl.registerLazySingleton<EmployeeRepository>(
      () => EmployeeRepositoryImpl(
        remoteDataSource: sl(),
        connectionChecker: sl(),
      ),
    );

    // Data sources
    sl.registerLazySingleton<EmployeeRemoteDataSource>(
      () => EmployeeRemoteDataSourceImpl(firestore: sl()),
    );

    // External dependencies checker if not registered
    if (!sl.isRegistered<InternetConnectionChecker>()) {
      sl.registerLazySingleton(() => InternetConnectionChecker());
    }
  }
}

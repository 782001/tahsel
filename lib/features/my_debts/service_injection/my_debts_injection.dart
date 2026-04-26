import 'package:get_it/get_it.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/repositories/my_debt_repository_impl.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';
import 'package:tahsel/features/my_debts/domain/usecases/my_debt_usecases.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_cubit.dart';

class MyDebtsInjection {
  static void init(GetIt sl) {
    // Cubit
    sl.registerLazySingleton(() => MyDebtsCubit(
          getMyDebtsUseCase: sl(),
          addMyDebtUseCase: sl(),
          addMyDebtTransactionUseCase: sl(),
          getMyDebtTransactionsUseCase: sl(),
          deleteMyDebtUseCase: sl(),
          updateMyDebtUseCase: sl(),
          getTotalPeopleCountUseCase: sl(),
        ));

    sl.registerFactory(() => MyDebtDetailsCubit(
          getTransactionsUseCase: sl(),
          addTransactionUseCase: sl(),
        ));

    // Use cases
    sl.registerLazySingleton(() => GetMyDebtsUseCase(sl()));
    sl.registerLazySingleton(() => AddMyDebtUseCase(sl()));
    sl.registerLazySingleton(() => AddMyDebtTransactionUseCase(sl()));
    sl.registerLazySingleton(() => GetMyDebtTransactionsUseCase(sl()));
    sl.registerLazySingleton(() => DeleteMyDebtUseCase(sl()));
    sl.registerLazySingleton(() => UpdateMyDebtUseCase(sl()));
    sl.registerLazySingleton(() => GetTotalPeopleCountUseCase(sl()));

    // Repository
    sl.registerLazySingleton<MyDebtRepository>(
      () => MyDebtRepositoryImpl(remoteDataSource: sl()),
    );

    // Data source
    sl.registerLazySingleton<MyDebtRemoteDataSource>(
      () => MyDebtRemoteDataSourceImpl(firestore: sl(), auth: sl()),
    );
  }
}

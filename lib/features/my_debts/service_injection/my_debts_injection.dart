import 'package:get_it/get_it.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_person_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_item_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/repositories/my_debt_repository_impl.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_persons_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/add_my_debt_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/pay_my_debt_item_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/distribute_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/update_my_debt_person_preference_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_items_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_person_operations_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/delete_my_debt_item_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_item_payments_usecase.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_cubit.dart';

class MyDebtsInjection {
  static void init(GetIt sl) {
    // Cubits
    sl.registerLazySingleton(() => MyDebtsCubit(
          getPersonsUseCase: sl(),
          addDebtUseCase: sl(),
          distributePaymentUseCase: sl(),
          updatePreferenceUseCase: sl(),
        ));

    sl.registerFactory(() => MyDebtDetailsCubit(
          getItemsUseCase: sl(),
          getOperationsUseCase: sl(),
          payItemUseCase: sl(),
          deleteItemUseCase: sl(),
          addDebtUseCase: sl(),
          distributePaymentUseCase: sl(),
        ));
        
    sl.registerFactory(() => MyDebtDetailsReportCubit(
          getMyDebtItemPaymentsUseCase: sl(),
        ));

    // Use cases
    sl.registerLazySingleton(() => GetMyDebtPersonsUseCase(sl()));
    sl.registerLazySingleton(() => AddMyDebtUseCase(sl()));
    sl.registerLazySingleton(() => PayMyDebtItemUseCase(sl()));
    sl.registerLazySingleton(() => DistributeMyDebtPaymentUseCase(sl()));
    sl.registerLazySingleton(() => UpdateMyDebtPersonPreferenceUseCase(sl()));
    sl.registerLazySingleton(() => GetMyDebtItemsUseCase(sl()));
    sl.registerLazySingleton(() => GetMyDebtPersonOperationsUseCase(sl()));
    sl.registerLazySingleton(() => DeleteMyDebtItemUseCase(sl()));
    sl.registerLazySingleton(() => GetMyDebtItemPaymentsUseCase(sl()));

    // Repository
    sl.registerLazySingleton<MyDebtRepository>(
      () => MyDebtRepositoryImpl(
        personRemoteDataSource: sl(),
        itemRemoteDataSource: sl(),
      ),
    );

    // Data sources
    sl.registerLazySingleton<MyDebtPersonRemoteDataSource>(
      () => MyDebtPersonRemoteDataSourceImpl(firestore: sl()),
    );
    sl.registerLazySingleton<MyDebtItemRemoteDataSource>(
      () => MyDebtItemRemoteDataSourceImpl(firestore: sl()),
    );
  }
}

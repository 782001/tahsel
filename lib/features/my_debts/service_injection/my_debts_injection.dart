import 'package:get_it/get_it.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_item_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_person_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/repositories/my_debt_repository_impl.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/add_my_debt_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/delete_my_debt_item_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_item_payments_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_item_payments_paginated_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_items_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_pending_my_debts_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/delete_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/distribute_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/pay_my_debt_item_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/update_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_person_operations_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_persons_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_persons_paginated_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/update_my_debt_person_preference_usecase.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_summary_cubit.dart';
import 'package:tahsel/features/my_debts/domain/usecases/get_my_debt_by_id_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_summary_usecase.dart';

class MyDebtsInjection {
  static void init(GetIt sl) {
    // Cubits
    sl.registerLazySingleton(
      () => MyDebtsCubit(
        getPersonsUseCase: sl(),
        getPersonsPaginatedUseCase: sl(),
        addDebtUseCase: sl(),
        distributePaymentUseCase: sl(),
        updatePreferenceUseCase: sl(),
        getPendingMyDebtsUseCase: sl(),
        connectivityCubit: sl(),
        offlineSyncCubit: sl(),
      ),
    );

    sl.registerLazySingleton(
      () => MyDebtsSummaryCubit(
        getMyDebtSummaryUseCase: sl(),
      ),
    );

    sl.registerFactory(
      () => MyDebtDetailsCubit(
        getItemsUseCase: sl(),
        getOperationsUseCase: sl(),
        payItemUseCase: sl(),
        deleteItemUseCase: sl(),
        addDebtUseCase: sl(),
        distributePaymentUseCase: sl(),
        getPendingMyDebtsUseCase: sl(),
        connectivityCubit: sl(),
        offlineSyncCubit: sl(),
      ),
    );

    sl.registerFactory(
      () => MyDebtDetailsReportCubit(
        getMyDebtItemPaymentsUseCase: sl(),
        getMyDebtItemPaymentsPaginatedUseCase: sl(),
        updateMyDebtPaymentUseCase: sl(),
        deleteMyDebtPaymentUseCase: sl(),
        getMyDebtByIdUseCase: sl(),
      ),
    );

    // Use cases
    sl.registerLazySingleton(() => GetMyDebtPersonsUseCase(repository: sl()));
    sl.registerLazySingleton(() => GetMyDebtPersonsPaginatedUseCase(repository: sl()));
    sl.registerLazySingleton(() => GetMyDebtSummaryUseCase(repository: sl()));
    sl.registerLazySingleton(() => AddMyDebtUseCase(sl()));
    sl.registerLazySingleton(() => PayMyDebtItemUseCase(sl()));
    sl.registerLazySingleton(() => DistributeMyDebtPaymentUseCase(sl()));
    sl.registerLazySingleton(() => UpdateMyDebtPersonPreferenceUseCase(sl()));
    sl.registerLazySingleton(() => GetMyDebtItemsUseCase(repository: sl()));
    sl.registerLazySingleton(
      () => GetMyDebtPersonOperationsUseCase(repository: sl()),
    );
    sl.registerLazySingleton(() => DeleteMyDebtItemUseCase(sl()));
    sl.registerLazySingleton(
      () => GetMyDebtItemPaymentsUseCase(repository: sl()),
    );
    sl.registerLazySingleton(
      () => GetMyDebtItemPaymentsPaginatedUseCase(repository: sl()),
    );
    sl.registerLazySingleton(
      () => UpdateMyDebtPaymentUseCase(repository: sl()),
    );
    sl.registerLazySingleton(
      () => DeleteMyDebtPaymentUseCase(repository: sl()),
    );
    sl.registerLazySingleton(() => GetPendingMyDebtsUseCase(sl()));
    sl.registerLazySingleton(() => GetMyDebtByIdUseCase(sl()));

    // Repository
    sl.registerLazySingleton<MyDebtRepository>(
      () => MyDebtRepositoryImpl(
        personRemoteDataSource: sl(),
        itemRemoteDataSource: sl(),
        offlineSyncRepository: sl(),
        connectionChecker: sl(),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/debt/domain/usecases/delete_payment_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/get_debt_by_id_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/get_debt_transactions_future_use_case.dart';
import 'package:tahsel/features/debt/domain/usecases/update_payment_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/get_monthly_collected_amounts_usecase.dart';
import 'package:tahsel/features/debt/presentation/cubit/monthly_collected/monthly_collected_cubit.dart';

import '../data/datasources/debt_remote_data_source.dart';
import '../data/repositories/debt_repository_impl.dart';
import '../domain/repositories/debt_repository.dart';
import '../domain/usecases/add_debt_usecase.dart';
import '../domain/usecases/calculate_total_debts_usecase.dart';
import '../domain/usecases/delete_customer_debt_usecase.dart';
import '../domain/usecases/delete_debt_item_usecase.dart';
import '../domain/usecases/get_all_user_payments_paginated_usecase.dart';
import '../domain/usecases/get_customer_all_payments_paginated_usecase.dart';
import '../domain/usecases/get_customer_all_payments_usecase.dart';
import '../domain/usecases/get_debt_transactions_paginated_usecase.dart';
import '../domain/usecases/get_debt_transactions_use_case.dart';
import '../domain/usecases/get_debts_paginated_usecase.dart';
import '../domain/usecases/get_debts_stream_usecase.dart';
import '../domain/usecases/get_debts_usecase.dart';
import '../domain/usecases/mark_customer_as_paid_usecase.dart';
import '../domain/usecases/mark_item_as_paid_usecase.dart';
import '../domain/usecases/pay_debt_usecase.dart';
import '../domain/usecases/pay_item_debt_usecase.dart';
import '../domain/usecases/get_customer_debts_usecase.dart';
import '../domain/usecases/get_debt_summary_usecase.dart';
import '../presentation/cubit/debt_cubit.dart';
import '../presentation/cubit/debt_details/debt_details_cubit.dart';
import '../presentation/cubit/global_payments/global_payments_cubit.dart';
import '../presentation/cubit/total_debts/total_debts_cubit.dart';

Future<void> initDebt() async {
  // Cubit
  sl.registerLazySingleton(
    () => DebtCubit(
      addDebtUseCase: sl(),
      getDebtsUseCase: sl(),
      getDebtsPaginatedUseCase: sl(),
      payDebtUseCase: sl(),
      markCustomerAsPaidUseCase: sl(),
      payItemDebtUseCase: sl(),
      markItemAsPaidUseCase: sl(),
      deleteCustomerDebtUseCase: sl(),
      deleteDebtItemUseCase: sl(),
      getCustomerDebtsUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => DebtDetailsCubit(
      getDebtTransactionsUseCase: sl(),
      updatePaymentUseCase: sl(),
      deletePaymentUseCase: sl(),
      getDebtByIdUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => GlobalPaymentsCubit(
      getCustomerAllPaymentsUseCase: sl(),
      getCustomerAllPaymentsPaginatedUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => TotalDebtsCubit(getDebtSummaryUseCase: sl()));

  sl.registerFactory(
    () => MonthlyCollectedCubit(getMonthlyCollectedAmountsUseCase: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => AddDebtUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetDebtsUseCase(repository: sl()));
  sl.registerLazySingleton(() => PayDebtUseCase(repository: sl()));
  sl.registerLazySingleton(() => MarkCustomerAsPaidUseCase(repository: sl()));
  sl.registerLazySingleton(() => PayItemDebtUseCase(repository: sl()));
  sl.registerLazySingleton(() => MarkItemAsPaidUseCase(repository: sl()));
  sl.registerLazySingleton(() => DeleteCustomerDebtUseCase(repository: sl()));
  sl.registerLazySingleton(() => DeleteDebtItemUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetDebtTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetDebtTransactionsFutureUseCase(sl()));
  sl.registerLazySingleton(
    () => GetCustomerAllPaymentsUseCase(repository: sl()),
  );
  sl.registerLazySingleton(() => GetDebtsStreamUseCase(sl()));
  sl.registerLazySingleton(() => CalculateTotalDebtsUseCase());
  sl.registerLazySingleton(() => UpdatePaymentUseCase(repository: sl()));
  sl.registerLazySingleton(() => DeletePaymentUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetDebtByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetDebtsPaginatedUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerAllPaymentsPaginatedUseCase(sl()));
  sl.registerLazySingleton(() => GetDebtTransactionsPaginatedUseCase(sl()));
  sl.registerLazySingleton(() => GetAllUserPaymentsPaginatedUseCase(sl()));
  sl.registerLazySingleton(() => GetMonthlyCollectedAmountsUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerDebtsUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetDebtSummaryUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<DebtRepository>(
    () => DebtRepositoryImpl(
      remoteDataSource: sl(),
      connectionChecker: sl(),
      offlineSyncRepository: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<DebtRemoteDataSource>(
    () => DebtRemoteDataSourceImpl(firestore: sl()),
  );

  // External
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/debt/domain/usecases/get_debt_by_id_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/get_debt_transactions_future_use_case.dart';
import 'package:tahsel/features/debt/domain/usecases/pay_item_debt_usecase.dart';
import 'package:tahsel/features/invoice/data/datasources/invoice_history_remote_data_source.dart';
import 'package:tahsel/features/invoice/data/datasources/invoice_remote_data_source.dart';
import 'package:tahsel/features/invoice/data/repositories/invoice_history_repository_impl.dart';
import 'package:tahsel/features/invoice/data/repositories/invoice_repository_impl.dart';
import 'package:tahsel/features/invoice/domain/repositories/invoice_history_repository.dart';
import 'package:tahsel/features/invoice/domain/repositories/invoice_repository.dart';
import 'package:tahsel/features/invoice/domain/usecases/invoice_history_usecases.dart';
import 'package:tahsel/features/invoice/domain/usecases/invoice_usecases.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_history_cubit.dart';
import 'package:tahsel/features/invoice/data/datasources/offline_invoice_local_data_source.dart';

Future<void> initInvoice() async {
  // ── Cubits ─────────────────────────────────────────────────────────────────

  sl.registerLazySingleton(
    () => InvoiceCubit(
      createInvoiceUseCase: sl(),
      getInvoicesUseCase: sl(),
      getInvoicesPaginatedUseCase: sl(),
      getPendingInvoicesUseCase: sl(),
      getInvoiceByIdUseCase: sl(),
      recordPaymentUseCase: sl(),
      linkDebtToInvoiceUseCase: sl(),
      addDebtUseCase: sl(),
      getDebtByIdUseCase: sl(),
      payItemDebtUseCase: sl(),
      updateInvoiceUseCase: sl(),
      voidInvoiceUseCase: sl(),
      addInvoiceHistoryUseCase: sl(),
      getDebtTransactionsUseCase: sl(),
      offlineInvoiceLocalDataSource: sl(),
      connectivityCubit: sl(),
    ),
  );

  sl.registerFactory(
    () => InvoiceHistoryCubit(
      getHistoryUseCase: sl(),
      addHistoryUseCase: sl(),
    ),
  );

  // ── Use Cases ──────────────────────────────────────────────────────────────

  sl.registerLazySingleton(() => CreateInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoicesPaginatedUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoiceByIdUseCase(sl()));
  sl.registerLazySingleton(() => RecordPaymentUseCase(sl()));
  sl.registerLazySingleton(() => LinkDebtToInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => UpdateInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => VoidInvoiceUseCase(sl()));
  // Debt use-cases needed by InvoiceCubit for smart payment routing
  if (!sl.isRegistered<GetDebtByIdUseCase>()) {
    sl.registerLazySingleton(() => GetDebtByIdUseCase(sl()));
  }
  if (!sl.isRegistered<PayItemDebtUseCase>()) {
    sl.registerLazySingleton(() => PayItemDebtUseCase(repository: sl()));
  }
  if (!sl.isRegistered<GetDebtTransactionsFutureUseCase>()) {
    sl.registerLazySingleton(() => GetDebtTransactionsFutureUseCase(sl()));
  }

  // History use-cases
  sl.registerLazySingleton(
    () => AddInvoiceHistoryUseCase(sl<InvoiceHistoryRepository>()),
  );
  sl.registerLazySingleton(
    () => GetInvoiceHistoryUseCase(sl<InvoiceHistoryRepository>()),
  );

  // ── Repositories ───────────────────────────────────────────────────────────

  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(
      remoteDataSource: sl(),
      offlineSyncRepository: sl(),
      connectionChecker: sl(),
    ),
  );

  sl.registerLazySingleton<InvoiceHistoryRepository>(
    () => InvoiceHistoryRepositoryImpl(
      remoteDataSource: sl(),
      connectionChecker: sl(),
    ),
  );

  // ── Data Sources ───────────────────────────────────────────────────────────

  sl.registerLazySingleton<InvoiceRemoteDataSource>(
    () => InvoiceRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<InvoiceHistoryRemoteDataSource>(
    () => InvoiceHistoryRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<OfflineInvoiceLocalDataSource>(
    () => OfflineInvoiceLocalDataSourceImpl(),
  );

  // ── External ───────────────────────────────────────────────────────────────

  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }
}

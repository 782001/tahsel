import 'package:get_it/get_it.dart';
import '../data/datasources/vault_remote_data_source.dart';
import '../data/repositories/vault_repository_impl.dart';
import '../domain/repositories/vault_repository.dart';
import '../domain/usecases/delete_manual_vault_usecase.dart';
import '../domain/usecases/deposit_manual_vault_usecase.dart';
import '../domain/usecases/edit_manual_vault_usecase.dart';
import '../domain/usecases/get_vault_summary_usecase.dart';
import '../domain/usecases/get_vault_transactions_paginated_usecase.dart';
import '../domain/usecases/record_vault_transaction_usecase.dart';
import '../domain/usecases/withdraw_manual_vault_usecase.dart';
import '../presentation/cubit/vault_cubit.dart';

class CashboxInjection {
  static Future<void> init(GetIt sl) async {
    // Cubit
    sl.registerFactory(
      () => VaultCubit(
        getVaultSummaryUseCase: sl(),
        getVaultTransactionsPaginatedUseCase: sl(),
        depositManualVaultUseCase: sl(),
        withdrawManualVaultUseCase: sl(),
        editManualVaultUseCase: sl(),
        deleteManualVaultUseCase: sl(),
      ),
    );

    // UseCases
    sl.registerLazySingleton(() => GetVaultSummaryUseCase(sl()));
    sl.registerLazySingleton(() => GetVaultTransactionsPaginatedUseCase(sl()));
    sl.registerLazySingleton(() => DepositManualVaultUseCase(sl()));
    sl.registerLazySingleton(() => WithdrawManualVaultUseCase(sl()));
    sl.registerLazySingleton(() => RecordVaultTransactionUseCase(sl()));
    sl.registerLazySingleton(() => EditManualVaultUseCase(sl()));
    sl.registerLazySingleton(() => DeleteManualVaultUseCase(sl()));

    // Repository
    sl.registerLazySingleton<VaultRepository>(
      () => VaultRepositoryImpl(remoteDataSource: sl()),
    );

    // DataSource
    sl.registerLazySingleton<VaultRemoteDataSource>(
      () => VaultRemoteDataSourceImpl(firestore: sl()),
    );
  }
}

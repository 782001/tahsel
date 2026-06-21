import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/debt/domain/repositories/debt_repository.dart';

import '../data/datasources/operation_remote_data_source.dart';
import '../data/datasources/ps_session_remote_data_source.dart';
import '../data/repositories/operation_repository_impl.dart';
import '../data/repositories/ps_session_repository_impl.dart';
import '../domain/repositories/operation_repository.dart';
import '../domain/repositories/ps_session_repository.dart';
import '../domain/usecases/add_operation_usecase.dart';
import '../domain/usecases/calculate_remaining_debt_usecase.dart';
import '../domain/usecases/ps_session_usecases.dart';
import '../presentation/cubit/operation_cubit.dart';
import '../presentation/cubit/ps_session_cubit.dart';

Future<void> initOperation() async {
  // Cubit
  sl.registerFactory(
    () => OperationCubit(
      addOperationUseCase: sl(),
      calculateRemainingDebtUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => PsSessionCubit(
      startPsSessionUseCase: sl(),
      endPsSessionUseCase: sl(),
      getActiveSessionsUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(
    () => AddOperationUseCase(
      repository: sl<OperationRepository>(),
      debtRepository: sl<DebtRepository>(),
    ),
  );
  sl.registerLazySingleton(() => CalculateRemainingDebtUseCase());

  sl.registerLazySingleton(() => StartPsSessionUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => EndPsSessionUseCase(repository: sl(), debtRepository: sl()),
  );
  sl.registerLazySingleton(() => GetActiveSessionsUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<OperationRepository>(
    () => OperationRepositoryImpl(
      remoteDataSource: sl(),
      offlineSyncRepository: sl(),
      connectionChecker: sl(),
    ),
  );
  sl.registerLazySingleton<PsSessionRepository>(
    () => PsSessionRepositoryImpl(
      remoteDataSource: sl(),
      offlineSyncRepository: sl(),
      connectionChecker: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<OperationRemoteDataSource>(
    () => OperationRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<PsSessionRemoteDataSource>(
    () => PsSessionRemoteDataSourceImpl(firestore: sl()),
  );

  // External
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }
}

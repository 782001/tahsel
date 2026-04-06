import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../data/datasources/debt_remote_data_source.dart';
import '../data/repositories/debt_repository_impl.dart';
import '../domain/repositories/debt_repository.dart';
import '../domain/usecases/add_debt_usecase.dart';
import '../domain/usecases/get_debts_usecase.dart';
import '../presentation/cubit/debt_cubit.dart';

Future<void> initDebt() async {
  final sl = GetIt.instance;

  // Cubit
  sl.registerFactory(
    () => DebtCubit(
      addDebtUseCase: sl(),
      getDebtsUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AddDebtUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetDebtsUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<DebtRepository>(
    () => DebtRepositoryImpl(remoteDataSource: sl()),
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

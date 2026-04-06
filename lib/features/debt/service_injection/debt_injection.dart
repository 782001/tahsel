import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:tahsel/core/services/injection_container.dart';
import '../data/datasources/debt_remote_data_source.dart';
import '../data/repositories/debt_repository_impl.dart';
import '../domain/repositories/debt_repository.dart';
import '../domain/usecases/add_debt_usecase.dart';
import '../domain/usecases/get_debts_usecase.dart';
import '../domain/usecases/pay_debt_usecase.dart';
import '../domain/usecases/mark_customer_as_paid_usecase.dart';
import '../domain/usecases/mark_item_as_paid_usecase.dart';
import '../domain/usecases/pay_item_debt_usecase.dart';
import '../presentation/cubit/debt_cubit.dart';

Future<void> initDebt() async {


  // Cubit
  sl.registerFactory(
    () => DebtCubit(
      addDebtUseCase: sl(),
      getDebtsUseCase: sl(),
      payDebtUseCase: sl(),
      markCustomerAsPaidUseCase: sl(),
      payItemDebtUseCase: sl(),
      markItemAsPaidUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AddDebtUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetDebtsUseCase(repository: sl()));
  sl.registerLazySingleton(() => PayDebtUseCase(repository: sl()));
  sl.registerLazySingleton(() => MarkCustomerAsPaidUseCase(repository: sl()));
  sl.registerLazySingleton(() => PayItemDebtUseCase(repository: sl()));
  sl.registerLazySingleton(() => MarkItemAsPaidUseCase(repository: sl()));

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

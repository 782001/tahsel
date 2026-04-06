import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/services/injection_container.dart';

import '../data/datasources/operation_remote_data_source.dart';
import '../data/repositories/operation_repository_impl.dart';
import '../domain/repositories/operation_repository.dart';
import '../domain/usecases/add_operation_usecase.dart';
import '../presentation/cubit/operation_cubit.dart';

Future<void> initOperation() async {
  // Cubit
  sl.registerFactory(() => OperationCubit(addOperationUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => AddOperationUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<OperationRepository>(
    () => OperationRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<OperationRemoteDataSource>(
    () => OperationRemoteDataSourceImpl(firestore: sl()),
  );

  // External
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../data/datasources/operation_remote_data_source.dart';
import '../data/repositories/operation_repository_impl.dart';
import '../domain/repositories/operation_repository.dart';
import '../domain/usecases/add_operation_usecase.dart';
import '../presentation/cubit/operation_cubit.dart';

Future<void> initOperation() async {
  // Cubit
  GetIt.instance.registerFactory(
    () => OperationCubit(addOperationUseCase: GetIt.instance()),
  );

  // Use cases
  GetIt.instance.registerLazySingleton(
    () => AddOperationUseCase(repository: GetIt.instance()),
  );

  // Repository
  GetIt.instance.registerLazySingleton<OperationRepository>(
    () => OperationRepositoryImpl(
      remoteDataSource: GetIt.instance(),
    ),
  );

  // Data sources
  GetIt.instance.registerLazySingleton<OperationRemoteDataSource>(
    () => OperationRemoteDataSourceImpl(firestore: GetIt.instance()),
  );

  // External
  if (!GetIt.instance.isRegistered<FirebaseFirestore>()) {
    GetIt.instance.registerLazySingleton(() => FirebaseFirestore.instance);
  }
}

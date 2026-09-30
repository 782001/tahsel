import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../data/datasources/custody_remote_data_source.dart';
import '../data/repositories/custody_repository_impl.dart';
import '../domain/repositories/custody_repository.dart';
import '../presentation/cubit/custody_cubit.dart';

class CustodyInjection {
  CustodyInjection._();

  static void init(GetIt sl) {
    // Data Sources
    sl.registerLazySingleton<CustodyRemoteDataSource>(
      () => CustodyRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
    );

    // Repository
    sl.registerLazySingleton<CustodyRepository>(
      () => CustodyRepositoryImpl(
        remoteDataSource: sl<CustodyRemoteDataSource>(),
      ),
    );

    // Cubit
    sl.registerFactory<CustodyCubit>(
      () => CustodyCubit(repository: sl<CustodyRepository>()),
    );
  }
}

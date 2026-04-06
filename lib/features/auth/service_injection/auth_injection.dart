import 'package:get_it/get_it.dart';

import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repo_impl.dart';
import '../domain/repositories/auth_repo_base.dart';
import '../domain/usecases/login_usecase.dart';
import '../presentation/cubit/auth_cubit.dart';

class AuthInjection {
  static void init(GetIt sl) {
    // Cubit
    sl.registerFactory(() => AuthCubit(loginUseCase: sl()));

    // Use cases
    sl.registerLazySingleton(() => LoginUseCase(baseRepository: sl()));

    // Repository
    sl.registerLazySingleton<AuthBaseRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()),
    );

    // Data sources
    sl.registerLazySingleton<AuthRemoteDataSourceBase>(
      () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
    );
  }
}

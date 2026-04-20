import 'package:get_it/get_it.dart';

import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repo_impl.dart';
import '../domain/repositories/auth_repo_base.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../presentation/cubit/auth_cubit.dart';

import 'package:internet_connection_checker/internet_connection_checker.dart';

class AuthInjection {
  static void init(GetIt sl) {
    // Connection checker
    if (!sl.isRegistered<InternetConnectionChecker>()) {
      sl.registerLazySingleton<InternetConnectionChecker>(
        () => InternetConnectionChecker(),
      );
    }

    // Cubit
    sl.registerFactory(() => AuthCubit(loginUseCase: sl(), logoutUseCase: sl()));

    // Use cases
    sl.registerLazySingleton(() => LoginUseCase(baseRepository: sl()));
    sl.registerLazySingleton(() => LogoutUseCase(baseRepository: sl()));

    // Repository
    sl.registerLazySingleton<AuthBaseRepository>(
      () => AuthRepositoryImpl(
          remoteDataSource: sl(), 
          secureStorage: sl(),
          connectionChecker: sl(),
      ),
    );

    // Data sources
    sl.registerLazySingleton<AuthRemoteDataSourceBase>(
      () => AuthRemoteDataSourceImpl(
        firebaseAuth: sl(),
        firestore: sl(),
      ),
    );
  }
}

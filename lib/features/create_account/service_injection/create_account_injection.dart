import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/features/create_account/data/datasources/create_account_remote_data_source.dart';
import 'package:tahsel/features/create_account/data/repositories/create_account_repository_impl.dart';
import 'package:tahsel/features/create_account/data/services/create_account_auth_service.dart';
import 'package:tahsel/features/create_account/domain/repositories/create_account_repository.dart';
import 'package:tahsel/features/create_account/domain/usecases/create_account_usecases.dart';
import 'package:tahsel/features/create_account/presentation/cubit/create_account/create_account_cubit.dart';

class CreateAccountDependencies {
  static void init(GetIt sl) {
    // Connection checker
    if (!sl.isRegistered<InternetConnectionChecker>()) {
      sl.registerLazySingleton<InternetConnectionChecker>(
        () => InternetConnectionChecker(),
      );
    }
    sl.registerLazySingleton<CreateAccountService>(
      () => CreateAccountService(),
    );

    sl.registerLazySingleton<CreateAccountRemoteDataSource>(
      () =>
          CreateAccountRemoteDataSourceImpl(firestore: sl(), authService: sl()),
    );

    sl.registerLazySingleton<CreateAccountRepository>(
      () => CreateAccountRepositoryImpl(sl<CreateAccountRemoteDataSource>()),
    );

    // Use cases

    sl.registerLazySingleton(() => CreateUserUseCase(sl()));

    // Cubits
    sl.registerFactory(() => CreateAccountCubit(createUser: sl()));
  }
}

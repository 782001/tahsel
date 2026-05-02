import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/auth/service_injection/auth_injection.dart';
import 'package:tahsel/features/category/service_injection/category_injection.dart';
import 'package:tahsel/features/operation/service_injection/operation_injection.dart';
import 'package:tahsel/features/customer/service_injection/customer_injection.dart';
import 'package:tahsel/features/product/service_injection/product_injection.dart';
import 'package:tahsel/features/debt/service_injection/debt_injection.dart';
import 'package:tahsel/features/expenses/service_injection/expense_injection.dart';
import 'package:tahsel/features/offline_sync/service_injection/offline_sync_injection.dart';
import 'package:tahsel/features/reports/service_injection/reports_injection.dart';
import 'package:tahsel/features/my_debts/service_injection/my_debts_injection.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:vault_kit/vault_kit.dart';
import 'package:get_it/get_it.dart';
import '../../core/dio_client/dio_client.dart';
import '../../core/services/navigator_service.dart';
import '../../core/storage/cashhelper.dart';
import '../../core/storage/secure_storage_helper.dart';
import '../../features/standard_features/localization/data/datasources/lang_local_data_source.dart';
import '../../features/standard_features/localization/data/repositories/lang_repository_impl.dart';
import '../../features/standard_features/localization/domain/repositories/lang_repository.dart';
import '../../features/standard_features/localization/domain/usecases/change_lang.dart';
import '../../features/standard_features/localization/domain/usecases/get_saved_lang.dart';
import '../../features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import '../../features/standard_features/theme/presentation/cubit/theme_cubit.dart';
import '../../features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // firebase
  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }

  //! Features
  await CategoryDI.init();
  AuthInjection.init(sl);
  await initDebt();
  await initOperation();
  initCustomerInjection();
  initProductInjection();
  await initExpense();
  await OfflineSyncInjection.init(sl);
  ReportsInjection.init(sl);
  MyDebtsInjection.init(sl);

  // localization
  /// -----localizationCubit------
  sl.registerFactory<LocaleCubit>(
    () => LocaleCubit(getSavedLangUseCase: sl(), changeLangUseCase: sl()),
  );

  // theme
  sl.registerFactory<ThemeCubit>(() => ThemeCubit(cashHelper: sl()));

  // connectivity
  sl.registerFactory<ConnectivityCubit>(() => ConnectivityCubit());

  // main layout
  sl.registerFactory<MainLayoutCubit>(
    () => MainLayoutCubit(
      cleanupOldReportsUseCase: sl(),
      cashHelper: sl(),
      secureStorage: sl(),
      firestore: sl(),
    ),
  );

  /// --------useCases----------
  sl.registerLazySingleton<ChangeLangUseCase>(
    () => ChangeLangUseCase(langRepository: sl()),
  );
  sl.registerLazySingleton<GetSavedLangUseCase>(
    () => GetSavedLangUseCase(langRepository: sl()),
  );

  /// --------Repository--------
  sl.registerLazySingleton<LangRepository>(
    () => LangRepositoryImpl(langLocalDataSource: sl()),
  );

  /// --------DataSource--------
  sl.registerLazySingleton<LangLocalDataSource>(
    () => LangLocalDataSourceImpl(),
  );
  // cart
  /// -----CartCubit------
  ///
  // sl.registerFactory<CartCubit>(
  //   () => CartCubit(
  //     kGetCartItemsUseCase: sl(),
  //     kAddToCartUseCase: sl(),
  //     kDeleteCartItemUseCase: sl(),
  //   ),
  // );

  /// --------useCases----------
  // sl.registerLazySingleton<AddToCartUseCase>(
  //   () => AddToCartUseCase(baseRepository: sl()),
  // );
  // sl.registerLazySingleton<DeleteCartItemUseCase>(
  //   () => DeleteCartItemUseCase(baseRepository: sl()),
  // );

  /// --------Repository--------
  // sl.registerLazySingleton<AddToCartBaseRepository>(
  //   () => AddToCartRepository(sl()),
  // );
  // sl.registerLazySingleton<DeleteCartItemBaseRepository>(
  //   () => DeleteCartItemRepository(sl()),
  // );

  /// --------DataSource--------
  // sl.registerLazySingleton<AddToCartBaseRemoteDataSource>(
  //   () => AddToCartRemoteDataSource(),
  // );
  // sl.registerLazySingleton<DeleteCartItemBaseRemoteDataSource>(
  //   () => DeleteCartItemRemoteDataSource(),
  // );

  //! Core

  /// --------------------------
  /// External
  /// --------------------------

  /// --------------------------
  /// Local Storage
  /// --------------------------

  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPrefs);
  sl.registerLazySingleton<CashHelper>(
    () => CashHelper(sl<SharedPreferences>()),
  );

  final vault = VaultKit();
  sl.registerLazySingleton<SecureStorageHelper>(
    () => SecureStorageHelper(vault),
  );

  /// --------------------------
  /// Network (Dio)
  /// --------------------------
  sl.registerLazySingleton<DioClient>(() => DioClient(Dio()));

  // Register NavigatorService as singleton
  sl.registerLazySingleton<NavigatorService>(() => NavigatorService());

  // PRELOAD: Session data for offline-first start
  try {
    final secureStorage = sl<SecureStorageHelper>();
    final token = await secureStorage.getData(key: 'token');
    final userType = await secureStorage.getData(key: AppStrings.userTypeKey);

    if (token != null && token.isNotEmpty) {
      AppStrings.userToken = token;
      AppStrings.userType = userType ?? AppStrings.cafe;
    }
  } catch (e) {
    // Silent catch: Splash screen will handle invalid sessions
  }
}

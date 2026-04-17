import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../standard_features/no-internet/logic/connectivity_cubit.dart';
import '../data/datasources/offline_local_data_source.dart';
import '../data/datasources/offline_remote_data_source.dart';
import '../data/models/offline_record.dart';
import '../data/repositories/offline_sync_repository_impl.dart';
import '../domain/repositories/offline_sync_repository.dart';
import '../domain/usecases/offline_sync_usecases.dart';
import '../presentation/cubit/offline_sync_cubit.dart';

class OfflineSyncInjection {
  static Future<void> init(GetIt sl) async {
    // Initialize Hive and Register Adapter
    await Hive.initFlutter();
    Hive.registerAdapter(OfflineRecordAdapter());

    // Data Sources
    sl.registerLazySingleton<OfflineLocalDataSource>(
      () => OfflineLocalDataSourceImpl(),
    );
    sl.registerLazySingleton<OfflineRemoteDataSource>(
      () => OfflineRemoteDataSourceImpl(firestore: sl()),
    );

    // Connection checker
    if (!sl.isRegistered<InternetConnectionChecker>()) {
      sl.registerLazySingleton<InternetConnectionChecker>(
        () => InternetConnectionChecker(),
      );
    }

    // Repository
    sl.registerLazySingleton<OfflineSyncRepository>(
      () => OfflineSyncRepositoryImpl(
        localDataSource: sl(),
        remoteDataSource: sl(),
        connectionChecker: sl(),
      ),
    );

    // UseCases
    sl.registerLazySingleton<AddOfflineRecordUseCase>(
      () => AddOfflineRecordUseCase(sl()),
    );
    sl.registerLazySingleton<SyncPendingOperationsUseCase>(
      () => SyncPendingOperationsUseCase(sl()),
    );
    sl.registerLazySingleton<GetPendingItemsUseCase>(
      () => GetPendingItemsUseCase(sl()),
    );

    // Cubit
    sl.registerFactory<OfflineSyncCubit>(
      () => OfflineSyncCubit(
        syncPendingOperationsUseCase: sl(),
        getPendingItemsUseCase: sl(),
        connectivityCubit: sl(),
      ),
    );
  }
}

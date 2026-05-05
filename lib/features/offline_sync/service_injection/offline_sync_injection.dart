import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path_provider/path_provider.dart';
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
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
    }
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

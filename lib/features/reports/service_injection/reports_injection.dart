import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../data/datasources/reports_remote_data_source.dart';
import '../data/repositories/reports_repository_impl.dart';
import '../domain/repositories/reports_repository.dart';
import '../domain/usecases/get_reports_usecase.dart';
import '../domain/usecases/generate_insights_usecase.dart';
import '../presentation/cubit/reports_cubit.dart';

class ReportsInjection {
  static void init(GetIt sl) {
    // Cubit
    sl.registerFactory(() => ReportsCubit(
          getReportsUseCase: sl(),
          generateInsightsUseCase: sl(),
        ));

    // Use cases
    sl.registerLazySingleton(() => GetReportsUseCase(sl()));
    sl.registerLazySingleton(() => GenerateInsightsUseCase());

    // Repository
    sl.registerLazySingleton<ReportsRepository>(
      () => ReportsRepositoryImpl(sl()),
    );

    // Data sources
    sl.registerLazySingleton<ReportsRemoteDataSource>(
      () => ReportsRemoteDataSourceImpl(FirebaseFirestore.instance),
    );
  }
}

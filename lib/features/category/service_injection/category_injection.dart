import '../../../../core/services/injection_container.dart';
import '../../../../core/dio_client/dio_client.dart';
import '../data/data_sources/get_category_by_id_remote_ds.dart';
import '../data/repositories/get_category_by_id_repo_impl.dart';
import '../domain/repositories/get_category_by_id_repo_base.dart';
import '../domain/usecases/get_category_by_id_usecase.dart';
import '../presentation/controller/category_cubit/category_cubit.dart';
import '../domain/usecases/get_categories_usecase.dart';
import '../domain/repositories/get_categories_repo_base.dart';
import '../data/repositories/get_categories_repo_impl.dart';
import '../data/data_sources/get_categories_remote_ds.dart';

class CategoryDI {
  static Future<void> init() async {
    // Category
    /// -----CategoryCubit------
    sl.registerFactory<CategoryCubit>(
      () => CategoryCubit(
        kGetCategoriesUseCase: sl(),
        kGetCategoryByIdUseCase: sl(),
      ),
    );

    /// --------useCases----------
    sl.registerLazySingleton<GetCategoriesUseCase>(
      () => GetCategoriesUseCase(baseRepository: sl()),
    );
    sl.registerLazySingleton<GetCategoryByIdUseCase>(
      () => GetCategoryByIdUseCase(baseRepository: sl()),
    );

    /// --------Repository--------
    sl.registerLazySingleton<GetCategoriesBaseRepository>(
      () => GetCategoriesRepository(sl()),
    );
    sl.registerLazySingleton<GetCategoryByIdBaseRepository>(
      () => GetCategoryByIdRepository(sl()),
    );

    /// --------DataSource--------
    sl.registerLazySingleton<GetCategoriesBaseRemoteDataSource>(
      () => GetCategoriesRemoteDataSource(sl<DioClient>()),
    );
    sl.registerLazySingleton<GetCategoryByIdBaseRemoteDataSource>(
      () => GetCategoryByIdRemoteDataSource(sl<DioClient>()),
    );
  }
}

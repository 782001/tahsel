import 'package:dartz/dartz.dart';

import '../../domain/entities/get_categories_entity.dart';
import '../../domain/repositories/get_categories_repo_base.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../data_sources/get_categories_remote_ds.dart';

class GetCategoriesRepository extends GetCategoriesBaseRepository {
  final GetCategoriesBaseRemoteDataSource baseRemoteDataSource;

  GetCategoriesRepository(this.baseRemoteDataSource);

  @override
  Future<Either<dynamic, GetCategoriesResponseEntity>> call({
    required GetCategoriesParameters parameters,
  }) async {
    try {
      final response = await baseRemoteDataSource.GetCategories(
        parameters: parameters,
      );
      return Right(response);
    } catch (e) {
      return Left(e);
    }
  }
}


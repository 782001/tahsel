import 'package:dartz/dartz.dart';

import '../../domain/entities/get_category_by_id_entity.dart';
import '../../domain/repositories/get_category_by_id_repo_base.dart';
import '../../domain/usecases/get_category_by_id_usecase.dart';
import '../data_sources/get_category_by_id_remote_ds.dart';

class GetCategoryByIdRepository extends GetCategoryByIdBaseRepository {
  final GetCategoryByIdBaseRemoteDataSource baseRemoteDataSource;

  GetCategoryByIdRepository(this.baseRemoteDataSource);

  @override
  Future<Either<dynamic, GetCategoryByIdResponseEntity>> call({
    required GetCategoryByIdParameters parameters,
  }) async {
    try {
      final response = await baseRemoteDataSource.GetCategoryById(
        parameters: parameters,
      );
      return Right(response);
    } catch (e) {
      return Left(e);
    }
  }
}


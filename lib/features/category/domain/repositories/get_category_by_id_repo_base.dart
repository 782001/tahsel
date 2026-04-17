import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';

import '../entities/get_category_by_id_entity.dart';
import '../usecases/get_category_by_id_usecase.dart';

abstract class GetCategoryByIdBaseRepository {
  Future<Either<Failure, GetCategoryByIdResponseEntity>> call({
    required GetCategoryByIdParameters parameters,
  });
}


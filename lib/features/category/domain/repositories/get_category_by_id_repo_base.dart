import 'package:dartz/dartz.dart';

import '../entities/get_category_by_id_entity.dart';
import '../usecases/get_category_by_id_usecase.dart';

abstract class GetCategoryByIdBaseRepository {
  Future<Either<dynamic, GetCategoryByIdResponseEntity>> call({
    required GetCategoryByIdParameters parameters,
  });
}


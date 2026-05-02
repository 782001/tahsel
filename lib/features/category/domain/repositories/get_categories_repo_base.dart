import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';

import '../entities/get_categories_entity.dart';
import '../usecases/get_categories_usecase.dart';

abstract class GetCategoriesBaseRepository {
  Future<Either<Failure, GetCategoriesResponseEntity>> call({
    required GetCategoriesParameters parameters,
  });
}

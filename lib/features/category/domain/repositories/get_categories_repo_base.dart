import 'package:dartz/dartz.dart';

import '../entities/get_categories_entity.dart';
import '../usecases/get_categories_usecase.dart';

abstract class GetCategoriesBaseRepository {
  Future<Either<dynamic, GetCategoriesResponseEntity>> call({
    required GetCategoriesParameters parameters,
  });
}


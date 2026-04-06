import 'package:dartz/dartz.dart';

import '../entities/user_entity.dart';
import '../usecases/login_usecase.dart';

abstract class AuthBaseRepository {
  Future<Either<dynamic, UserEntity>> login({
    required LoginParameters parameters,
  });
}

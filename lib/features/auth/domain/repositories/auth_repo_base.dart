import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';

import '../entities/user_entity.dart';
import '../usecases/login_usecase.dart';

abstract class AuthBaseRepository {
  Future<Either<Failure, UserEntity>> login({
    required LoginParameters parameters,
  });

  Future<void> logout();

  Future<Either<Failure, void>> deleteAccount();
}

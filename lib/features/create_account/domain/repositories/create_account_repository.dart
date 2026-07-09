import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';

abstract class CreateAccountRepository {
  Future<Either<Failure, Map<String, dynamic>>> createUser(
    Map<String, dynamic> data,
  );
}

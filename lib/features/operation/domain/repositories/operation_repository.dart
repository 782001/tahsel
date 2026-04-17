import 'package:dartz/dartz.dart';
import '../entities/operation_entity.dart';
import '../../../../core/error/failures.dart';

abstract class OperationRepository {
  Future<Either<Failure, String>> addOperation(OperationEntity operation);
}

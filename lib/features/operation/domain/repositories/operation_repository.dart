import 'package:dartz/dartz.dart';
import '../entities/operation_entity.dart';

abstract class OperationRepository {
  Future<Either<dynamic, void>> addOperation(OperationEntity operation);
}

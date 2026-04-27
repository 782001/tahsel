import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtPersonOperationsUseCase {
  final MyDebtRepository repository;

  GetMyDebtPersonOperationsUseCase(this.repository);

  Future<Either<Failure, List<MyDebtOperationEntity>>> call(String uid, String personName) async {
    return await repository.getMyDebtPersonOperations(uid, personName);
  }
}

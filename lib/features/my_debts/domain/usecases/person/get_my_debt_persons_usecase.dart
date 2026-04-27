import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtPersonsUseCase {
  final MyDebtRepository repository;

  GetMyDebtPersonsUseCase(this.repository);

  Future<Either<Failure, List<MyDebtPersonEntity>>> call(String uid) async {
    return await repository.getMyDebtPersons(uid);
  }
}

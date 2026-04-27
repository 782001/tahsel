import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class DeleteMyDebtItemUseCase {
  final MyDebtRepository repository;

  DeleteMyDebtItemUseCase(this.repository);

  Future<Either<Failure, void>> call(String uid, String debtId) async {
    return await repository.deleteMyDebtItem(uid, debtId);
  }
}

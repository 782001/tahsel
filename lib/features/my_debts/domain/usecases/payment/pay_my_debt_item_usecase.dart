import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class PayMyDebtItemUseCase {
  final MyDebtRepository repository;

  PayMyDebtItemUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required String debtId,
    required double amount,
    String? note,
  }) async {
    return await repository.payMyDebtItem(
      uid: uid,
      debtId: debtId,
      amount: amount,
      note: note,
    );
  }
}

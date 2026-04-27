import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class AddMyDebtUseCase {
  final MyDebtRepository repository;

  AddMyDebtUseCase(this.repository);

  Future<Either<Failure, String>> call(MyDebtItemEntity debt) async {
    return await repository.addMyDebtItem(debt);
  }
}

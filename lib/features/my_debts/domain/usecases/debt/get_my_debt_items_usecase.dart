import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtItemsUseCase {
  final MyDebtRepository repository;

  GetMyDebtItemsUseCase(this.repository);

  Future<Either<Failure, List<MyDebtItemEntity>>> call(String uid, String personName) async {
    return await repository.getMyDebtItems(uid, personName);
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/my_debt_item_entity.dart';
import '../repositories/my_debt_repository.dart';

class GetMyDebtByIdUseCase {
  final MyDebtRepository repository;

  GetMyDebtByIdUseCase(this.repository);

  Future<Either<Failure, MyDebtItemEntity?>> call(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    return await repository.getMyDebtItemById(
      uid,
      debtId,
      forceRefresh: forceRefresh,
    );
  }
}

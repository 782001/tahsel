import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebtByIdUseCase {
  final DebtRepository repository;

  GetDebtByIdUseCase(this.repository);

  Future<Either<Failure, DebtEntity?>> call(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    return await repository.getDebtById(
      uid,
      debtId,
      forceRefresh: forceRefresh,
    );
  }
}

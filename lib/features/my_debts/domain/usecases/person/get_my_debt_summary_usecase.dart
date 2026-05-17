import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_summary_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtSummaryUseCase {
  final MyDebtRepository repository;

  GetMyDebtSummaryUseCase({required this.repository});

  Future<Either<Failure, MyDebtSummaryEntity>> call(String uid) async {
    return await repository.getMyDebtSummary(uid);
  }
}

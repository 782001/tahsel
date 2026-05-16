import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debt_repository.dart';
import '../entities/debt_entity.dart';


class GetDebtSummaryUseCase {
  final DebtRepository repository;

  GetDebtSummaryUseCase({required this.repository});

  Future<Either<Failure, TotalDebtsResult>> call(String uid) async {
    return await repository.getDebtSummary(uid);
  }
}

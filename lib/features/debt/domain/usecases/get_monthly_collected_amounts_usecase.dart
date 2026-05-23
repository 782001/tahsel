import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/monthly_collected_amount.dart';
import '../repositories/debt_repository.dart';

class GetMonthlyCollectedAmountsUseCase
    implements BaseUseCase<List<MonthlyCollectedAmount>, String> {
  final DebtRepository repository;

  GetMonthlyCollectedAmountsUseCase(this.repository);

  @override
  Future<Either<Failure, List<MonthlyCollectedAmount>>> call(String uid) async {
    return await repository.getMonthlyCollectedAmounts(uid);
  }
}

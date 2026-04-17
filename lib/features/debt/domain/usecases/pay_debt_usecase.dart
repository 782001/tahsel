import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debt_repository.dart';

class PayDebtParams {
  final String uid;
  final String customerName;
  final double amount;

  PayDebtParams({
    required this.uid,
    required this.customerName,
    required this.amount,
  });
}

class PayDebtUseCase implements BaseUseCase<void, PayDebtParams> {
  final DebtRepository repository;

  PayDebtUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(PayDebtParams params) {
    return repository.payTotalDebt(params.uid, params.customerName, params.amount);
  }
}

import 'package:dartz/dartz.dart';
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

class PayDebtUseCase {
  final DebtRepository repository;

  PayDebtUseCase({required this.repository});

  Future<Either<dynamic, void>> call(PayDebtParams params) {
    return repository.payTotalDebt(params.uid, params.customerName, params.amount);
  }
}

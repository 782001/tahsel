import 'package:dartz/dartz.dart';
import '../repositories/debt_repository.dart';

class DeleteCustomerDebtUseCase {
  final DebtRepository repository;

  DeleteCustomerDebtUseCase({required this.repository});

  Future<Either<dynamic, void>> call(String uid, String customerName) {
    return repository.deleteCustomerDebts(uid, customerName);
  }
}

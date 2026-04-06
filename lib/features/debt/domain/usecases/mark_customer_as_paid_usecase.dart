import 'package:dartz/dartz.dart';
import '../repositories/debt_repository.dart';

class MarkCustomerAsPaidUseCase {
  final DebtRepository repository;

  MarkCustomerAsPaidUseCase({required this.repository});

  Future<Either<dynamic, void>> call(String uid, String customerName) {
    return repository.markCustomerAsPaid(uid, customerName);
  }
}

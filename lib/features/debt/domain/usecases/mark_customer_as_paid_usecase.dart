import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debt_repository.dart';

class MarkCustomerAsPaidUseCase
    implements BaseUseCase<void, MarkCustomerAsPaidParams> {
  final DebtRepository repository;

  MarkCustomerAsPaidUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(MarkCustomerAsPaidParams params) {
    return repository.markCustomerAsPaid(
      params.uid,
      params.customerName,
      paymentMethod: params.paymentMethod,
    );
  }
}

class MarkCustomerAsPaidParams {
  final String uid;
  final String customerName;
  final String paymentMethod;

  MarkCustomerAsPaidParams({
    required this.uid,
    required this.customerName,
    this.paymentMethod = 'cash',
  });
}

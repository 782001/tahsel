import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

class GetCustomerAllPaymentsParams {
  final String uid;
  final String customerName;

  GetCustomerAllPaymentsParams({required this.uid, required this.customerName});
}

class GetCustomerAllPaymentsUseCase
    implements BaseUseCase<List<PaymentEntity>, GetCustomerAllPaymentsParams> {
  final DebtRepository repository;

  GetCustomerAllPaymentsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<PaymentEntity>>> call(
    GetCustomerAllPaymentsParams params,
  ) {
    return repository.getCustomerAllPayments(params.uid, params.customerName);
  }
}

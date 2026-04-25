import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_operation.dart';
import '../repositories/customer_repository.dart';

class GetCustomerOperationsUseCase {
  final CustomerRepository repository;

  GetCustomerOperationsUseCase(this.repository);

  Future<Either<Failure, List<CustomerOperation>>> call({
    required String uid,
    required String customerName,
  }) async {
    return await repository.getCustomerOperations(uid, customerName);
  }
}

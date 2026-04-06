import 'package:dartz/dartz.dart';
import '../repositories/customer_repository.dart';
import '../entities/customer_entity.dart';

class GetCustomersUseCase {
  final CustomerRepository repository;

  GetCustomersUseCase(this.repository);

  Future<Either<dynamic, List<CustomerEntity>>> call(String uid) {
    return repository.getCustomers(uid);
  }
}

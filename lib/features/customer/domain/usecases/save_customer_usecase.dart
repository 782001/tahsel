import 'package:dartz/dartz.dart';
import '../repositories/customer_repository.dart';
import '../entities/customer_entity.dart';

class SaveCustomerUseCase {
  final CustomerRepository repository;

  SaveCustomerUseCase(this.repository);

  Future<Either<dynamic, void>> call(String uid, CustomerEntity customer) {
    return repository.saveCustomer(uid, customer);
  }
}

import 'package:dartz/dartz.dart';
import '../../domain/entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Either<dynamic, List<CustomerEntity>>> getCustomers(String uid);
  Future<Either<dynamic, void>> saveCustomer(String uid, CustomerEntity customer);
}

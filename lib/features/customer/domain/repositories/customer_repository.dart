import 'package:dartz/dartz.dart';
import '../../domain/entities/customer_entity.dart';
import '../../../../core/error/failures.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<CustomerEntity>>> getCustomers(String uid);
  Future<Either<Failure, void>> saveCustomer(String uid, CustomerEntity customer);
}

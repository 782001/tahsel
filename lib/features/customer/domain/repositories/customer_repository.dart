import 'package:dartz/dartz.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/customer_operation.dart';
import '../../../../core/error/failures.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<CustomerEntity>>> getCustomers(String uid);
  Future<Either<Failure, void>> saveCustomer(String uid, CustomerEntity customer);
  Future<Either<Failure, void>> updateCustomerPhone(String uid, String name, String phoneNumber);
  Future<Either<Failure, void>> updateCustomerPreference(String uid, String name, String preference);
  Future<Either<Failure, List<CustomerOperation>>> getCustomerOperations(String uid, String customerName);
}

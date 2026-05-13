import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/customer_operation.dart';
import '../../../../core/error/failures.dart';

abstract class CustomerRepository {
  Future<Either<Failure, (List<CustomerEntity>, DocumentSnapshot?)>>
  getCustomers(String uid, {int limit = 15, DocumentSnapshot? lastDoc});

  Future<Either<Failure, void>> saveCustomer(
    String uid,
    CustomerEntity customer,
  );
  Future<Either<Failure, void>> updateCustomerPhone(
    String uid,
    String name,
    String phoneNumber,
  );
  Future<Either<Failure, void>> updateCustomerPreference(
    String uid,
    String name,
    String preference,
  );
  Future<Either<Failure, (List<CustomerOperation>, DocumentSnapshot?)>>
  getCustomerOperations(
    String uid,
    String customerName, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
}

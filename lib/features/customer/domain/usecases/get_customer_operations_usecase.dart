import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_operation.dart';
import '../repositories/customer_repository.dart';

class GetCustomerOperationsUseCase {
  final CustomerRepository repository;

  GetCustomerOperationsUseCase(this.repository);

  Future<
    Either<
      Failure,
      (List<CustomerOperation>, DocumentSnapshot?, double, double)
    >
  >
  call({
    required String uid,
    required String customerName,
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    return await repository.getCustomerOperations(
      uid,
      customerName,
      limit: limit,
      lastDoc: lastDoc,
    );
  }
}

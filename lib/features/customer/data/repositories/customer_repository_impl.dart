import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/customer_operation.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';
import '../models/customer_model.dart';
import '../../../../core/error/failures.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, (List<CustomerEntity>, DocumentSnapshot?)>>
  getCustomers(String uid, {int limit = 15, DocumentSnapshot? lastDoc}) async {
    try {
      final result = await remoteDataSource.getCustomers(
        uid,
        limit: limit,
        lastDoc: lastDoc,
      );
      return Right((
        result['customers'] as List<CustomerEntity>,
        result['lastDoc'] as DocumentSnapshot?,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCustomer(
    String uid,
    CustomerEntity customer,
  ) async {
    try {
      await remoteDataSource.saveCustomer(
        uid,
        CustomerModel.fromEntity(customer),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomerPhone(
    String uid,
    String name,
    String phoneNumber,
  ) async {
    try {
      await remoteDataSource.updateCustomerPhone(uid, name, phoneNumber);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomerPreference(
    String uid,
    String name,
    String preference,
  ) async {
    try {
      await remoteDataSource.updateCustomerPreference(uid, name, preference);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<
    Either<
      Failure,
      (List<CustomerOperation>, DocumentSnapshot?, double, double)
    >
  >
  getCustomerOperations(
    String uid,
    String customerName, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final result = await remoteDataSource.getCustomerOperations(
        uid,
        customerName,
        limit: limit,
        lastDoc: lastDoc,
      );
      return Right((
        result['operations'] as List<CustomerOperation>,
        result['lastDoc'] as DocumentSnapshot?,
        (result['totalSpent'] as num? ?? 0.0).toDouble(),
        (result['totalPaid'] as num? ?? 0.0).toDouble(),
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

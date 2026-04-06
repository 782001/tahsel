import 'package:dartz/dartz.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<dynamic, List<CustomerEntity>>> getCustomers(String uid) async {
    try {
      final customers = await remoteDataSource.getCustomers(uid);
      return Right(customers);
    } catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<dynamic, void>> saveCustomer(String uid, CustomerEntity customer) async {
    try {
      await remoteDataSource.saveCustomer(uid, CustomerModel.fromEntity(customer));
      return const Right(null);
    } catch (e) {
      return Left(e);
    }
  }
}

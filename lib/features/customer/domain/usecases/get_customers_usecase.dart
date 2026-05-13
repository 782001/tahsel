import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/customer_repository.dart';
import '../entities/customer_entity.dart';

class GetCustomersParams {
  final String uid;
  final int limit;
  final DocumentSnapshot? lastDoc;

  GetCustomersParams({required this.uid, this.limit = 15, this.lastDoc});
}

class GetCustomersUseCase
    implements
        BaseUseCase<(List<CustomerEntity>, DocumentSnapshot?),
            GetCustomersParams> {
  final CustomerRepository repository;

  GetCustomersUseCase(this.repository);

  @override
  Future<Either<Failure, (List<CustomerEntity>, DocumentSnapshot?)>> call(
    GetCustomersParams params,
  ) {
    return repository.getCustomers(
      params.uid,
      limit: params.limit,
      lastDoc: params.lastDoc,
    );
  }
}

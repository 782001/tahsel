import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/customer_repository.dart';
import '../entities/customer_entity.dart';

class GetCustomersParams {
  final String uid;

  GetCustomersParams({required this.uid});
}

class GetCustomersUseCase
    implements BaseUseCase<List<CustomerEntity>, GetCustomersParams> {
  final CustomerRepository repository;

  GetCustomersUseCase(this.repository);

  @override
  Future<Either<Failure, List<CustomerEntity>>> call(
    GetCustomersParams params,
  ) {
    return repository.getCustomers(params.uid);
  }
}

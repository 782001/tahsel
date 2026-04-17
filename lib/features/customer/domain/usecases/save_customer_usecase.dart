import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/customer_repository.dart';
import '../entities/customer_entity.dart';

class SaveCustomerParams {
  final String uid;
  final CustomerEntity customer;

  SaveCustomerParams({required this.uid, required this.customer});
}

class SaveCustomerUseCase implements BaseUseCase<void, SaveCustomerParams> {
  final CustomerRepository repository;

  SaveCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveCustomerParams params) {
    return repository.saveCustomer(params.uid, params.customer);
  }
}

import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerPhoneUseCase implements BaseUseCase<void, UpdateCustomerPhoneParams> {
  final CustomerRepository repository;

  UpdateCustomerPhoneUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateCustomerPhoneParams params) async {
    return await repository.updateCustomerPhone(params.uid, params.name, params.phoneNumber);
  }
}

class UpdateCustomerPhoneParams {
  final String uid;
  final String name;
  final String phoneNumber;

  UpdateCustomerPhoneParams({
    required this.uid,
    required this.name,
    required this.phoneNumber,
  });
}

import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerParams {
  final String uid;
  final String? customerId;
  final String name;
  final String? phoneNumber;
  final String? ledgerNumber;
  final String? taxNumber;
  final String? commercialRegistration;

  UpdateCustomerParams({
    required this.uid,
    this.customerId,
    required this.name,
    this.phoneNumber,
    this.ledgerNumber,
    this.taxNumber,
    this.commercialRegistration,
  });
}

class UpdateCustomerUseCase
    implements BaseUseCase<void, UpdateCustomerParams> {
  final CustomerRepository repository;

  UpdateCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateCustomerParams params) async {
    return await repository.updateCustomerDetails(
      params.uid,
      customerId: params.customerId,
      name: params.name,
      phoneNumber: params.phoneNumber,
      ledgerNumber: params.ledgerNumber,
      taxNumber: params.taxNumber,
      commercialRegistration: params.commercialRegistration,
    );
  }
}

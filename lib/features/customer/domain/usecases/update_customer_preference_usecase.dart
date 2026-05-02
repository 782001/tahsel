import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerPreferenceUseCase
    implements BaseUseCase<void, UpdateCustomerPreferenceParams> {
  final CustomerRepository repository;

  UpdateCustomerPreferenceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    UpdateCustomerPreferenceParams params,
  ) async {
    return await repository.updateCustomerPreference(
      params.uid,
      params.name,
      params.preference,
    );
  }
}

class UpdateCustomerPreferenceParams {
  final String uid;
  final String name;
  final String preference;

  UpdateCustomerPreferenceParams({
    required this.uid,
    required this.name,
    required this.preference,
  });
}

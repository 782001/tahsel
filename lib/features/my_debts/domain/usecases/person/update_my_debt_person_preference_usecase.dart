import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class UpdateMyDebtPersonPreferenceUseCase {
  final MyDebtRepository repository;

  UpdateMyDebtPersonPreferenceUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String uid,
    String name,
    String preference,
  ) async {
    return await repository.updateMyDebtPersonPreference(uid, name, preference);
  }
}

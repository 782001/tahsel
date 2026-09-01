import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debt_repository.dart';

class UpdateDebtDueDateUseCase
    implements BaseUseCase<void, UpdateDebtDueDateParams> {
  final DebtRepository repository;

  UpdateDebtDueDateUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(UpdateDebtDueDateParams params) async {
    return await repository.updateDebtDueDate(
      uid: params.uid,
      debtId: params.debtId,
      dueDate: params.dueDate,
    );
  }
}

class UpdateDebtDueDateParams {
  final String uid;
  final String debtId;
  final DateTime? dueDate;

  const UpdateDebtDueDateParams({
    required this.uid,
    required this.debtId,
    required this.dueDate,
  });
}

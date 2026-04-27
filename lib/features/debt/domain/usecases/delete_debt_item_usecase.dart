import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debt_repository.dart';

class DeleteDebtItemUseCase implements BaseUseCase<void, DeleteDebtItemParams> {
  final DebtRepository repository;

  DeleteDebtItemUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(DeleteDebtItemParams params) {
    return repository.deleteDebtItem(params.uid, params.debtId);
  }
}

class DeleteDebtItemParams {
  final String uid;
  final String debtId;

  DeleteDebtItemParams({required this.uid, required this.debtId});
}

import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../offline_sync/data/models/offline_record.dart';
import '../repositories/expense_repository.dart';

class GetPendingExpensesUseCase
    implements BaseUseCase<List<OfflineRecord>, NoParams> {
  final ExpenseRepository repository;

  GetPendingExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<OfflineRecord>>> call(NoParams params) async {
    return await repository.getPendingExpenses();
  }
}

import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';

class GetPendingMyDebtsUseCase
    implements BaseUseCase<List<OfflineRecord>, NoParams> {
  final MyDebtRepository repository;

  GetPendingMyDebtsUseCase(this.repository);

  @override
  Future<Either<Failure, List<OfflineRecord>>> call(NoParams params) async {
    return await repository.getPendingMyDebts();
  }
}

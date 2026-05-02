import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

import '../../../../core/base_usecase/base_usecase.dart';

class GetDebtTransactionsFutureUseCase
    implements BaseUseCase<List<PaymentEntity>, GetDebtTransactionsParams> {
  final DebtRepository repository;

  GetDebtTransactionsFutureUseCase(this.repository);

  @override
  Future<Either<Failure, List<PaymentEntity>>> call(
    GetDebtTransactionsParams params,
  ) async {
    return await repository.getDebtTransactionsFuture(
      params.debtId,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetDebtTransactionsParams {
  final String debtId;
  final bool forceRefresh;
  GetDebtTransactionsParams({required this.debtId, this.forceRefresh = false});
}

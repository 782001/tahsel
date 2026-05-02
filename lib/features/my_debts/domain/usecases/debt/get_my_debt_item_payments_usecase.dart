import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

import 'package:tahsel/core/base_usecase/base_usecase.dart';

class GetMyDebtItemPaymentsUseCase
    implements BaseUseCase<List<PaymentEntity>, GetMyDebtItemPaymentsParams> {
  final MyDebtRepository repository;

  GetMyDebtItemPaymentsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<PaymentEntity>>> call(
    GetMyDebtItemPaymentsParams params,
  ) async {
    return await repository.getMyDebtItemPayments(
      params.uid,
      params.debtId,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetMyDebtItemPaymentsParams {
  final String uid;
  final String debtId;
  final bool forceRefresh;
  GetMyDebtItemPaymentsParams({
    required this.uid,
    required this.debtId,
    this.forceRefresh = false,
  });
}

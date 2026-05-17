import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtItemPaymentsPaginatedUseCase
    implements BaseUseCase<PaginatedResult<PaymentEntity>, GetMyDebtItemPaymentsPaginatedParams> {
  final MyDebtRepository repository;

  GetMyDebtItemPaymentsPaginatedUseCase({required this.repository});

  @override
  Future<Either<Failure, PaginatedResult<PaymentEntity>>> call(
    GetMyDebtItemPaymentsPaginatedParams params,
  ) async {
    return await repository.getMyDebtItemPaymentsPaginated(
      params.uid,
      params.debtId,
      limit: params.limit,
      lastDocument: params.lastDocument,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetMyDebtItemPaymentsPaginatedParams {
  final String uid;
  final String debtId;
  final int limit;
  final DocumentSnapshot? lastDocument;
  final bool forceRefresh;

  GetMyDebtItemPaymentsPaginatedParams({
    required this.uid,
    required this.debtId,
    this.limit = 15,
    this.lastDocument,
    this.forceRefresh = false,
  });
}

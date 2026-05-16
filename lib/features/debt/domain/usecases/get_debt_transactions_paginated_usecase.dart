import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/pagination_params.dart';
import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebtTransactionsPaginatedUseCase {
  final DebtRepository repository;

  GetDebtTransactionsPaginatedUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<PaymentEntity>>> call({
    required String uid,
    required String debtId,
    int limit = 15,
    DocumentSnapshot? lastDocument,
  }) async {
    return await repository.getDebtTransactionsPaginated(
      uid,
      debtId,
      limit: limit,
      lastDocument: lastDocument,
    );
  }
}

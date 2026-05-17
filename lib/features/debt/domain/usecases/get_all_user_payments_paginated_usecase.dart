import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/pagination_params.dart';
import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

class GetAllUserPaymentsPaginatedUseCase {
  final DebtRepository repository;

  GetAllUserPaymentsPaginatedUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<PaymentEntity>>> call({
    required String uid,
    int limit = 15,
    DocumentSnapshot? lastDocument,
    int? month,
    int? year,
  }) async {
    return await repository.getAllUserPaymentsPaginated(
      uid,
      limit: limit,
      lastDocument: lastDocument,
      month: month,
      year: year,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/pagination_params.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebtsPaginatedUseCase {
  final DebtRepository repository;

  GetDebtsPaginatedUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<DebtEntity>>> call({
    required String uid,
    int limit = 15,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
    String filter = 'all',
  }) async {
    return await repository.getDebtsPaginated(
      uid,
      limit: limit,
      lastDocument: lastDocument,
      forceRefresh: forceRefresh,
      filter: filter,
    );
  }
}

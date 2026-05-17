import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtPersonsPaginatedUseCase
    implements BaseUseCase<PaginatedResult<MyDebtPersonEntity>, GetMyDebtPersonsPaginatedParams> {
  final MyDebtRepository repository;

  GetMyDebtPersonsPaginatedUseCase({required this.repository});

  @override
  Future<Either<Failure, PaginatedResult<MyDebtPersonEntity>>> call(
    GetMyDebtPersonsPaginatedParams params,
  ) async {
    return await repository.getMyDebtPersonsPaginated(
      params.uid,
      limit: params.limit,
      lastDocument: params.lastDocument,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetMyDebtPersonsPaginatedParams {
  final String uid;
  final int limit;
  final DocumentSnapshot? lastDocument;
  final bool forceRefresh;

  GetMyDebtPersonsPaginatedParams({
    required this.uid,
    this.limit = 15,
    this.lastDocument,
    this.forceRefresh = false,
  });
}

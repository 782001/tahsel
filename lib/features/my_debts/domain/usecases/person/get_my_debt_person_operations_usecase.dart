import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtPersonOperationsUseCase
    implements
        BaseUseCase<
          List<MyDebtOperationEntity>,
          GetMyDebtPersonOperationsParams
        > {
  final MyDebtRepository repository;

  GetMyDebtPersonOperationsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<MyDebtOperationEntity>>> call(
    GetMyDebtPersonOperationsParams params,
  ) async {
    return await repository.getMyDebtPersonOperations(
      params.uid,
      params.personName,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetMyDebtPersonOperationsParams {
  final String uid;
  final String personName;
  final bool forceRefresh;
  GetMyDebtPersonOperationsParams({
    required this.uid,
    required this.personName,
    this.forceRefresh = false,
  });
}

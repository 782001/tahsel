import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtItemsUseCase
    implements BaseUseCase<List<MyDebtItemEntity>, GetMyDebtItemsParams> {
  final MyDebtRepository repository;

  GetMyDebtItemsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<MyDebtItemEntity>>> call(
    GetMyDebtItemsParams params,
  ) async {
    return await repository.getMyDebtItems(
      params.uid,
      params.personName,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetMyDebtItemsParams {
  final String uid;
  final String personName;
  final bool forceRefresh;
  GetMyDebtItemsParams({
    required this.uid,
    required this.personName,
    this.forceRefresh = false,
  });
}

import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtPersonsUseCase
    implements BaseUseCase<List<MyDebtPersonEntity>, GetMyDebtPersonsParams> {
  final MyDebtRepository repository;

  GetMyDebtPersonsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<MyDebtPersonEntity>>> call(
    GetMyDebtPersonsParams params,
  ) async {
    return await repository.getMyDebtPersons(
      params.uid,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetMyDebtPersonsParams {
  final String uid;
  final bool forceRefresh;
  GetMyDebtPersonsParams({required this.uid, this.forceRefresh = false});
}

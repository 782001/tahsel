import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

import '../../../../core/error/failures.dart';

class GetDebtsUseCase implements BaseUseCase<List<DebtEntity>, GetDebtsParams> {
  final DebtRepository repository;

  GetDebtsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<DebtEntity>>> call(GetDebtsParams params) async {
    return await repository.getDebts(params.uid);
  }
}

class GetDebtsParams {
  final String uid;
  GetDebtsParams({required this.uid});
}

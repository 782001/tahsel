import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class AddDebtUseCase implements BaseUseCase<String, AddDebtParams> {
  final DebtRepository repository;

  AddDebtUseCase({required this.repository});

  @override
  Future<Either<dynamic, String>> call(AddDebtParams params) async {
    return await repository.addDebt(params.debt);
  }
}

class AddDebtParams {
  final DebtEntity debt;
  AddDebtParams({required this.debt});
}

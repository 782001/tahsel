import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../operation/domain/entities/operation_entity.dart';
import '../repositories/reports_repository.dart';

class GetIncomeDetailsParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? type;

  GetIncomeDetailsParams({required this.startDate, required this.endDate, this.type});
}

class GetIncomeDetailsUseCase implements BaseUseCase<List<OperationEntity>, GetIncomeDetailsParams> {
  final ReportsRepository repository;

  GetIncomeDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, List<OperationEntity>>> call(GetIncomeDetailsParams params) {
    return repository.getIncomeDetails(params.startDate, params.endDate, type: params.type);
  }
}

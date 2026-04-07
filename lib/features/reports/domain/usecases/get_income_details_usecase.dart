import 'package:dartz/dartz.dart';
import '../../../operation/domain/entities/operation_entity.dart';
import '../repositories/reports_repository.dart';

class GetIncomeDetailsUseCase {
  final ReportsRepository repository;

  GetIncomeDetailsUseCase(this.repository);

  Future<Either<String, List<OperationEntity>>> call(DateTime startDate, DateTime endDate, {String? type}) {
    return repository.getIncomeDetails(startDate, endDate, type: type);
  }
}

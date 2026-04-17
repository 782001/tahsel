import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/reports_entity.dart';
import '../repositories/reports_repository.dart';

class GetReportsParams {
  final DateTime startDate;
  final DateTime endDate;

  GetReportsParams({required this.startDate, required this.endDate});
}

class GetReportsUseCase implements BaseUseCase<ReportsEntity, GetReportsParams> {
  final ReportsRepository repository;

  GetReportsUseCase(this.repository);

  @override
  Future<Either<Failure, ReportsEntity>> call(GetReportsParams params) {
    return repository.getReports(params.startDate, params.endDate);
  }
}

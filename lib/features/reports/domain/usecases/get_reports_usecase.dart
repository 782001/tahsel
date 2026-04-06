import 'package:dartz/dartz.dart';
import '../entities/reports_entity.dart';
import '../repositories/reports_repository.dart';

class GetReportsUseCase {
  final ReportsRepository repository;

  GetReportsUseCase(this.repository);

  Future<Either<String, ReportsEntity>> call(DateTime startDate, DateTime endDate) {
    return repository.getReports(startDate, endDate);
  }
}

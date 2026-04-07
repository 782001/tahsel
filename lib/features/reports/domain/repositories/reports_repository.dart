import 'package:dartz/dartz.dart';
import '../entities/reports_entity.dart';
import '../../../operation/domain/entities/operation_entity.dart';

abstract class ReportsRepository {
  Future<Either<String, ReportsEntity>> getReports(DateTime startDate, DateTime endDate);
  Future<Either<String, List<OperationEntity>>> getIncomeDetails(DateTime startDate, DateTime endDate, {String? type});
}

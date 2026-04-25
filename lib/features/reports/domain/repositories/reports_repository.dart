import 'package:dartz/dartz.dart';
import '../entities/reports_entity.dart';
import '../../../operation/domain/entities/operation_entity.dart';
import '../../../../core/error/failures.dart';

abstract class ReportsRepository {
  Future<Either<Failure, ReportsEntity>> getReports(DateTime startDate, DateTime endDate);
  Future<Either<Failure, ReportsEntity>> getAllTimeReports();
  Future<Either<Failure, List<OperationEntity>>> getIncomeDetails(DateTime startDate, DateTime endDate, {String? type});
  Future<Either<Failure, int>> cleanupOldReports();
}

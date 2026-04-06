import 'package:dartz/dartz.dart';
import '../entities/reports_entity.dart';

abstract class ReportsRepository {
  Future<Either<String, ReportsEntity>> getReports(DateTime startDate, DateTime endDate);
}

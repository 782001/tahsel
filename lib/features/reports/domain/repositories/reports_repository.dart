import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../entities/reports_entity.dart';
import '../../../operation/domain/entities/operation_entity.dart';
import '../../../../core/error/failures.dart';

abstract class ReportsRepository {
  Future<Either<Failure, ReportsEntity>> getReports(
    DateTime startDate,
    DateTime endDate,
    String periodKey, {
    bool forceRefresh = false,
  });
  Future<Either<Failure, ReportsEntity>> getAllTimeReports({bool forceRefresh = false});
  Future<Either<Failure, (List<OperationEntity>, DocumentSnapshot?)>> getIncomeDetails(
    DateTime startDate,
    DateTime endDate, {
    String? type,
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
  Future<Either<Failure, int>> cleanupOldReports();
}

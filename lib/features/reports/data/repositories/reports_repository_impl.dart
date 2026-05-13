import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:tahsel/core/utils/app_logger.dart';

import '../../../../core/error/failures.dart';
import '../../../operation/data/models/operation_model.dart';
import '../../../operation/domain/entities/operation_entity.dart';
import '../../domain/entities/reports_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_data_source.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource dataSource;

  ReportsRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, ReportsEntity>> getReports(
    DateTime startDate,
    DateTime endDate,
    String periodKey, {
    bool forceRefresh = false,
  }) async {
    try {
      // 1. Fetch Current Period Data
      final currentData = await dataSource.getPeriodData(
        startDate,
        endDate,
        periodKey,
        forceRefresh: forceRefresh,
      );

      // 2. Fetch Previous Period Data for Comparison
      final duration = endDate.difference(startDate);
      final prevStartDate = startDate.subtract(duration);
      final prevEndDate = endDate.subtract(duration);

      // Note: We use the same periodKey for comparison data
      // We don't necessarily need forceRefresh for the previous period unless the user specifically wants it,
      // but for consistency we'll use it if passed.
      final prevData = await dataSource.getPeriodData(
        prevStartDate,
        prevEndDate,
        periodKey,
        forceRefresh: forceRefresh,
      );

      // Mapping keys from DataSource to Entity
      // Consistent keys: totalIncome, cafeIncome, playstationIncome, totalExpenses, totalDebts, paidDebts, unpaidDebts
      
      // Current Data
      final double currentIncome = (currentData['totalIncome'] ?? 0).toDouble();
      final double currentCafeIncome = (currentData['cafeIncome'] ?? 0).toDouble();
      final double currentPlaystationIncome = (currentData['playstationIncome'] ?? 0).toDouble();
      final double currentExpenses = (currentData['totalExpenses'] ?? 0).toDouble();
      final double currentTotalDebts = (currentData['totalDebts'] ?? 0).toDouble();
      final double currentPaidDebts = (currentData['paidDebts'] ?? 0).toDouble();
      final double currentUnpaidDebts = (currentData['unpaidDebts'] ?? 0).toDouble();
      final int currentTotalCount = (currentData['totalCount'] ?? 0).toInt();
      final int currentCafeCount = (currentData['cafeCount'] ?? 0).toInt();
      final int currentPSCount = (currentData['playstationCount'] ?? 0).toInt();
      final double currentProfit = currentIncome - currentExpenses;

      // Previous Data
      final double prevIncome = (prevData['totalIncome'] ?? 0).toDouble();
      final double prevCafeIncome = (prevData['cafeIncome'] ?? 0).toDouble();
      final double prevPlaystationIncome = (prevData['playstationIncome'] ?? 0).toDouble();
      final double prevExpenses = (prevData['totalExpenses'] ?? 0).toDouble();
      final double prevProfit = prevIncome - prevExpenses;

      final double incomeDiff = currentIncome - prevIncome;
      final double expenseDiff = currentExpenses - prevExpenses;
      final double profitDiff = currentProfit - prevProfit;
      final double cafeDiff = currentCafeIncome - prevCafeIncome;
      final double psDiff = currentPlaystationIncome - prevPlaystationIncome;

      final reports = ReportsEntity(
        totalIncome: currentIncome,
        cafeIncome: currentCafeIncome,
        playstationIncome: currentPlaystationIncome,
        totalExpenses: currentExpenses,
        totalDebts: currentTotalDebts,
        paidDebts: currentPaidDebts,
        unpaidDebts: currentUnpaidDebts,
        netProfit: currentProfit,
        totalCount: currentTotalCount,
        cafeCount: currentCafeCount,
        playstationCount: currentPSCount,
        prevIncome: prevIncome,
        prevExpenses: prevExpenses,
        prevCafeIncome: prevCafeIncome,
        prevPlaystationIncome: prevPlaystationIncome,
        incomeDiff: incomeDiff.abs(),
        expenseDiff: expenseDiff.abs(),
        profitDiff: profitDiff.abs(),
        cafeDiff: cafeDiff.abs(),
        playstationDiff: psDiff.abs(),
        isIncomeIncrease: incomeDiff >= 0,
        isExpenseIncrease: expenseDiff >= 0,
        isProfitIncrease: profitDiff >= 0,
        isCafeIncrease: cafeDiff >= 0,
        isPlaystationIncrease: psDiff >= 0,
      );

      return Right(reports);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReportsEntity>> getAllTimeReports({bool forceRefresh = false}) async {
    try {
      final data = await dataSource.getAllTimeData(forceRefresh: forceRefresh);

      final double income = (data['totalIncome'] ?? 0).toDouble();
      final double cafeIncome = (data['cafeIncome'] ?? 0).toDouble();
      final double playstationIncome = (data['playstationIncome'] ?? 0).toDouble();
      final double expenses = (data['totalExpenses'] ?? 0).toDouble();
      final double totalDebts = (data['totalDebts'] ?? 0).toDouble();
      final double paidDebts = (data['paidDebts'] ?? 0).toDouble();
      final double unpaidDebts = (data['unpaidDebts'] ?? 0).toDouble();
      final int totalCount = (data['totalCount'] ?? 0).toInt();
      final int cafeCount = (data['cafeCount'] ?? 0).toInt();
      final int psCount = (data['playstationCount'] ?? 0).toInt();
      final double profit = income - expenses;

      final reports = ReportsEntity(
        totalIncome: income,
        cafeIncome: cafeIncome,
        playstationIncome: playstationIncome,
        totalExpenses: expenses,
        totalDebts: totalDebts,
        paidDebts: paidDebts,
        unpaidDebts: unpaidDebts,
        netProfit: profit,
        totalCount: totalCount,
        cafeCount: cafeCount,
        playstationCount: psCount,
        // No comparison for all-time aggregation
        incomeDiff: 0,
        expenseDiff: 0,
        profitDiff: 0,
        cafeDiff: 0,
        playstationDiff: 0,
        isIncomeIncrease: true,
        isExpenseIncrease: false,
        isProfitIncrease: true,
      );

      return Right(reports);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, (List<OperationEntity>, DocumentSnapshot?)>> getIncomeDetails(
    DateTime startDate,
    DateTime endDate, {
    String? type,
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final results = await dataSource.getIncomeDetails(
        startDate,
        endDate,
        type: type,
        limit: limit,
        lastDoc: lastDoc,
      );

      final List<OperationEntity> operations = results.map((result) {
        final data = result['data'] as Map<String, dynamic>;
        final id = data['id'] as String;
        return OperationModel.fromJson(data, id);
      }).toList();

      final DocumentSnapshot? lastSnapshot = results.isNotEmpty 
          ? results.last['snapshot'] as DocumentSnapshot 
          : null;

      return Right((operations, lastSnapshot));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> cleanupOldReports() async {
    try {
      final startTime = DateTime.now();
      final deletedCount = await dataSource.cleanupOldReports();
      final endTime = DateTime.now();

      final duration = endTime.difference(startTime).inMilliseconds;
      // Logging the result
      AppLogger.printMessage(
        'Cleanup executed in ${duration}ms. Deleted $deletedCount records.',
      );

      return Right(deletedCount);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

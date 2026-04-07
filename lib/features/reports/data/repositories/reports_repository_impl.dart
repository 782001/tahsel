import 'package:dartz/dartz.dart';
import '../../domain/entities/reports_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_data_source.dart';
import '../../../operation/data/models/operation_model.dart';
import '../../../operation/domain/entities/operation_entity.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource dataSource;

  ReportsRepositoryImpl(this.dataSource);

  @override
  Future<Either<String, ReportsEntity>> getReports(DateTime startDate, DateTime endDate) async {
    try {
      // 1. Fetch Current Period Data
      final currentData = await dataSource.getPeriodData(startDate, endDate);

      // 2. Fetch Previous Period Data for Comparison
      final duration = endDate.difference(startDate);
      final prevStartDate = startDate.subtract(duration);
      final prevEndDate = endDate.subtract(duration);

      final prevData = await dataSource.getPeriodData(prevStartDate, prevEndDate);

      // Current Data
      final double currentIncome = (currentData['income'] ?? 0).toDouble();
      final double currentCafeIncome = (currentData['cafeIncome'] ?? 0).toDouble();
      final double currentPlaystationIncome = (currentData['playstationIncome'] ?? 0).toDouble();
      final double currentExpenses = (currentData['expenses'] ?? 0).toDouble();
      final double currentTotalDebts = (currentData['totalDebts'] ?? 0).toDouble();
      final double currentPaidDebts = (currentData['paidDebts'] ?? 0).toDouble();
      final double currentUnpaidDebts = (currentData['unpaidDebts'] ?? 0).toDouble();
      final double currentProfit = currentIncome - currentExpenses;

      // Previous Data
      final double prevIncome = (prevData['income'] ?? 0).toDouble();
      final double prevCafeIncome = (prevData['cafeIncome'] ?? 0).toDouble();
      final double prevPlaystationIncome = (prevData['playstationIncome'] ?? 0).toDouble();
      final double prevExpenses = (prevData['expenses'] ?? 0).toDouble();
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
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<OperationEntity>>> getIncomeDetails(
      DateTime startDate, DateTime endDate,
      {String? type}) async {
    try {
      final results = await dataSource.getIncomeDetails(startDate, endDate, type: type);
      final List<OperationEntity> operations = results.map((data) {
        final id = data['id'] as String;
        return OperationModel.fromJson(data, id);
      }).toList();
      return Right(operations);
    } catch (e) {
      return Left(e.toString());
    }
  }
}

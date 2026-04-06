import 'package:dartz/dartz.dart';
import '../../domain/entities/reports_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_data_source.dart';

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

      // Calculations
      final currentIncome = currentData['income'] ?? 0;
      final currentExpenses = currentData['expenses'] ?? 0;
      final currentTotalDebts = currentData['totalDebts'] ?? 0;
      final currentPaidDebts = currentData['paidDebts'] ?? 0;
      final currentUnpaidDebts = currentData['unpaidDebts'] ?? 0;
      final currentProfit = currentIncome - currentExpenses;

      final prevIncome = prevData['income'] ?? 0;
      final prevExpenses = prevData['expenses'] ?? 0;
      final prevProfit = prevIncome - prevExpenses;

      // Percentages calculation
      double _calcPercUpdate(double current, double prev) {
        if (prev == 0) return current > 0 ? 100 : 0;
        return ((current - prev) / prev) * 100;
      }

      final incomePerc = _calcPercUpdate(currentIncome, prevIncome);
      final expensePerc = _calcPercUpdate(currentExpenses, prevExpenses);
      final profitPerc = _calcPercUpdate(currentProfit, prevProfit);

      final reports = ReportsEntity(
        totalIncome: currentIncome,
        totalExpenses: currentExpenses,
        totalDebts: currentTotalDebts,
        paidDebts: currentPaidDebts,
        unpaidDebts: currentUnpaidDebts,
        netProfit: currentProfit,
        incomePercentage: incomePerc.abs(),
        expensePercentage: expensePerc.abs(),
        profitPercentage: profitPerc.abs(),
        isIncomeIncrease: incomePerc >= 0,
        isExpenseIncrease: expensePerc >= 0,
        isProfitIncrease: profitPerc >= 0,
      );

      return Right(reports);
    } catch (e) {
      return Left(e.toString());
    }
  }
}

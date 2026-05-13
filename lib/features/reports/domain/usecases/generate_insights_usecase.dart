import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/reports_entity.dart';
import '../entities/profit_insight.dart';

class GenerateInsightsParams {
  final ReportsEntity reports;
  final ReportPeriod period;

  GenerateInsightsParams({required this.reports, required this.period});
}

class GenerateInsightsUseCase
    implements BaseUseCase<List<ProfitInsight>, GenerateInsightsParams> {
  @override
  Future<Either<Failure, List<ProfitInsight>>> call(
    GenerateInsightsParams params,
  ) async {
    if (params.period == ReportPeriod.allTime) {
      return const Right([]); // Pure aggregation, no insights for all-time
    }

    final List<ProfitInsight> insights = [];

    // 1. Net Profit Analysis (Growth Trend)
    insights.add(_getNetProfitTrendInsight(params.reports, params.period));

    // 2. Extra Smart Insights
    final incomeInsight = _getIncomeTrendInsight(params.reports);
    if (incomeInsight != null) insights.add(incomeInsight);

    final expenseInsight = _getExpenseTrendInsight(params.reports);
    if (expenseInsight != null) insights.add(expenseInsight);

    final contributionInsight = _getContributionInsight(params.reports);
    if (contributionInsight != null) insights.add(contributionInsight);

    return Right(insights);
  }

  // Pure logic for profit growth analysis
  ProfitInsight _getNetProfitTrendInsight(
    ReportsEntity reports,
    ReportPeriod period,
  ) {
    final currentProfit = reports.totalIncome - reports.totalExpenses;
    final prevProfit = reports.prevIncome - reports.prevExpenses;

    final double difference = (currentProfit - prevProfit).abs();

    // Edge case: No data yet
    if (reports.totalIncome == 0 && reports.prevIncome == 0) {
      return const ProfitInsight(
        status: ProfitInsightStatus.none,
        difference: 0,
        currentValue: 0,
        previousValue: 0,
        netProfit: 0,
        messageKey: 'insight_no_previous_data',
      );
    }

    // Case 1: Break-even (Net Profit is exactly 0)
    if (currentProfit == 0 && reports.totalIncome > 0) {
      return const ProfitInsight(
        status: ProfitInsightStatus.none,
        difference: 0,
        currentValue: 0,
        previousValue: 0,
        netProfit: 0,
        messageKey: 'insight_profit_zero',
      );
    }

    // Case 2: Same Profit as previous (within 1 EGP margin)
    if (difference < 1.0) {
      String key;
      switch (period) {
        case ReportPeriod.daily:
          key = 'insight_profit_same_daily';
          break;
        case ReportPeriod.weekly:
          key = 'insight_profit_same_weekly';
          break;
        case ReportPeriod.monthly:
          key = 'insight_profit_same_monthly';
          break;
        case ReportPeriod.allTime:
          key = 'insight_profit_same_general';
          break; // Placeholder or general key
      }
      return ProfitInsight(
        status: ProfitInsightStatus.same,
        difference: 0,
        currentValue: currentProfit,
        previousValue: prevProfit,
        netProfit: currentProfit,
        messageKey: key,
      );
    }

    // Determine Prefix/Suffix based on period
    String keyPrefix = 'insight_profit_';
    switch (period) {
      case ReportPeriod.daily:
        keyPrefix += 'daily_';
        break;
      case ReportPeriod.weekly:
        keyPrefix += 'weekly_';
        break;
      case ReportPeriod.monthly:
        keyPrefix += 'monthly_';
        break;
      case ReportPeriod.allTime:
        keyPrefix += 'general_';
        break;
    }

    if (currentProfit > prevProfit) {
      return ProfitInsight(
        status: ProfitInsightStatus.increase,
        difference: difference,
        currentValue: currentProfit,
        previousValue: prevProfit,
        netProfit: currentProfit,
        messageKey: '${keyPrefix}increase',
      );
    } else {
      return ProfitInsight(
        status: ProfitInsightStatus.loss,
        difference: difference,
        currentValue: currentProfit,
        previousValue: prevProfit,
        netProfit: currentProfit,
        messageKey: '${keyPrefix}decrease',
      );
    }
  }

  ProfitInsight? _getIncomeTrendInsight(ReportsEntity reports) {
    if (reports.totalIncome > reports.prevIncome) {
      final cafeIncrease = reports.cafeIncome - reports.prevCafeIncome;
      final psIncrease =
          reports.playstationIncome - reports.prevPlaystationIncome;

      if (cafeIncrease > psIncrease && cafeIncrease > 0) {
        return ProfitInsight(
          status: ProfitInsightStatus.increase,
          difference: cafeIncrease.abs(),
          currentValue: reports.cafeIncome,
          previousValue: reports.prevCafeIncome,
          netProfit: 0,
          messageKey: 'insight_income_up_cafe',
        );
      } else if (psIncrease > cafeIncrease && psIncrease > 0) {
        return ProfitInsight(
          status: ProfitInsightStatus.increase,
          difference: psIncrease.abs(),
          currentValue: reports.playstationIncome,
          previousValue: reports.prevPlaystationIncome,
          netProfit: 0,
          messageKey: 'insight_income_up_ps',
        );
      }
    }
    return null;
  }

  ProfitInsight? _getExpenseTrendInsight(ReportsEntity reports) {
    if (reports.totalExpenses > reports.prevExpenses) {
      final expenseIncrease = reports.totalExpenses - reports.prevExpenses;
      if (expenseIncrease > 100) {
        // Threshold for "high" increase
        return ProfitInsight(
          status: ProfitInsightStatus.loss,
          difference: expenseIncrease.abs(),
          currentValue: reports.totalExpenses,
          previousValue: reports.prevExpenses,
          netProfit: 0,
          messageKey: 'insight_expenses_up_high',
        );
      }
    }
    return null;
  }

  ProfitInsight? _getContributionInsight(ReportsEntity reports) {
    if (reports.totalIncome > 0) {
      final psContribution = reports.playstationIncome / reports.totalIncome;
      if (psContribution < 0.3 && reports.playstationIncome > 0) {
        return ProfitInsight(
          status: ProfitInsightStatus.same,
          difference: reports.playstationIncome,
          currentValue: reports.playstationIncome,
          previousValue: 0, // Not a comparison per se
          netProfit: 0,
          messageKey: 'insight_ps_low_contribution',
        );
      }
    }
    return null;
  }
}

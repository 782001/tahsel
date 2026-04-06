import '../entities/reports_entity.dart';
import '../entities/profit_insight.dart';

class GenerateInsightsUseCase {
  List<ProfitInsight> call(ReportsEntity reports, ReportPeriod period) {
    final List<ProfitInsight> insights = [];

    // 1. Net Profit Analysis (Growth Trend)
    insights.add(_getNetProfitTrendInsight(reports, period));

    // 2. Extra Smart Insights
    final incomeInsight = _getIncomeTrendInsight(reports);
    if (incomeInsight != null) insights.add(incomeInsight);

    final expenseInsight = _getExpenseTrendInsight(reports);
    if (expenseInsight != null) insights.add(expenseInsight);

    final contributionInsight = _getContributionInsight(reports);
    if (contributionInsight != null) insights.add(contributionInsight);

    return insights;
  }

  // Pure logic for profit growth analysis
  ProfitInsight _getNetProfitTrendInsight(ReportsEntity reports, ReportPeriod period) {
    final currentProfit = reports.totalIncome - reports.totalExpenses;
    final prevProfit = reports.prevIncome - reports.prevExpenses;

    final double difference = (currentProfit - prevProfit).abs();

    // Edge case: No data yet
    if (reports.totalIncome == 0 && reports.prevIncome == 0) {
      return const ProfitInsight(
        status: ProfitInsightStatus.none,
        difference: 0,
        netProfit: 0,
        messageKey: 'insight_no_previous_data',
      );
    }

    // Case 1: Break-even (Net Profit is exactly 0)
    if (currentProfit == 0 && reports.totalIncome > 0) {
      return const ProfitInsight(
        status: ProfitInsightStatus.none,
        difference: 0,
        netProfit: 0,
        messageKey: 'insight_profit_zero',
      );
    }

    // Case 2: Same Profit as previous (within 1 EGP margin)
    if (difference < 1.0) {
      String key;
      switch (period) {
        case ReportPeriod.daily: key = 'insight_profit_same_daily'; break;
        case ReportPeriod.weekly: key = 'insight_profit_same_weekly'; break;
        case ReportPeriod.monthly: key = 'insight_profit_same_monthly'; break;
      }
      return ProfitInsight(
        status: ProfitInsightStatus.same,
        difference: 0,
        netProfit: currentProfit,
        messageKey: key,
      );
    }

    // Determine Prefix/Suffix based on period
    String keyPrefix = 'insight_profit_';
    switch (period) {
      case ReportPeriod.daily: keyPrefix += 'daily_'; break;
      case ReportPeriod.weekly: keyPrefix += 'weekly_'; break;
      case ReportPeriod.monthly: keyPrefix += 'monthly_'; break;
    }

    if (currentProfit > prevProfit) {
      return ProfitInsight(
        status: ProfitInsightStatus.increase,
        difference: difference,
        netProfit: currentProfit,
        messageKey: '${keyPrefix}increase',
      );
    } else {
      return ProfitInsight(
        status: ProfitInsightStatus.loss,
        difference: difference,
        netProfit: currentProfit,
        messageKey: '${keyPrefix}decrease',
      );
    }
  }

  ProfitInsight? _getIncomeTrendInsight(ReportsEntity reports) {
    if (reports.totalIncome > reports.prevIncome) {
      final cafeIncrease = reports.cafeIncome - reports.prevCafeIncome;
      final psIncrease = reports.playstationIncome - reports.prevPlaystationIncome;

      if (cafeIncrease > psIncrease && cafeIncrease > 0) {
        return ProfitInsight(
          status: ProfitInsightStatus.increase,
          difference: cafeIncrease.abs(),
          netProfit: 0,
          messageKey: 'insight_income_up_cafe',
        );
      } else if (psIncrease > cafeIncrease && psIncrease > 0) {
        return ProfitInsight(
          status: ProfitInsightStatus.increase,
          difference: psIncrease.abs(),
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
      if (expenseIncrease > 100) { // Threshold for "high" increase
        return ProfitInsight(
          status: ProfitInsightStatus.loss,
          difference: expenseIncrease.abs(),
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
          netProfit: 0,
          messageKey: 'insight_ps_low_contribution',
        );
      }
    }
    return null;
  }
}

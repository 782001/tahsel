import 'package:flutter_test/flutter_test.dart';
import 'package:tahsel/features/reports/domain/entities/profit_insight.dart';
import 'package:tahsel/features/reports/domain/entities/reports_entity.dart';
import 'package:tahsel/features/reports/domain/usecases/generate_insights_usecase.dart';
import 'package:tahsel/core/utils/app_strings.dart';

void main() {
  late GenerateInsightsUseCase useCase;

  setUp(() {
    useCase = GenerateInsightsUseCase();
  });

  group('GenerateInsightsUseCase Tests', () {
    test('Profit Increase: should include primary profit insight with positive percentage', () {
      final reports = ReportsEntity(
        totalIncome: 500,
        totalExpenses: 300,
        netProfit: 200,
        totalDebts: 0,
        paidDebts: 0,
        unpaidDebts: 0,
        prevIncome: 400,
        prevExpenses: 300, // Prev Profit: 100
        cafeIncome: 250,
        playstationIncome: 250,
        prevCafeIncome: 200,
        prevPlaystationIncome: 200,
      );

      final result = useCase(reports, ReportPeriod.daily);

      expect(result.isNotEmpty, true);
      final primary = result.first;
      expect(primary.netProfit, 200);
      expect(primary.difference, 100.0);
      expect(primary.status, ProfitInsightStatus.increase);
      expect(primary.messageKey, AppStrings.insightProfitDailyIncrease);
    });

    test('Loss Scenario: should include loss insight in primary analysis', () {
      final reports = ReportsEntity(
        totalIncome: 425,
        totalExpenses: 500,
        netProfit: -75,
        totalDebts: 0,
        paidDebts: 0,
        unpaidDebts: 0,
        prevIncome: 500,
        prevExpenses: 100, // Prev Profit: 400
        cafeIncome: 200,
        playstationIncome: 225,
        prevCafeIncome: 250,
        prevPlaystationIncome: 250,
      );

      final result = useCase(reports, ReportPeriod.daily);

      expect(result.isNotEmpty, true);
      final primary = result.first;
      expect(primary.netProfit, -75);
      // (-75 - 400).abs() = 475
      expect(primary.difference, 475.0);
      expect(primary.status, ProfitInsightStatus.loss);
      expect(primary.messageKey, AppStrings.insightProfitDailyDecrease);
    });

    test('Cafe Growth Insight: should detect when cafe drove the income growth', () {
      final reports = ReportsEntity(
        totalIncome: 1000,
        totalExpenses: 500,
        netProfit: 500,
        totalDebts: 0,
        paidDebts: 0,
        unpaidDebts: 0,
        prevIncome: 800,
        prevExpenses: 500,
        cafeIncome: 600, // 600 vs prev 400 = +200
        playstationIncome: 400, // 400 vs prev 400 = 0
        prevCafeIncome: 400,
        prevPlaystationIncome: 400,
      );

      final result = useCase(reports, ReportPeriod.daily);

      final hasCafeInsight = result.any((i) => i.messageKey == "insight_income_up_cafe");
      expect(hasCafeInsight, true);
    });

    test('Playstation Low Contribution: should flag low ps contribution when it is < 30%', () {
      final reports = ReportsEntity(
        totalIncome: 1000,
        totalExpenses: 500,
        netProfit: 500,
        totalDebts: 0,
        paidDebts: 0,
        unpaidDebts: 0,
        prevIncome: 1000,
        prevExpenses: 500,
        cafeIncome: 850,
        playstationIncome: 150, // 15% contribution
        prevCafeIncome: 500,
        prevPlaystationIncome: 500,
      );

      final result = useCase(reports, ReportPeriod.daily);

      final hasLowPsInsight = result.any((i) => i.messageKey == "insight_ps_low_contribution");
      expect(hasLowPsInsight, true);
    });

    test('High Expense Alert: should flag if expenses increased > 20%', () {
       final reports = ReportsEntity(
        totalIncome: 1000,
        totalExpenses: 500,
        netProfit: 500,
        totalDebts: 0,
        paidDebts: 0,
        unpaidDebts: 0,
        prevIncome: 1000,
        prevExpenses: 200,
        cafeIncome: 500,
        playstationIncome: 500,
        prevCafeIncome: 500,
        prevPlaystationIncome: 500,
      );

      final result = useCase(reports, ReportPeriod.daily);

      final hasExpenseAlert = result.any((i) => i.messageKey == "insight_expenses_up_high");
      expect(hasExpenseAlert, true);
    });
  });
}

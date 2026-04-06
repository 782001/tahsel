import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_dashboard_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_net_profit_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_time_range_selector.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp(
        // Set text direction to RTL for Arabic app consistency
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('Reports Widgets Tests', () {
    testWidgets('ReportsDashboardCard renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        const ReportsDashboardCard(
          title: 'إجمالي الدخل',
          subtitle: 'subtitle',
          amount: '1,000',
          type: BusinessReportType.income,
          badgeText: 'badge',
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('إجمالي الدخل'), findsOneWidget);
      expect(find.text('1,000'), findsOneWidget);
    });

    testWidgets('ReportsNetProfitCard renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        const ReportsNetProfitCard(
          amount: '5,500',
          difference: '150',
          isPositive: true,
          comparisonText: 'مقارنة بالأمس',
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('5,500'), findsOneWidget);
    });

    testWidgets('ReportsTimeRangeSelector changes index on tap', (WidgetTester tester) async {
      int? tappedIndex;
      
      await tester.pumpWidget(createTestableWidget(
        ReportsTimeRangeSelector(
          onTabChanged: (index) => tappedIndex = index,
        ),
      ));

      await tester.pumpAndSettle();

      // Find by text
      final weekTab = find.text('أسبوعي');
      expect(weekTab, findsOneWidget);

      await tester.tap(weekTab);
      await tester.pumpAndSettle();

      expect(tappedIndex, 1);
    });
  });
}

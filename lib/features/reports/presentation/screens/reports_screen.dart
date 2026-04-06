import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_dashboard_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_net_profit_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_operational_margin_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_time_range_selector.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedTimeRange = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                AppStrings.reports.tr(),
                style: TextStyles.customStyle(
                  color: AppColors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            20.verticalSpace,
            SizedBox(height: 12.h),
            ReportsTimeRangeSelector(
              onTabChanged: (index) {
                setState(() => _selectedTimeRange = index);
              },
            ),

            const ReportsNetProfitCard(
              amount: "12,482.00",
              percentage: "12",
              isPositive: true,
            ),

            ReportsDashboardCard(
              title: AppStrings.totalIncome.tr(),
              subtitle: "",
              amount: "24,900.00",
              type: BusinessReportType.income,
              badgeText: _selectedTimeRange == 1
                  ? AppStrings.comparisonLastWeek.tr()
                  : _selectedTimeRange == 2
                      ? AppStrings.comparisonLastMonth.tr()
                      : AppStrings.comparisonYesterday.tr(),
            ),

            ReportsDashboardCard(
              title: AppStrings.totalExpenses.tr(),
              subtitle: "",
              amount: "12,418.00",
              type: BusinessReportType.expense,
              badgeText: AppStrings.withinBudget.tr(),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 32),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                AppStrings.activityDetails.tr(),
                style: TextStyles.customStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            const ReportsOperationalMarginCard(
              amount: "8,122.50",
              margin: 0.63,
            ),
            ReportsDashboardCard(
              title: AppStrings.cafeIncome.tr(),
              subtitle: "",
              amount: "4,210.00",
              type: BusinessReportType.cafe,
            ),
            ReportsDashboardCard(
              title: AppStrings.playstationIncome.tr(),
              subtitle: "",
              amount: "2,945.00",
              type: BusinessReportType.playstation,
              hasActiveStatus: true,
            ),
            ReportsDashboardCard(
              title: AppStrings.debts.tr(),
              subtitle: "",
              amount: "1,450.00",
              type: BusinessReportType.debts,
              badgeText: AppStrings.alert.tr(),
            ),
            SizedBox(height: 120.h), // Bottom spacing for navigation
          ],
        ),
      ),
    );
  }
}

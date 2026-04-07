import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/reports/domain/entities/profit_insight.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_state.dart';
import 'package:tahsel/features/reports/presentation/widgets/profit_insight_ui_extension.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_dashboard_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_net_profit_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_operational_margin_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_time_range_selector.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReportsCubit>()..fetchToday(),
      child: const ReportsView(),
    );
  }
}

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  int _selectedTimeRange = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async {
          _onTabChanged(_selectedTimeRange);
        },
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
                    fontSize: 25.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              20.verticalSpace,
              ReportsTimeRangeSelector(onTabChanged: _onTabChanged),
              SizedBox(height: 16.h),
              BlocBuilder<ReportsCubit, ReportsState>(
                builder: (context, state) {
                  if (state is ReportsLoading) {
                    return SizedBox(
                      height: 400.h,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    );
                  } else if (state is ReportsError) {
                    return SizedBox(
                      height: 400.h,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.message),
                            TextButton(
                              onPressed: () =>
                                  _onTabChanged(_selectedTimeRange),
                              child: Text(AppStrings.tryAgain.tr()),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is ReportsSuccess) {
                    final data = state.reports;
                    final margin = data.totalIncome > 0
                        ? data.netProfit / data.totalIncome
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReportsNetProfitCard(
                          amount: data.netProfit.toStringAsFixed(1),
                          difference: data.profitDiff.toStringAsFixed(1),
                          isPositive: data.isProfitIncrease,
                          comparisonText: _getBadgeText(),
                        ),

                        // Main Profit Insight Message
                        if (state.insights.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 8.h,
                            ),
                            child: _buildInsightCard(state.insights.first),
                          ),

                        ReportsDashboardCard(
                          title: AppStrings.totalIncome.tr(),
                          subtitle: "",
                          amount: data.totalIncome.toStringAsFixed(1),
                          type: BusinessReportType.income,
                          badgeText:
                              "${data.isIncomeIncrease ? '+' : '-'}${data.incomeDiff.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()} ${_getBadgeText()}",
                        ),

                        ReportsDashboardCard(
                          title: AppStrings.totalExpenses.tr(),
                          subtitle: "",
                          amount: data.totalExpenses.toStringAsFixed(1),
                          type: BusinessReportType.expense,
                          badgeText:
                              "${data.isExpenseIncrease ? '+' : '-'}${data.expenseDiff.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()} ${_getBadgeText()}",
                          onTap: () {
                            context.read<MainLayoutCubit>().changeBottomNav(1);
                          },
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

                        // Restore Cafe Income Card
                        ReportsDashboardCard(
                          title: AppStrings.cafeIncome.tr(),
                          subtitle: "",
                          amount: data.cafeIncome.toStringAsFixed(1),
                          type: BusinessReportType.cafe,
                          badgeText:
                              "${data.isCafeIncrease ? '+' : '-'}${data.cafeDiff.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()} ${_getBadgeText()}",
                        ),

                        // Restore Playstation Income Card
                        ReportsDashboardCard(
                          title: AppStrings.playstationIncome.tr(),
                          subtitle: "",
                          amount: data.playstationIncome.toStringAsFixed(1),
                          type: BusinessReportType.playstation,
                          badgeText:
                              "${data.isPlaystationIncrease ? '+' : '-'}${data.playstationDiff.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()} ${_getBadgeText()}",
                        ),

                        ReportsOperationalMarginCard(
                          amount: data.netProfit.toStringAsFixed(1),
                          margin: margin.clamp(0.0, 1.0),
                        ),

                        ReportsDashboardCard(
                          title: AppStrings.unpaid.tr(),
                          subtitle: "",
                          amount: data.unpaidDebts.toStringAsFixed(1),
                          type: BusinessReportType.debts,
                          badgeText:
                              "${AppStrings.debts.tr()}: ${data.totalDebts.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()} \n${AppStrings.paid.tr()}: ${data.paidDebts.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}",
                          onTap: () {
                            context.read<MainLayoutCubit>().changeBottomNav(2);
                          },
                        ),

                        // Smart Insights Section
                        if (state.insights.length > 1) ...[
                          32.verticalSpace,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              AppStrings.smartInsights.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          12.verticalSpace,
                          ...state.insights
                              .skip(1)
                              .map(
                                (insight) => Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    24.w,
                                    0,
                                    24.w,
                                    12.h,
                                  ),
                                  child: _buildInsightCard(insight),
                                ),
                              ),
                        ],

                        SizedBox(height: 120.h),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTimeRange = index);
    final cubit = context.read<ReportsCubit>();
    switch (index) {
      case 0:
        cubit.fetchToday();
        break;
      case 1:
        cubit.fetchCurrentWeek();
        break;
      case 2:
        cubit.fetchCurrentMonth();
        break;
    }
  }

  String _getBadgeText() {
    switch (_selectedTimeRange) {
      case 0:
        return AppStrings.comparisonYesterday.tr();
      case 1:
        return AppStrings.comparisonLastWeek.tr();
      case 2:
        return AppStrings.comparisonLastMonth.tr();
      default:
        return "";
    }
  }

  Widget _buildInsightCard(ProfitInsight insight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: insight.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: insight.color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              insight.status == ProfitInsightStatus.loss
                  ? Icons.trending_down_rounded
                  : (insight.status == ProfitInsightStatus.same
                        ? Icons.trending_flat_rounded
                        : Icons.trending_up_rounded),
              color: insight.color,
              size: 20.sp,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Text(
              insight.message,
              style: TextStyles.customStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: insight.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

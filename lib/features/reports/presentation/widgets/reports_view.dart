import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/skeletons/customer_debt_skeleton.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/reports/domain/entities/profit_insight.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_cubit/reports_cubit.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_cubit/reports_state.dart';
import 'package:tahsel/features/reports/presentation/widgets/build_report_insight_detail_row.dart';
import 'package:tahsel/features/reports/presentation/widgets/profit_insight_ui_extension.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_dashboard_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_invoice_summary_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_net_profit_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_operational_margin_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_time_range_selector.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  int _selectedTimeRange = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return SafeArea(
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          final bool isOffline = connectivityState is ConnectivityDisconnected;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 10.h),
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
              ),
              if (isOffline)
                Expanded(
                  child: NoInternetView(
                    onRetry: () {
                      context.read<ConnectivityCubit>().checkConnectivity();
                    },
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: () async {
                      await _onTabChanged(
                        _selectedTimeRange,
                        forceRefresh: true,
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 850 : double.infinity,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              isDesktop
                                  ? const SizedBox(height: 20)
                                  : 20.verticalSpace,
                              Padding(
                                padding: isDesktop
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 8,
                                      )
                                    : EdgeInsets.symmetric(horizontal: 24.w),
                                child: GestureDetector(
                                  onTap: () {
                                    final uid = AppStrings.userToken;
                                    if (uid.isNotEmpty) {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.customersList,
                                        arguments: uid,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      isDesktop ? 16 : 16.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                            isDesktop ? 10 : 10.w,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.whiteOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.people_alt_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        16.horizontalSpace,
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppStrings.myCustomers.tr(),
                                                style: TextStyles.customStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                AppStrings.customersReportDesc
                                                    .tr(),
                                                style: TextStyles.customStyle(
                                                  color: AppColors.whiteOpacity(
                                                    0.8,
                                                  ),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              isDesktop
                                  ? const SizedBox(height: 16)
                                  : 16.verticalSpace,
                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isDesktop ? 600 : double.infinity,
                                  ),
                                  child: Padding(
                                    padding: isDesktop
                                        ? const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          )
                                        : EdgeInsets.zero,
                                    child: ReportsTimeRangeSelector(
                                      onTabChanged: _onTabChanged,
                                    ),
                                  ),
                                ),
                              ),
                              isDesktop
                                  ? const SizedBox(height: 16)
                                  : SizedBox(height: 16.h),
                              BlocBuilder<ReportsCubit, ReportsState>(
                                builder: (context, state) {
                                  if (state is ReportsLoading) {
                                    return SizedBox(
                                      height: 450.h,
                                      child: ListView.builder(
                                        padding: EdgeInsets.all(16.w),
                                        itemBuilder: (context, index) =>
                                            const CustomerDebtCardSkeleton(),
                                        itemCount: 4,
                                      ),
                                    );
                                  } else if (state is ReportsError) {
                                    return SizedBox(
                                      height: 400.h,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search_off,
                                              size: 64,
                                              color: AppColors.blackLight
                                                  .withAlpha(100),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              AppStrings.noData.tr(),
                                              style: TextStyles.customStyle(
                                                color: AppColors.blackLight,
                                                fontSize: 16,
                                              ),
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

                                    final netProfitCard = ReportsNetProfitCard(
                                      amount: data.netProfit.toSmartAmount(),
                                      isPositive: data.isProfitIncrease,
                                      comparisonText: _buildComparisonText(
                                        label: AppStrings.netProfit.tr(),
                                        diff: data.profitDiff,
                                        isIncrease: data.isProfitIncrease,
                                      ),
                                    );

                                    final insightCard =
                                        state.insights.isNotEmpty
                                        ? _buildInsightCard(
                                            state.insights.first,
                                          )
                                        : null;

                                    final totalIncomeCard =
                                        ReportsDashboardCard(
                                          title: AppStrings.totalIncome.tr(),
                                          subtitle: "",
                                          amount: data.totalIncome
                                              .toSmartAmount(),
                                          type: BusinessReportType.income,
                                          isShop: context
                                              .read<MainLayoutCubit>()
                                              .isShop,
                                          badgeText: _buildComparisonText(
                                            label: AppStrings.totalIncome.tr(),
                                            diff: data.incomeDiff,
                                            isIncrease: data.isIncomeIncrease,
                                          ),
                                          onTap: () {
                                            final dateRange = _getDateRange();
                                            nav().pushNamedWithArgs(
                                              routeName:
                                                  AppRoutes.incomeDetails,
                                              arguments: {
                                                'startDate': dateRange.start,
                                                'endDate': dateRange.end,
                                                'period': _getPeriodString(),
                                                'type': null,
                                                'isShop': context
                                                    .read<MainLayoutCubit>()
                                                    .isShop,
                                                'totalIncome': data.totalIncome,
                                                'totalCount': data.totalCount,
                                              },
                                            );
                                          },
                                        );

                                    final totalExpensesCard =
                                        ReportsDashboardCard(
                                          title: AppStrings.totalExpenses.tr(),
                                          subtitle: "",
                                          amount: data.totalExpenses
                                              .toSmartAmount(),
                                          type: BusinessReportType.expense,
                                          isShop: context
                                              .read<MainLayoutCubit>()
                                              .isShop,
                                          badgeText: _buildComparisonText(
                                            label: AppStrings.totalExpenses
                                                .tr(),
                                            diff: data.expenseDiff,
                                            isIncrease: data.isExpenseIncrease,
                                          ),
                                          onTap: () {
                                            context
                                                .read<MainLayoutCubit>()
                                                .changeBottomNav(1);
                                          },
                                        );

                                    final bool showCafeCard =
                                        context
                                            .read<MainLayoutCubit>()
                                            .isShop ==
                                        false;
                                    final cafeCard = showCafeCard
                                        ? ReportsDashboardCard(
                                            title:
                                                context
                                                    .watch<MainLayoutCubit>()
                                                    .isShop
                                                ? AppStrings.shopIncome.tr()
                                                : AppStrings.cafeIncome.tr(),
                                            subtitle: "",
                                            amount: data.cafeIncome
                                                .toSmartAmount(),
                                            type: BusinessReportType.cafe,
                                            isShop: context
                                                .watch<MainLayoutCubit>()
                                                .isShop,
                                            badgeText: _buildComparisonText(
                                              label:
                                                  context
                                                      .read<MainLayoutCubit>()
                                                      .isShop
                                                  ? AppStrings.shopIncome.tr()
                                                  : AppStrings.cafeIncome.tr(),
                                              diff: data.cafeDiff,
                                              isIncrease: data.isCafeIncrease,
                                            ),
                                            onTap: () {
                                              final dateRange = _getDateRange();
                                              nav().pushNamedWithArgs(
                                                routeName:
                                                    AppRoutes.incomeDetails,
                                                arguments: {
                                                  'startDate': dateRange.start,
                                                  'endDate': dateRange.end,
                                                  'type': AppStrings.shop,
                                                  'period': _getPeriodString(),
                                                  'isShop': context
                                                      .read<MainLayoutCubit>()
                                                      .isShop,
                                                  'totalIncome':
                                                      data.cafeIncome,
                                                  'totalCount': data.cafeCount,
                                                },
                                              );
                                            },
                                          )
                                        : null;

                                    final bool showPlaystationCard = context
                                        .read<MainLayoutCubit>()
                                        .isCafe;
                                    final playstationCard = showPlaystationCard
                                        ? ReportsDashboardCard(
                                            title: AppStrings.playstationIncome
                                                .tr(),
                                            subtitle: "",
                                            amount: data.playstationIncome
                                                .toSmartAmount(),
                                            type:
                                                BusinessReportType.playstation,
                                            badgeText: _buildComparisonText(
                                              label: AppStrings
                                                  .playstationIncome
                                                  .tr(),
                                              diff: data.playstationDiff,
                                              isIncrease:
                                                  data.isPlaystationIncrease,
                                            ),
                                            onTap: () {
                                              final dateRange = _getDateRange();
                                              nav().pushNamedWithArgs(
                                                routeName:
                                                    AppRoutes.incomeDetails,
                                                arguments: {
                                                  'startDate': dateRange.start,
                                                  'endDate': dateRange.end,
                                                  'type':
                                                      AppStrings.playStation,
                                                  'period': _getPeriodString(),
                                                  'isShop': context
                                                      .read<MainLayoutCubit>()
                                                      .isShop,
                                                  'totalIncome':
                                                      data.playstationIncome,
                                                  'totalCount':
                                                      data.playstationCount,
                                                },
                                              );
                                            },
                                          )
                                        : null;

                                    final operationalMarginCard =
                                        ReportsOperationalMarginCard(
                                          amount: data.netProfit
                                              .toSmartAmount(),
                                          margin: margin.clamp(0.0, 1.0),
                                        );

                                    final unpaidDebtsCard = ReportsDashboardCard(
                                      title: AppStrings.unpaid.tr(),
                                      subtitle: "",
                                      amount: data.unpaidDebts.toSmartAmount(),
                                      type: BusinessReportType.debts,
                                      badgeText: _selectedTimeRange == 3
                                          ? ""
                                          : "${AppStrings.debts.tr()}: ${data.totalDebts.toSmartAmount()} ${AppStrings.currencyEgp.tr()}  \n${AppStrings.paid.tr()}: ${data.paidDebts.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                      onTap: () {
                                        context
                                            .read<MainLayoutCubit>()
                                            .changeBottomNav(2);
                                      },
                                    );

                                    final bool isShopUser = context
                                        .read<MainLayoutCubit>()
                                        .isShop;

                                    final ReportsInvoiceSummaryCard?
                                    invoiceSummaryCard = isShopUser
                                        ? ReportsInvoiceSummaryCard(
                                            invoiceCount: data.invoiceCount,
                                            invoiceValue: data.invoiceValue,
                                            invoiceCollected:
                                                data.invoiceCollected,
                                            invoiceRemaining:
                                                data.invoiceRemaining,
                                            invoicePaidCount:
                                                data.invoicePaidCount,
                                            invoicePartialCount:
                                                data.invoicePartialCount,
                                            invoiceUnpaidCount:
                                                data.invoiceUnpaidCount,
                                            onTap: () {
                                              context
                                                  .read<MainLayoutCubit>()
                                                  .changeBottomNav(3);
                                            },
                                          )
                                        : null;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isDesktop) ...[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(child: netProfitCard),
                                                if (insightCard != null) ...[
                                                  const SizedBox(width: 16),
                                                  Expanded(child: insightCard),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: totalIncomeCard,
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: totalExpensesCard,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else ...[
                                          netProfitCard,
                                          if (insightCard != null)
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24.w,
                                                vertical: 8.h,
                                              ),
                                              child: insightCard,
                                            ),
                                          totalIncomeCard,
                                          totalExpensesCard,
                                        ],

                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: Divider(height: 32),
                                        ),

                                        Padding(
                                          padding: isDesktop
                                              ? const EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                )
                                              : EdgeInsets.symmetric(
                                                  horizontal: 24.w,
                                                ),
                                          child: Text(
                                            AppStrings.activityDetails.tr(),
                                            style: TextStyles.customStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        if (isDesktop) ...[
                                          if (showCafeCard &&
                                              showPlaystationCard)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 8,
                                                  ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: cafeCard!),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: playstationCard!,
                                                  ),
                                                ],
                                              ),
                                            )
                                          else if (showCafeCard)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 8,
                                                  ),
                                              child: cafeCard!,
                                            )
                                          else if (showPlaystationCard)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 8,
                                                  ),
                                              child: playstationCard!,
                                            ),

                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: operationalMarginCard,
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: unpaidDebtsCard,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (invoiceSummaryCard != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 8,
                                                  ),
                                              child: invoiceSummaryCard,
                                            ),
                                        ] else ...[
                                          if (showCafeCard) cafeCard!,
                                          if (showPlaystationCard)
                                            playstationCard!,
                                          operationalMarginCard,
                                          unpaidDebtsCard,
                                          if (invoiceSummaryCard != null)
                                            invoiceSummaryCard,
                                        ],

                                        if (state.insights.length > 1) ...[
                                          const SizedBox(height: 32),
                                          Padding(
                                            padding: isDesktop
                                                ? const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                  )
                                                : EdgeInsets.symmetric(
                                                    horizontal: 24.w,
                                                  ),
                                            child: Text(
                                              AppStrings.smartInsights.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.black,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          if (isDesktop) ...[
                                            for (
                                              int i = 0;
                                              i < state.insights.skip(1).length;
                                              i += 2
                                            ) ...[
                                              (() {
                                                final currentList = state
                                                    .insights
                                                    .skip(1)
                                                    .where((insight) {
                                                      if (context
                                                          .read<
                                                            MainLayoutCubit
                                                          >()
                                                          .isShop) {
                                                        return !insight
                                                                .messageKey
                                                                .toLowerCase()
                                                                .contains(
                                                                  'ps',
                                                                ) &&
                                                            !insight.messageKey
                                                                .toLowerCase()
                                                                .contains(
                                                                  'playstation',
                                                                );
                                                      }
                                                      return true;
                                                    })
                                                    .toList();
                                                if (i >= currentList.length) {
                                                  return const SizedBox();
                                                }
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        24,
                                                        0,
                                                        24,
                                                        12,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            _buildInsightCard(
                                                              currentList[i],
                                                            ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      if (i + 1 <
                                                          currentList.length)
                                                        Expanded(
                                                          child:
                                                              _buildInsightCard(
                                                                currentList[i +
                                                                    1],
                                                              ),
                                                        )
                                                      else
                                                        const Expanded(
                                                          child: SizedBox(),
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              })(),
                                            ],
                                          ] else ...[
                                            ...state.insights
                                                .skip(1)
                                                .where((insight) {
                                                  if (context
                                                      .read<MainLayoutCubit>()
                                                      .isShop) {
                                                    return !insight.messageKey
                                                            .toLowerCase()
                                                            .contains('ps') &&
                                                        !insight.messageKey
                                                            .toLowerCase()
                                                            .contains(
                                                              'playstation',
                                                            );
                                                  }
                                                  return true;
                                                })
                                                .map(
                                                  (insight) => Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                          24.w,
                                                          0,
                                                          24.w,
                                                          12.h,
                                                        ),
                                                    child: _buildInsightCard(
                                                      insight,
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ],

                                        SizedBox(
                                          height: isDesktop ? 60 : 120.h,
                                        ),
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
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onTabChanged(int index, {bool forceRefresh = false}) async {
    setState(() => _selectedTimeRange = index);
    final cubit = context.read<ReportsCubit>();
    switch (index) {
      case 0:
        cubit.fetchToday(forceRefresh: forceRefresh);
        break;
      case 1:
        cubit.fetchCurrentWeek(forceRefresh: forceRefresh);
        break;
      case 2:
        cubit.fetchCurrentMonth(forceRefresh: forceRefresh);
        break;
      case 3:
        await cubit.fetchAllTime(forceRefresh: forceRefresh);
        break;
    }
  }

  ({DateTime start, DateTime end}) _getDateRange() {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case 0:
        return (
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 1:
        final start = now.subtract(Duration(days: now.weekday % 7));
        return (start: DateTime(start.year, start.month, start.day), end: now);
      case 2:
        return (start: DateTime(now.year, now.month, 1), end: now);
      case 3:
        // All time: from a very old date to now
        return (start: DateTime(1800, 1, 1), end: now);
      default:
        return (start: DateTime(now.year, now.month, now.day), end: now);
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
      case 3:
        return "";
      default:
        return "";
    }
  }

  String _getPeriodString() {
    switch (_selectedTimeRange) {
      case 0:
        return 'daily';
      case 1:
        return 'weekly';
      case 2:
        return 'monthly';
      case 3:
        return 'allTime';
      default:
        return 'daily';
    }
  }

  String _buildComparisonText({
    required String label,
    required double diff,
    required bool isIncrease,
  }) {
    if (_selectedTimeRange == 3) return "";

    if (diff == 0) {
      return AppStrings.comparisonNoChange.tr(
        namedArgs: {'label': label, 'period': _getBadgeText()},
      );
    }

    final String key = isIncrease
        ? AppStrings.comparisonIncrease
        : AppStrings.comparisonDecrease;

    return key.tr(
      namedArgs: {
        'label': label,
        'amount': diff.toSmartAmount(),
        'currency': AppStrings.currencyEgp.tr(),
        'period': _getBadgeText(),
      },
    );
  }

  String _getCurrentPeriodLabel() {
    switch (_selectedTimeRange) {
      case 0:
        return AppStrings.earningsToday.tr();
      case 1:
        return AppStrings.earningsThisWeek.tr();
      case 2:
        return AppStrings.earningsThisMonth.tr();
      default:
        return "";
    }
  }

  String _getPreviousPeriodLabel() {
    switch (_selectedTimeRange) {
      case 0:
        return AppStrings.earningsYesterday.tr();
      case 1:
        return AppStrings.earningsLastWeek.tr();
      case 2:
        return AppStrings.earningsLastMonth.tr();
      default:
        return "";
    }
  }

  Widget _buildInsightCard(ProfitInsight insight) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final isComparison =
        insight.messageKey.contains('increase') ||
        insight.messageKey.contains('decrease') ||
        insight.messageKey.contains('same');

    // If it's a simple message (like "no data"), show original style
    if (!isComparison || _selectedTimeRange == 3) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isDesktop ? 24 : 12.w),
        decoration: BoxDecoration(
          color: insight.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isDesktop ? 24 : 12.r),
          border: Border.all(
            color: insight.color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 12 : 6.w),
              decoration: BoxDecoration(
                color: insight.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                insight.status == ProfitInsightStatus.loss
                    ? Icons.trending_down_rounded
                    : (insight.status == ProfitInsightStatus.same
                          ? Icons.trending_flat_rounded
                          : Icons.trending_up_rounded),
                color: insight.color,
                size: 20,
              ),
            ),
            SizedBox(width: isDesktop ? 12 : 8.w),
            Expanded(
              child: Text(
                insight.getMessage(context.read<MainLayoutCubit>().isShop),
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: insight.color,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Detailed Breakdown Style
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: insight.color.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insight.status == ProfitInsightStatus.loss
                    ? Icons.trending_down_rounded
                    : (insight.status == ProfitInsightStatus.same
                          ? Icons.trending_flat_rounded
                          : Icons.trending_up_rounded),
                color: insight.color,
                size: 20,
              ),
              8.horizontalSpace,
              Text(
                AppStrings.earningsComparison.tr(),
                style: TextStyles.customStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: insight.color,
                ),
              ),
            ],
          ),
          12.verticalSpace,
          BuildReportInsightDetailRow(
            label: _getCurrentPeriodLabel(),
            value: insight.currentValue,
            textColor: AppColors.black,
          ),
          8.verticalSpace,
          BuildReportInsightDetailRow(
            label: _getPreviousPeriodLabel(),
            value: insight.previousValue,
            textColor: AppColors.grey,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(
              color: insight.color.withValues(alpha: 0.1),
              thickness: 1,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.difference.tr(),
                style: TextStyles.customStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: insight.color,
                ),
              ),
              Row(
                children: [
                  Text(
                    insight.status == ProfitInsightStatus.increase
                        ? "+"
                        : (insight.status == ProfitInsightStatus.loss
                              ? "-"
                              : ""),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: insight.color,
                    ),
                  ),
                  Text(
                    "${insight.difference.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: insight.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';

import '../cubit/income_cubit/income_details_cubit.dart';
import '../widgets/income_summary_card.dart';
import '../widgets/transaction_detail_card.dart';

class IncomeDetailsScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? type; // AppStrings.shop, AppStrings.playStation, or null
  final String period; // 'daily', 'weekly', 'monthly'
  final bool isShop;
  final double totalIncome; // Passed from parent for accuracy
  final int totalCount; // Passed from parent for accuracy

  const IncomeDetailsScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.isShop,
    required this.totalIncome,
    required this.totalCount,
    this.type,
  });

  @override
  State<IncomeDetailsScreen> createState() => _IncomeDetailsScreenState();
}

class _IncomeDetailsScreenState extends State<IncomeDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<IncomeDetailsCubit>().loadMoreIncomeDetails(
        widget.startDate,
        widget.endDate,
        type: widget.type,
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _getScreenTitle(context, widget.type, widget.period),
          style: TextStyles.customStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
          builder: (context, connectivityState) {
            if (connectivityState is ConnectivityDisconnected) {
              return NoInternetView(
                onRetry: () {
                  context.read<ConnectivityCubit>().checkConnectivity();
                },
              );
            }

            return BlocBuilder<IncomeDetailsCubit, IncomeDetailsState>(
              builder: (context, state) {
                if (state is IncomeDetailsInitial ||
                    state is IncomeDetailsLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
                  );
                } else if (state is IncomeDetailsError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 60,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            state.message,
                            style: TextStyles.customStyle(
                              color: AppColors.error,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: () => context
                                .read<IncomeDetailsCubit>()
                                .fetchIncomeDetails(
                                  widget.startDate,
                                  widget.endDate,
                                  type: widget.type,
                                  isRefresh: true,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              AppStrings.tryAgain.tr(),
                              style: TextStyles.customStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is IncomeDetailsLoaded) {
                  final dateRangeStr = _formatDateRange(
                    context,
                    widget.startDate,
                    widget.endDate,
                  );

                  return RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: () =>
                        context.read<IncomeDetailsCubit>().fetchIncomeDetails(
                          widget.startDate,
                          widget.endDate,
                          type: widget.type,
                          isRefresh: true,
                        ),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // Summary Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24.w,
                              24.h,
                              24.w,
                              16.h,
                            ),
                            child: IncomeSummaryCard(
                              totalIncome: widget.totalIncome,
                              count: widget.totalCount,
                              dateRange: dateRangeStr,
                            ),
                          ),
                        ),

                        // List or Empty State
                        if (state.operations.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.insert_chart_outlined_rounded,
                                    size: 80,
                                    color: AppColors.blackLight.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    AppStrings.noIncomeData.tr(),
                                    style: TextStyles.customStyle(
                                      color: AppColors.blackLight.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => TransactionDetailCard(
                                  operation: state.operations[index],
                                ),
                                childCount: state.operations.length,
                              ),
                            ),
                          ),

                          // Loading More Indicator
                          if (!state.hasReachedMax)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.h),
                                child: Center(
                                  child: SizedBox(
                                    height: 24.w,
                                    width: 24.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  String _getScreenTitle(BuildContext context, String? type, String period) {
    String periodStr = '';
    if (period == 'daily') {
      periodStr = AppStrings.periodDaily.tr();
    } else if (period == 'weekly') {
      periodStr = AppStrings.periodWeekly.tr();
    } else if (period == 'monthly') {
      periodStr = AppStrings.periodMonthly.tr();
    } else if (period == 'allTime') {
      periodStr = AppStrings.allTime.tr();
    }

    if (type == null) {
      return "${AppStrings.totalIncome.tr()} ($periodStr)";
    } else if (periodStr.isEmpty) {
      return widget.isShop
          ? AppStrings.shopIncome.tr()
          : AppStrings.cafeIncome.tr();
    } else if (type.toLowerCase() == AppStrings.shop.toLowerCase()) {
      return widget.isShop
          ? "${AppStrings.shopIncome.tr()} ($periodStr)"
          : "${AppStrings.cafeIncome.tr()} ($periodStr)";
    } else if (type.toLowerCase() == AppStrings.playStation.toLowerCase()) {
      return "${AppStrings.playstationIncome.tr()} ($periodStr)";
    }

    return AppStrings.incomeDetails.tr();
  }

  String _formatDateRange(BuildContext context, DateTime start, DateTime end) {
    final bool isArabic =
        context.read<LocaleCubit>().state.locale.languageCode == 'ar';
    final DateFormat formatter = isArabic
        ? DateFormat('d MMM', 'ar')
        : DateFormat('d MMM', 'en');

    // If it's the same day
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return formatter.format(start);
    }

    return "${formatter.format(start)} - ${formatter.format(end)}";
  }
}

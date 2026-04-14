import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import '../cubit/income_cubit/income_details_cubit.dart';
import '../widgets/income_summary_card.dart';
import '../widgets/transaction_detail_card.dart';

class IncomeDetailsScreen extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? type; // AppStrings.shop, AppStrings.playStation, or null
  final String period; // 'daily', 'weekly', 'monthly'

  const IncomeDetailsScreen({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.period,
    this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<IncomeDetailsCubit>()..fetchIncomeDetails(startDate, endDate, type: type),
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _getScreenTitle(context, type, period),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<IncomeDetailsCubit, IncomeDetailsState>(
          builder: (context, state) {
            if (state is IncomeDetailsLoading) {
              return Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
            } else if (state is IncomeDetailsError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: AppColors.error, size: 60.sp),
                      SizedBox(height: 16.h),
                      Text(
                        state.message,
                        style: TextStyle(color: AppColors.error, fontSize: 16.sp),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: () => context.read<IncomeDetailsCubit>().fetchIncomeDetails(startDate, endDate, type: type),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text(AppStrings.tryAgain.tr()),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is IncomeDetailsLoaded) {
              final totalIncome = state.operations.fold<double>(0, (sum, op) => sum + op.totalAmount);
              final dateRangeStr = _formatDateRange(context, startDate, endDate);

              return RefreshIndicator(
                color: AppColors.primaryColor,
                onRefresh: () => context.read<IncomeDetailsCubit>().fetchIncomeDetails(startDate, endDate, type: type),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // Summary Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
                        child: IncomeSummaryCard(
                          totalIncome: totalIncome,
                          count: state.operations.length,
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
                              Icon(Icons.insert_chart_outlined_rounded, size: 80.sp, color: AppColors.blackLight.withOpacity(0.1)),
                              SizedBox(height: 16.h),
                              Text(
                                AppStrings.noIncomeData.tr(),
                                style: TextStyle(
                                  color: AppColors.blackLight.withOpacity(0.4),
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => TransactionDetailCard(operation: state.operations[index]),
                            childCount: state.operations.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _getScreenTitle(BuildContext context, String? type, String period) {
    String periodStr = '';
    if (period == 'daily') periodStr = AppStrings.periodDaily.tr();
    else if (period == 'weekly') periodStr = AppStrings.periodWeekly.tr();
    else if (period == 'monthly') periodStr = AppStrings.periodMonthly.tr();

    if (type == null) {
      return "$periodStr ${AppStrings.totalIncome.tr()}";
    } else if (type.toLowerCase() == AppStrings.shop.toLowerCase()) {
      return "$periodStr ${AppStrings.cafeIncome.tr()}";
    } else if (type.toLowerCase() == AppStrings.playStation.toLowerCase()) {
      return "$periodStr ${AppStrings.playstationIncome.tr()}";
    }
    
    return AppStrings.incomeDetails.tr();
  }

  String _formatDateRange(BuildContext context, DateTime start, DateTime end) {
    final bool isArabic = context.read<LocaleCubit>().state.locale.languageCode == 'ar';
    final DateFormat formatter = isArabic ? DateFormat('d MMM', 'ar') : DateFormat('d MMM', 'en');
    
    // If it's the same day
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return formatter.format(start);
    }
    
    return "${formatter.format(start)} - ${formatter.format(end)}";
  }
}

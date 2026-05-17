import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/skeletons/customer_debt_skeleton.dart';

import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/monthly_collected_amount.dart';
import '../cubit/monthly_collected/monthly_collected_cubit.dart';
import '../cubit/monthly_collected/monthly_collected_state.dart';

class MonthlyCollectedScreen extends StatelessWidget {
  final String uid;

  const MonthlyCollectedScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocProvider(
      create: (context) => sl<MonthlyCollectedCubit>()..loadMonthlyData(uid),
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          title: Text(
            AppStrings.collectedAmount.tr(),
            style: TextStyles.customStyle(
              color: AppColors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.scafoldBackGround,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textColor,
              size: 20.r,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          iconTheme: IconThemeData(color: AppColors.primaryColor),
        ),
        body: BlocBuilder<MonthlyCollectedCubit, MonthlyCollectedState>(
          builder: (context, state) {
            if (state is MonthlyCollectedLoading) {
              return isDesktop
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 220,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemBuilder: (context, index) =>
                            const CustomerDebtCardSkeleton(),
                        itemCount: 6,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemBuilder: (context, index) =>
                          const CustomerDebtCardSkeleton(),
                      itemCount: 5,
                    );
            } else if (state is MonthlyCollectedError) {
              AppLogger.printMessage(state.message);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: AppColors.grey.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      AppStrings.noCollectedData.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 20,
                        color: AppColors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is MonthlyCollectedSuccess) {
              if (state.data.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 80,
                        color: AppColors.grey.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        AppStrings.noCollectedData.tr(),
                        style: TextStyles.customStyle(fontSize: 20),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 0,
                    vertical: 16.h,
                  ),
                  child: Column(
                    children: [
                      // Total Collected Summary Header
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: _buildSummaryHeader(state.data, isDesktop),
                        ),
                      ),

                      if (isDesktop)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 100,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: state.data.length,
                          itemBuilder: (context, index) {
                            final item = state.data[index];
                            return FadeInUp(
                              duration: Duration(
                                milliseconds: 300 + (index * 30),
                              ),
                              child: _buildMonthCard(context, item, isDesktop),
                            );
                          },
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.all(16.w),
                          itemCount: state.data.length,
                          itemBuilder: (context, index) {
                            final item = state.data[index];
                            return FadeInUp(
                              duration: Duration(
                                milliseconds: 300 + (index * 30),
                              ),
                              child: _buildMonthCard(context, item, isDesktop),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(
    List<MonthlyCollectedAmount> data,
    bool isDesktop,
  ) {
    final total = data.fold(0.0, (sum, item) => sum + item.totalAmount);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 8 : 16.h,
      ),
      padding: EdgeInsets.all(isDesktop ? 32 : 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.totalCollected.tr(),
            style: TextStyles.customStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: isDesktop ? 16 : 14,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "${total.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
            style: TextStyles.customStyle(
              color: Colors.white,
              fontSize: isDesktop ? 36 : 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard(
    BuildContext context,
    MonthlyCollectedAmount item,
    bool isDesktop,
  ) {
    final monthName = _getMonthName(item.month, context);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 0 : 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.monthlyCollectedTransactions,
              arguments: {'monthlyData': item, 'uid': uid},
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : 16.w,
              vertical: isDesktop ? 12 : 16.h,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 10 : 10.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primaryColor,
                    size: isDesktop ? 24 : 24.r,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$monthName ${item.year}",
                        style: TextStyles.customStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${item.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Simple indicator for high collection months
                _buildPerformanceIndicator(item.totalAmount),
                Icon(
                  Icons.arrow_forward_ios,
                  size: isDesktop ? 14 : 14.r,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator(double amount) {
    // Simple visual flair: show a green arrow if amount is significant
    if (amount > 1000) {
      return Padding(
        padding: EdgeInsets.only(left: 8.w, right: 12.w),
        child: const Icon(Icons.trending_up, color: AppColors.green, size: 20),
      );
    }
    return const SizedBox.shrink();
  }

  String _getMonthName(int month, BuildContext context) {
    // Month is 1-indexed (1=Jan, 12=Dec)
    final date = DateTime(2024, month);
    return DateFormat.MMMM(
      Localizations.localeOf(context).languageCode,
    ).format(date);
  }
}

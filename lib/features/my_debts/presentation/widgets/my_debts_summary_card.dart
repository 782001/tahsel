import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_summary_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_summary_state.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/skeletons/my_debts_summary_skeleton.dart';

class MyDebtsSummaryCard extends StatelessWidget {
  const MyDebtsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDebtsSummaryCubit, MyDebtsSummaryState>(
      builder: (context, state) {
        if (state is MyDebtsSummaryLoading || state is MyDebtsSummaryInitial) {
          return const MyDebtsSummarySkeleton();
        }

        final double totalOwed;
        final double totalPaid;
        final int totalPeople;

        if (state is MyDebtsSummaryLoaded) {
          totalOwed = state.totalOwed;
          totalPaid = state.totalPaid;
          totalPeople = state.totalPeople;
        } else {
          totalOwed = 0;
          totalPaid = 0;
          totalPeople = 0;
        }

        return FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.debtCardSurface,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppColors.isDark ? 0.3 : 0.05,
                  ),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: AppColors.isDark
                    ? AppColors.whiteOpacity(0.05)
                    : AppColors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.payments_outlined,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      AppStrings.whatIOweOutside.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  '${totalOwed.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    color: AppColors.primaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      Icons.people_alt_outlined,
                      '$totalPeople ${AppStrings.totalPeople.tr()}',
                    ),
                    _buildInfoItem(
                      Icons.check_circle_outline,
                      '${AppStrings.paid.tr()}: ${totalPaid.toStringAsFixed(1)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.disabledColor, size: 18),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyles.customStyle(
                color: AppColors.disabledColor,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/debt/domain/entities/debt_entity.dart';
import 'package:tahsel/features/debt/presentation/widgets/debt_details_report_summary_item.dart';

class BuildDebtDetailsSummaryCard extends StatelessWidget {
  const BuildDebtDetailsSummaryCard({
    super.key,
    required this.totalAmount,
    required this.amountPaid,
    required this.remainingDebt,
    this.debt,
  });

  final double totalAmount;
  final double amountPaid;
  final double remainingDebt;
  final DebtEntity? debt;

  @override
  Widget build(BuildContext context) {
    final bool isSettled = remainingDebt <= 0;

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSettled
              ? [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withValues(alpha: 0.8),
                ]
              : [AppColors.error.withValues(alpha: 0.9), AppColors.error],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isSettled ? AppColors.primaryColor : AppColors.error)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt?.customerName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        debt?.productOrSessionDetails ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (debt?.ledgerNumber != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          '${AppStrings.ledgerNumber.tr()}: ${debt?.ledgerNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.customStyle(
                            color: AppColors.whiteOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.whiteOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isSettled
                      ? AppStrings.fullSettlement.tr()
                      : AppStrings.debtStatusOverdue.tr(),
                  style: TextStyles.customStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DebtDetailsReportSummaryItem(
                label: AppStrings.totalDueLabel.tr(),
                value: totalAmount.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              DebtDetailsReportSummaryItem(
                label: AppStrings.paid.tr(),
                value: amountPaid.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              DebtDetailsReportSummaryItem(
                label: AppStrings.remaining.tr(),
                value: remainingDebt.toSmartAmount(),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    final bool hasCredit = remainingDebt < 0;

    // Three visual states:
    //   hasCredit → amber/gold  (customer has a refund balance)
    //   isSettled → green/primary (fully paid, nothing owed)
    //   default   → red (still has an outstanding debt)
    final Color cardColor = hasCredit
        ? const Color(0xFFB45309) // amber-800
        : isSettled
            ? AppColors.primaryColor
            : AppColors.error;

    final List<Color> gradientColors = hasCredit
        ? [
            const Color(0xFFF59E0B), // amber-400
            const Color(0xFFB45309), // amber-800
          ]
        : isSettled
            ? [
                AppColors.primaryColor,
                AppColors.primaryColor.withValues(alpha: 0.8),
              ]
            : [AppColors.error.withValues(alpha: 0.9), AppColors.error];

    final String statusBadgeLabel = hasCredit
        ? AppStrings.customerCredit.tr()
        : isSettled
            ? AppStrings.fullSettlement.tr()
            : AppStrings.debtStatusOverdue.tr();

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
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
                  statusBadgeLabel,
                  style: TextStyles.customStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // ── Customer Credit banner ───────────────────────────────────────────
          if (hasCredit) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 18.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${AppStrings.customerCredit.tr()}:  ${remainingDebt.abs().toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                      style: TextStyles.customStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

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

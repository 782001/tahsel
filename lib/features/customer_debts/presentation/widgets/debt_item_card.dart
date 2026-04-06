import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';

/// A card showing a single debt transaction row (one item/day).
class DebtItemCard extends StatelessWidget {
  final DebtItem item;
  final int index;
  final Function(DebtItem) onPayPartial;
  final Function(DebtItem) onPayFull;

  const DebtItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onPayPartial,
    required this.onPayFull,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSettled = item.remainingDebt <= 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.debtCardSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSettled
              ? AppColors.primaryColor.withOpacity(0.2)
              : AppColors.error.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Row 1: index badge + item desc + date ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction number badge
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: TextStyles.customStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          color: AppColors.textColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11.r,
                            color: AppColors.disabledColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            item.date,
                            style: TextStyles.customStyle(
                              color: AppColors.disabledColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Settled / pending pill
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isSettled
                        ? AppColors.primaryColor.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    isSettled
                        ? AppStrings.fullPaymentLabel.tr()
                        : AppStrings.debtStatusOverdue.tr(),
                    style: TextStyles.customStyle(
                      color: isSettled
                          ? AppColors.primaryColor
                          : AppColors.error,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // --- Row 2: Financials ---
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.stitchSurfaceLow,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  _FinancialCell(
                    label: AppStrings.totalDueLabel.tr(),
                    amount: item.totalAmount,
                    color: AppColors.blackLight,
                  ),
                  _Divider(),
                  _FinancialCell(
                    label: AppStrings.amountPaid.tr(),
                    amount: item.amountPaid,
                    color: AppColors.primaryColor,
                  ),
                  _Divider(),
                  _FinancialCell(
                    label: AppStrings.remainingDebt.tr(),
                    amount: item.remainingDebt,
                    color: item.remainingDebt > 0
                        ? AppColors.error
                        : AppColors.primaryColor,
                  ),
                ],
              ),
            ),
            if (!isSettled) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onPayPartial(item),
                      icon: Icon(Icons.payments_outlined, size: 16.r),
                      label: Text(AppStrings.partialPayLabel.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: BorderSide(
                          color: AppColors.primaryColor.withOpacity(0.5),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        textStyle: TextStyles.customStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onPayFull(item),
                      icon: Icon(Icons.check_circle_outline, size: 16.r),
                      label: Text(AppStrings.fullPaymentLabel.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.whiteColor,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        textStyle: TextStyles.customStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _FinancialCell extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _FinancialCell({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyles.customStyle(
              color: AppColors.disabledColor,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${amount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
              style: TextStyles.customStyle(
                color: color,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: AppColors.disabledColor.withOpacity(0.2),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';

class MyDebtItemCard extends StatelessWidget {
  final MyDebtItem item;
  final int index;
  final Function(MyDebtItem) onPayPartial;
  final Function(MyDebtItem) onPayFull;
  final bool isFullPaying;
  final VoidCallback onTap;

  const MyDebtItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onPayPartial,
    required this.onPayFull,
    this.isFullPaying = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.debtCardSurface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '#$index',
                        style: TextStyles.customStyle(
                          color: AppColors.primaryColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      item.date,
                      style: TextStyles.customStyle(
                        color: AppColors.subTitleColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  item.description.isNotEmpty ? item.description : "",
                  style: TextStyles.customStyle(
                    color: AppColors.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmountInfo(
                      AppStrings.totalDueLabel.tr(),
                      item.totalAmount,
                    ),
                    _buildAmountInfo(
                      AppStrings.amountPaid.tr(),
                      item.amountPaid,
                    ),
                    _buildAmountInfo(
                      AppStrings.remainingDebt.tr(),
                      item.remainingDebt,
                      isRemaining: true,
                    ),
                  ],
                ),
                if (item.remainingDebt > 0) ...[
                  const Divider(height: 24, thickness: 0.5),
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
                        child: ElevatedButton(
                          onPressed: isFullPaying ? null : () => onPayFull(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.whiteColor,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isFullPaying) ...[
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      color: AppColors.whiteColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ] else
                                  Icon(Icons.check_circle_outline, size: 16.r),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.fullPaymentLabel.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.whiteColor,
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildAmountInfo(
    String label,
    double amount, {
    bool isRemaining = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            color: AppColors.subTitleColor,
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${amount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
          style: TextStyles.customStyle(
            color: isRemaining ? AppColors.error : AppColors.textColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

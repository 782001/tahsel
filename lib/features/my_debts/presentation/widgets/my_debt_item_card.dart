import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/routes/app_routes.dart';

class MyDebtItemCard extends StatelessWidget {
  final MyDebtItemEntity item;
  final int index;
  final Function(MyDebtItemEntity) onPayPartial;
  final Function(MyDebtItemEntity) onPayFull;
  final Function(MyDebtItemEntity) onDelete;
  final VoidCallback? onRefresh;
  final bool isFullPaying;

  const MyDebtItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onPayPartial,
    required this.onPayFull,
    required this.onDelete,
    this.onRefresh,
    this.isFullPaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isPending ? 0.7 : 1.0,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: AppColors.debtCardSurface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark ? 0.2 : 0.03,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: item.isPending
                ? null
                : () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.myDebtDetailsReport,
                      arguments: item.id,
                    ).then((_) {
                      if (context.mounted && onRefresh != null) {
                        onRefresh!();
                      }
                    });
                  },
            onLongPress: item.isPending
                ? null
                : () {
                    // if (item.remainingAmount > 0) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     SnackBar(
                    //       duration: const Duration(seconds: 2),
                    //       backgroundColor: AppColors.error,
                    //       content: Text(
                    //         AppStrings.deleteDebtAfterPaid.tr(),
                    //         style: TextStyles.customStyle(
                    //           color: Colors.white,
                    //           fontSize: 14.sp,
                    //         ),
                    //       ),
                    //     ),
                    //   );
                    // } else {
                    onDelete(item);
                    // }
                  },
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '#$index',
                              style: TextStyles.customStyle(
                                color: AppColors.primaryColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.isPending) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    "قيد المزامنة...",
                                    style: TextStyles.customStyle(
                                      color: AppColors.error,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        item.timestamp != null
                            ? DateFormat('yyyy/MM/dd').format(item.timestamp!)
                            : '',
                        style: TextStyles.customStyle(
                          color: AppColors.subTitleColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    item.details?.isNotEmpty == true
                        ? item.details!
                        : AppStrings.noDescription.tr(),
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
                        item.paidAmount,
                      ),
                      _buildAmountInfo(
                        AppStrings.remainingDebt.tr(),
                        item.remainingAmount,
                        isRemaining: true,
                      ),
                    ],
                  ),
                  if (item.remainingAmount > 0) ...[
                    const Divider(height: 24, thickness: 0.5),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: item.isPending
                                ? null
                                : () => onPayPartial(item),
                            icon: Icon(Icons.payments_outlined, size: 16.r),
                            label: Text(AppStrings.partialPayLabel.tr()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryColor,
                              side: BorderSide(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
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
                            onPressed: (isFullPaying || item.isPending)
                                ? null
                                : () => onPayFull(item),
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
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16.r,
                                    ),
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

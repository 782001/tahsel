import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';
import 'package:tahsel/routes/app_routes.dart';

class MyDebtCard extends StatelessWidget {
  final MyDebtDetail detail;

  const MyDebtCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
          onTap: () {
            sl<NavigatorService>().pushNamedWithArgs(
              routeName: AppRoutes.myDebtDetails,
              arguments: detail,
            );
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
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
                            detail.personName,
                            style: TextStyles.customStyle(
                              color: AppColors.textColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (detail.phoneNumber != null &&
                              detail.phoneNumber!.isNotEmpty)
                            Text(
                              detail.phoneNumber!,
                              style: TextStyles.customStyle(
                                color: AppColors.subTitleColor,
                                fontSize: 12.sp,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: detail.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        detail.status.tr(),
                        style: TextStyles.customStyle(
                          color: detail.statusColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmountInfo(
                      AppStrings.remainingDebt.tr(),
                      detail.totalDebt,
                      AppColors.error,
                    ),
                    _buildAmountInfo(
                      AppStrings.paid.tr(),
                      detail.totalPaid,
                      AppColors.success,
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.5),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.disabledColor,
                      size: 14.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${AppStrings.lastTransactionDate.tr()}: ${detail.lastTransactionDate}',
                      style: TextStyles.customStyle(
                        color: AppColors.disabledColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            color: AppColors.subTitleColor,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${amount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
          style: TextStyles.customStyle(
            color: color,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

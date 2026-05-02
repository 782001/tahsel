import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/operation/domain/entities/operation_entity.dart';

class TransactionDetailCard extends StatelessWidget {
  final OperationEntity operation;

  const TransactionDetailCard({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    final bool isPlaystation =
        operation.type.toLowerCase() == AppStrings.playStation.toLowerCase();
    final bool hasDebt = operation.remainingDebt > 0;

    final DateFormat timeFormat = DateFormat('hh:mm a');
    final DateFormat dateFormat = DateFormat('yyyy/MM/dd');

    String subtitleText = '';
    if (isPlaystation) {
      if (operation.subType == 'time') {
        final durationStr = AppStrings.durationMins.tr().replaceAll(
          '{mins}',
          '${operation.durationMinutes ?? 0}',
        );
        subtitleText = "${AppStrings.psSessionTime.tr()} - $durationStr";
      } else {
        subtitleText =
            "${AppStrings.psSessionTurn.tr()} - ${operation.turnCount ?? 0} ادوار";
      }
    } else {
      subtitleText = operation.productName ?? AppStrings.shop.tr();
    }

    final String customerName =
        (operation.customerName != null && operation.customerName!.isNotEmpty)
        ? operation.customerName!
        : AppStrings.walkingCustomer.tr();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: hasDebt
              ? AppColors.error.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          children: [
            // Status marker for debt
            if (hasDebt)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                color: AppColors.error.withOpacity(0.3),
                child: Center(
                  child: Text(
                    AppStrings.remainingDebt.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon Circle
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color:
                              (isPlaystation
                                      ? AppColors.primaryColor
                                      : AppColors.green)
                                  .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaystation
                              ? Icons.sports_esports_outlined
                              : Icons.shopping_bag_outlined,
                          color: (isPlaystation
                              ? AppColors.primaryColor
                              : AppColors.green),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Customer and Type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: TextStyles.customStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              subtitleText,
                              style: TextStyles.customStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.blackLight.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Amount
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              operation.totalAmount.toSmartAmount(),
                              style: TextStyles.customStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            Text(
                              AppStrings.currencyEgp.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),
                  const Divider(height: 1),

                  // Debt Breakdown Section
                  if (hasDebt) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.paidAmount.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blackLight.withOpacity(0.5),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${operation.paidAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                  style: TextStyles.customStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30.h,
                          color: AppColors.blackLight.withOpacity(0.1),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.remainingDebt.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blackLight.withOpacity(0.5),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${operation.remainingDebt.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                  style: TextStyles.customStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 12.h),

                  // Footer: Date & Time + Payment Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12.sp,
                            color: AppColors.blackLight.withOpacity(0.4),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            operation.timestamp != null
                                ? dateFormat.format(operation.timestamp!)
                                : 'N/A',
                            style: TextStyles.customStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blackLight.withOpacity(0.5),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.access_time_rounded,
                            size: 12.sp,
                            color: AppColors.blackLight.withOpacity(0.4),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            operation.timestamp != null
                                ? timeFormat.format(operation.timestamp!)
                                : 'N/A',
                            style: TextStyles.customStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blackLight.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),

                      // Payment Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: hasDebt
                              ? AppColors.error.withOpacity(0.05)
                              : AppColors.success.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          hasDebt
                              ? AppStrings.remainingDebt.tr()
                              : AppStrings.paid.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: hasDebt
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

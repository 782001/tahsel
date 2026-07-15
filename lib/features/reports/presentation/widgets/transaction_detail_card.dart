import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/operation/domain/entities/operation_entity.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class TransactionDetailCard extends StatelessWidget {
  final OperationEntity operation;

  const TransactionDetailCard({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final bool isPlaystation =
        operation.type.toLowerCase() == AppStrings.playStation.toLowerCase();
    final bool hasDebt = operation.remainingDebt > 0;
    final bool hasCredit = operation.remainingDebt < 0;

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
      margin: EdgeInsets.only(bottom: isDesktop ? 16 : 16.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: hasDebt
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.transparent,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
        child: Column(
          children: [
            // Status marker for debt or credit
            if (hasDebt || hasCredit)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: isDesktop ? 4 : 4.h),
                color: (hasDebt ? AppColors.error : AppColors.success)
                    .withValues(alpha: 0.3),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasDebt ? AppStrings.remainingDebt.tr() : AppStrings.customerCredit.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasDebt ? AppColors.error : AppColors.success,
                        ),
                      ),
                      Text(
                        " : ",
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasDebt ? AppColors.error : AppColors.success,
                        ),
                      ),
                      Text(
                        "${operation.remainingDebt.abs().toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasDebt ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon Circle
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 10 : 10.r),
                        decoration: BoxDecoration(
                          color:
                              (isPlaystation
                                      ? AppColors.primaryColor
                                      : AppColors.green)
                                  .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaystation
                              ? Icons.sports_esports_outlined
                              : Icons.shopping_bag_outlined,
                          color: (isPlaystation
                              ? AppColors.primaryColor
                              : AppColors.green),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 12 : 12.w),
                      // Customer and Type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: TextStyles.customStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isDesktop ? 2 : 2.h),
                            Text(
                              subtitleText,
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.blackLight.withValues(
                                  alpha: 0.6,
                                ),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            Text(
                              AppStrings.currencyEgp.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isDesktop ? 16 : 16.h),
                  const Divider(height: 1),

                  // Debt Breakdown Section
                  if (hasDebt) ...[
                    SizedBox(height: isDesktop ? 12 : 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.paidAmount.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blackLight.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(height: isDesktop ? 4 : 4.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${operation.paidAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
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
                          height: isDesktop ? 30 : 30.h,
                          color: AppColors.blackLight.withValues(alpha: 0.1),
                        ),
                        SizedBox(width: isDesktop ? 16 : 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasDebt ? AppStrings.remainingDebt.tr() : AppStrings.customerCredit.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.blackLight.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(height: isDesktop ? 4 : 4.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${hasDebt ? operation.remainingDebt.toSmartAmount() : operation.remainingDebt.abs().toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: hasDebt ? AppColors.error : (hasCredit ? AppColors.success : AppColors.error),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: isDesktop ? 12 : 12.h),

                  // Footer: Date & Time + Payment Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.blackLight.withValues(alpha: 0.4),
                          ),
                          SizedBox(width: isDesktop ? 4 : 4.w),
                          Text(
                            operation.timestamp != null
                                ? dateFormat.format(operation.timestamp!)
                                : 'N/A',
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blackLight.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(width: isDesktop ? 12 : 12.w),
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.blackLight.withValues(alpha: 0.4),
                          ),
                          SizedBox(width: isDesktop ? 4 : 4.w),
                          Text(
                            operation.timestamp != null
                                ? timeFormat.format(operation.timestamp!)
                                : 'N/A',
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blackLight.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Payment Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 8 : 8.w,
                          vertical: isDesktop ? 4 : 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: hasDebt
                              ? AppColors.error.withValues(alpha: 0.05)
                              : AppColors.success.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 8 : 8.r,
                          ),
                        ),
                        child: Text(
                          hasDebt
                              ? AppStrings.remainingDebt.tr()
                              : AppStrings.paid.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 10,
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

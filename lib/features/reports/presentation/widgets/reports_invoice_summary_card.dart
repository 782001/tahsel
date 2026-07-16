import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class ReportsInvoiceSummaryCard extends StatelessWidget {
  final int invoiceCount;
  final double invoiceValue;
  final double invoiceCollected;
  final double invoiceRemaining;
  final int invoicePaidCount;
  final int invoicePartialCount;
  final int invoiceUnpaidCount;
  final VoidCallback? onTap;

  const ReportsInvoiceSummaryCard({
    super.key,
    required this.invoiceCount,
    required this.invoiceValue,
    required this.invoiceCollected,
    required this.invoiceRemaining,
    required this.invoicePaidCount,
    required this.invoicePartialCount,
    required this.invoiceUnpaidCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      width: double.infinity,
      margin: isDesktop
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.stitchSurfaceLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: AppColors.primaryColor,
                            size: 20.r,
                          ),
                        ),
                        12.horizontalSpace,
                        Text(
                          AppStrings.invoices.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    // Total count badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        "${AppStrings.totalInvoices.tr()}: $invoiceCount",
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Main total value
                Text(
                  AppStrings.invoiceTotalValue.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blackLight.withValues(alpha: 0.5),
                  ),
                ),
                SizedBox(height: 4.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        invoiceValue.toSmartAmount(),
                        style: TextStyles.customStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        AppStrings.currencyEgp.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackLight.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Collected & Remaining split
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.invoiceCollected.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackLight.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${invoiceCollected.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
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
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.invoiceRemainingAmount.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackLight.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${invoiceRemaining.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Status breakdown pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusPill(
                      label: AppStrings.invoicePaidCountKey.tr(),
                      count: invoicePaidCount,
                      color: AppColors.success,
                    ),
                    8.horizontalSpace,
                    _buildStatusPill(
                      label: AppStrings.invoicePartialCountKey.tr(),
                      count: invoicePartialCount,
                      color: AppColors.warning,
                    ),
                    8.horizontalSpace,
                    _buildStatusPill(
                      label: AppStrings.invoiceUnpaidCountKey.tr(),
                      count: invoiceUnpaidCount,
                      color: AppColors.error,
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

  Widget _buildStatusPill({
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyles.customStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              "$count",
              style: TextStyles.customStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

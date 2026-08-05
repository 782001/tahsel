import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/order_reconciliation_item.dart';

class OrderDetailsHeader extends StatelessWidget {
  final OrderReconciliationItem item;

  const OrderDetailsHeader({super.key, required this.item});

  Color _getStatusColor(OrderMatchStatus status) {
    switch (status) {
      case OrderMatchStatus.matched:
        return AppColors.reconciliationMatched;
      case OrderMatchStatus.missingFromShipping:
        return AppColors.reconciliationMissing;
      case OrderMatchStatus.shippingReportOnly:
        return AppColors.reconciliationReportOnly;
      case OrderMatchStatus.conflict:
        return AppColors.reconciliationConflict;
      case OrderMatchStatus.duplicate:
        return AppColors.reconciliationDuplicate;
    }
  }

  Color _getStatusBgColor(OrderMatchStatus status) {
    switch (status) {
      case OrderMatchStatus.matched:
        return AppColors.reconciliationMatchedBg;
      case OrderMatchStatus.missingFromShipping:
        return AppColors.reconciliationMissingBg;
      case OrderMatchStatus.shippingReportOnly:
        return AppColors.reconciliationReportOnlyBg;
      case OrderMatchStatus.conflict:
        return AppColors.reconciliationConflictBg;
      case OrderMatchStatus.duplicate:
        return AppColors.reconciliationDuplicateBg;
    }
  }

  String _getStatusText(OrderMatchStatus status) {
    switch (status) {
      case OrderMatchStatus.matched:
        return AppStrings.matchStatusMatched.tr();
      case OrderMatchStatus.missingFromShipping:
        return AppStrings.matchStatusMissingFromShipping.tr();
      case OrderMatchStatus.shippingReportOnly:
        return AppStrings.matchStatusShippingReportOnly.tr();
      case OrderMatchStatus.conflict:
        return AppStrings.matchStatusConflict.tr();
      case OrderMatchStatus.duplicate:
        return AppStrings.matchStatusDuplicate.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final statusColor = _getStatusColor(item.matchStatus);
    final statusBgColor = _getStatusBgColor(item.matchStatus);
    final statusText = _getStatusText(item.matchStatus);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          margin: EdgeInsets.only(
            top: isDesktop ? 10 : 10.h,
            bottom: isDesktop ? 6 : 6.h,
          ),
          width: isDesktop ? 45 : 45.w,
          height: isDesktop ? 5 : 5.h,
          decoration: BoxDecoration(
            color: AppColors.sandText.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),

        // Main Header Container
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 16.w,
            vertical: isDesktop ? 10 : 8.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Order Icon + Order Code + Status Badge + Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Order Code Box
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isDesktop ? 8 : 8.r),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primaryColor,
                            size: isDesktop ? 20 : 20.r,
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.orderMatchDetails.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 11 : 11,
                                  color: AppColors.sandText,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.displayOrderNumber.isEmpty
                                          ? AppStrings.unspecified.tr()
                                          : item.displayOrderNumber,
                                      style: TextStyles.customStyle(
                                        fontSize: isDesktop ? 15 : 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.displayOrderNumber.isNotEmpty)
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: item.displayOrderNumber,
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'تم نسخ رقم الطلب (${item.displayOrderNumber})',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          isDesktop ? 4 : 4.r,
                                        ),
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: isDesktop ? 14 : 14.r,
                                          color: AppColors.primaryColor,
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

                  SizedBox(width: isDesktop ? 8 : 8.w),

                  // Match Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 8 : 8.w,
                      vertical: isDesktop ? 4 : 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7.r,
                          height: 7.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        SizedBox(width: isDesktop ? 5 : 5.w),
                        Text(
                          statusText,
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 11 : 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: isDesktop ? 4 : 4.w),

                  // Close Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.primaryColor,
                      size: isDesktop ? 22 : 22.r,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 10 : 8.h),

              // Bottom Row: Customer Name & Phone Chips
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 12 : 12.w,
                  vertical: isDesktop ? 8 : 8.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.stitchSurfaceLow,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    // Customer Name
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: isDesktop ? 16 : 16.r,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: isDesktop ? 6 : 6.w),
                          Expanded(
                            child: Text(
                              item.displayCustomerName.isEmpty
                                  ? AppStrings.unspecified.tr()
                                  : item.displayCustomerName,
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 12 : 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackReal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 14.h,
                      width: 1,
                      color: AppColors.sandText.withValues(alpha: 0.3),
                      margin: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 8 : 8.w,
                      ),
                    ),

                    // Phone Number
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: isDesktop ? 16 : 16.r,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: isDesktop ? 6 : 6.w),
                          Expanded(
                            child: Text(
                              item.displayPhone.isEmpty
                                  ? AppStrings.unspecified.tr()
                                  : item.displayPhone,
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 12 : 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blackReal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: AppColors.sandText.withValues(alpha: 0.2)),
      ],
    );
  }
}

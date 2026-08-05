import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/order_reconciliation_item.dart';
import 'order_details_bottom_sheet.dart';

class OrderResultTile extends StatelessWidget {
  final OrderReconciliationItem item;

  const OrderResultTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Card(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 10.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
        side: BorderSide(color: AppColors.sandText.withValues(alpha: 0.15)),
      ),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
        onTap: () => OrderDetailsBottomSheet.show(context, item),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Order Number & Match Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: isDesktop ? 18 : 18.r,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: isDesktop ? 6 : 6.w),
                      Text(
                        item.displayOrderNumber,
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackReal,
                        ),
                      ),
                    ],
                  ),
                  _buildMatchBadge(item.matchStatus, isDesktop),
                ],
              ),
              SizedBox(height: isDesktop ? 8 : 8.h),

              // Customer & Phone Row
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: isDesktop ? 15 : 15.r,
                    color: AppColors.sandText,
                  ),
                  SizedBox(width: isDesktop ? 4 : 4.w),
                  Expanded(
                    child: Text(
                      item.displayCustomerName,
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        color: AppColors.blackReal,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.phone_rounded,
                    size: isDesktop ? 15 : 15.r,
                    color: AppColors.sandText,
                  ),
                  SizedBox(width: isDesktop ? 4 : 4.w),
                  Text(
                    item.displayPhone,
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      color: AppColors.sandText,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 10 : 10.h),

              // Status Badges & Financial Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildShippingBadge(item.shippingStatus, isDesktop),
                      SizedBox(width: isDesktop ? 6 : 6.w),
                      _buildCollectionBadge(item.collectionStatus, isDesktop),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppStrings.collectionCollected.tr()}: ${item.collectedAmount.toSmartAmount()} / ${item.requiredAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackReal,
                        ),
                      ),
                      if (item.remainingAmount > 0)
                        Text(
                          '${AppStrings.collectionRemaining.tr()}: ${item.remainingAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                          style: TextStyles.customStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.shippingReturned,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              if (item.discrepancyNotes.isNotEmpty) ...[
                SizedBox(height: isDesktop ? 8 : 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 10 : 10.w,
                    vertical: isDesktop ? 6 : 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.reconciliationConflictBg,
                    borderRadius: BorderRadius.circular(isDesktop ? 8 : 8.r),
                    border: Border.all(
                      color: AppColors.reconciliationConflict.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: isDesktop ? 15 : 15.r,
                        color: AppColors.reconciliationConflict,
                      ),
                      SizedBox(width: isDesktop ? 6 : 6.w),
                      Expanded(
                        child: Text(
                          item.discrepancyNotes.first,
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            color: AppColors.reconciliationConflict,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBadge(OrderMatchStatus status, bool isDesktop) {
    String text;
    Color color;
    Color bg;

    switch (status) {
      case OrderMatchStatus.matched:
        text = AppStrings.matchStatusMatched.tr();
        color = AppColors.reconciliationMatched;
        bg = AppColors.reconciliationMatchedBg;
        break;
      case OrderMatchStatus.missingFromShipping:
        text = AppStrings.matchStatusMissingFromShipping.tr();
        color = AppColors.reconciliationMissing;
        bg = AppColors.reconciliationMissingBg;
        break;
      case OrderMatchStatus.shippingReportOnly:
        text = AppStrings.matchStatusShippingReportOnly.tr();
        color = AppColors.reconciliationReportOnly;
        bg = AppColors.reconciliationReportOnlyBg;
        break;
      case OrderMatchStatus.conflict:
        text = AppStrings.matchStatusConflict.tr();
        color = AppColors.reconciliationConflict;
        bg = AppColors.reconciliationConflictBg;
        break;
      case OrderMatchStatus.duplicate:
        text = AppStrings.matchStatusDuplicate.tr();
        color = AppColors.reconciliationDuplicate;
        bg = AppColors.reconciliationDuplicateBg;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 8 : 8.w,
        vertical: isDesktop ? 4 : 4.h,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyles.customStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildShippingBadge(ShippingStatusCategory status, bool isDesktop) {
    String text;
    Color color;

    switch (status) {
      case ShippingStatusCategory.delivered:
        text = AppStrings.deliveredFilter.tr();
        color = AppColors.success;
        break;
      case ShippingStatusCategory.returned:
        text = AppStrings.returnedFilter.tr();
        color = AppColors.reconciliationConflict;
        break;
      case ShippingStatusCategory.outForDelivery:
        text = AppStrings.statusOutForDelivery.tr();
        color = Colors.blue.shade700;
        break;
      case ShippingStatusCategory.shipped:
        text = AppStrings.statusShipped.tr();
        color = Colors.cyan.shade700;
        break;
      case ShippingStatusCategory.failedDelivery:
        text = AppStrings.statusFailedDelivery.tr();
        color = Colors.orange.shade700;
        break;
      case ShippingStatusCategory.notShipped:
        text = AppStrings.statusNotShipped.tr();
        color = Colors.grey.shade700;
        break;
      case ShippingStatusCategory.unknown:
        text = AppStrings.statusUnknown.tr();
        color = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 8 : 8.w,
        vertical: isDesktop ? 4 : 3.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 6.r),
      ),
      child: Text(
        text,
        style: TextStyles.customStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCollectionBadge(
    CollectionStatusCategory status,
    bool isDesktop,
  ) {
    String text;
    Color color;

    switch (status) {
      case CollectionStatusCategory.fullyCollected:
        text = AppStrings.fullyCollectedCount.tr();
        color = Colors.teal.shade700;
        break;
      case CollectionStatusCategory.partiallyCollected:
        text = AppStrings.partiallyCollectedCount.tr();
        color = Colors.amber.shade900;
        break;
      case CollectionStatusCategory.notCollected:
        text = AppStrings.notCollectedCount.tr();
        color = Colors.red.shade700;
        break;
      case CollectionStatusCategory.overCollected:
        text = AppStrings.fullyCollectedCount.tr();
        color = Colors.indigo.shade700;
        break;
      case CollectionStatusCategory.amountMismatch:
        text = AppStrings.matchStatusConflict.tr();
        color = Colors.orange.shade900;
        break;
      case CollectionStatusCategory.unknown:
        text = AppStrings.statusUnknown.tr();
        color = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 8 : 8.w,
        vertical: isDesktop ? 4 : 3.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isDesktop ? 6 : 6.r),
      ),
      child: Text(
        text,
        style: TextStyles.customStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

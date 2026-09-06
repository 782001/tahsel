import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_purchase_entity.dart';

class SupplierPurchaseCard extends StatefulWidget {
  final InventoryPurchaseEntity purchase;

  const SupplierPurchaseCard({super.key, required this.purchase});

  @override
  State<SupplierPurchaseCard> createState() => SupplierPurchaseCardState();
}

class SupplierPurchaseCardState extends State<SupplierPurchaseCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final dateStr = DateFormat(
      'yyyy/MM/dd - hh:mm a',
    ).format(widget.purchase.createdAt);

    final itemsToDisplay = (_isExpanded || widget.purchase.items.length <= 2)
        ? widget.purchase.items
        : widget.purchase.items.take(2).toList();

    final hasMoreItems = widget.purchase.items.length > 2;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.purchaseInvoiceNum.tr()} #${widget.purchase.id.substring(widget.purchase.id.length > 8 ? widget.purchase.id.length - 8 : 0)}',
                style: TextStyles.customStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackReal,
                ),
              ),
              Text(
                '${widget.purchase.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                style: TextStyles.customStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 4 : 4.h),
          Text(
            dateStr,
            style: TextStyles.customStyle(
              fontSize: 12,
              color: AppColors.sandText,
            ),
          ),
          const Divider(),
          Column(
            children: itemsToDisplay
                .map((item) => _buildItemRow(item, isDesktop))
                .toList(),
          ),
          if (hasMoreItems) ...[
            SizedBox(height: isDesktop ? 6 : 6.h),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded
                          ? AppStrings.showLess.tr()
                          : '${AppStrings.showMore.tr()} (+${widget.purchase.items.length - 2})',
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inventoryPurchasePurple,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.inventoryPurchasePurple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(InventoryPurchaseItemEntity item, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 10 : 10.w,
        vertical: isDesktop ? 6 : 6.h,
      ),
      margin: EdgeInsets.symmetric(vertical: isDesktop ? 3 : 3.h),
      decoration: BoxDecoration(
        color: AppColors.scafoldBackGround.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 6 : 6.w,
            height: isDesktop ? 6 : 6.h,
            decoration: BoxDecoration(
              color: AppColors.inventoryPurchasePurple,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isDesktop ? 8 : 8.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackReal,
                  ),
                ),
                SizedBox(height: isDesktop ? 1 : 1.h),
                Row(
                  children: [
                    Text(
                      '${item.quantity.toSmartAmount()} ${item.unit != null && item.unit!.isNotEmpty ? item.unit! : AppStrings.unit.tr()} × ${item.purchasePrice.toSmartAmount()}',
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        color: AppColors.sandText,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 8 : 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 6 : 6.w,
                        vertical: isDesktop ? 2 : 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '${item.subtotal.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
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
    );
  }
}

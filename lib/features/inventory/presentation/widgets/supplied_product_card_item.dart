import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_product_entity.dart';

class SuppliedProductCardItem extends StatelessWidget {
  final InventoryProductEntity product;

  const SuppliedProductCardItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final p = product;

    final isOut = p.currentQuantity <= 0;
    final isLow = p.isLowStock && !isOut;
    final statusColor = isOut
        ? AppColors.error
        : isLow
        ? AppColors.lowStockOrange
        : AppColors.success;

    final statusLabel = isOut
        ? AppStrings.outOfStock.tr()
        : isLow
        ? AppStrings.lowStockAlert.tr()
        : AppStrings.stableStock.tr();

    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isOut || isLow
              ? statusColor.withValues(alpha: 0.5)
              : AppColors.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status badge & Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 8 : 8.w,
                  vertical: isDesktop ? 3 : 3.h,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (p.categoryName.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 8 : 8.w,
                    vertical: isDesktop ? 3 : 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.scafoldBackGround,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.dividerColor),
                  ),
                  child: Text(
                    p.categoryName,
                    style: TextStyles.customStyle(
                      fontSize: 11,
                      color: AppColors.sandText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isDesktop ? 10 : 10.h),
          // Product Info Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 10 : 10.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryColor,
                  size: isDesktop ? 22 : 20.r,
                ),
              ),
              SizedBox(width: isDesktop ? 10 : 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                    if (p.sku.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 8 : 6.w,
                          vertical: isDesktop ? 2 : 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.scafoldBackGround,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: AppColors.dividerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 12,
                              color: AppColors.sandText,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              p.sku,
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sandText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (p.barcode != null && p.barcode!.isNotEmpty) ...[
                      SizedBox(width: isDesktop ? 6 : 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 8 : 6.w,
                          vertical: isDesktop ? 2 : 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 11,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              p.barcode!,
                              style: TextStyles.customStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),
          const Divider(height: 1),
          SizedBox(height: isDesktop ? 10 : 10.h),
          // Price & Stock details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Purchase & Selling Prices
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.purchasePrice.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: AppColors.sandText,
                        ),
                      ),
                      Text(
                        '${p.purchasePrice.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackReal,
                        ),
                      ),
                    ],
                  ),
                  if (p.sellingPrice > 0) ...[
                    SizedBox(width: isDesktop ? 16 : 16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.sellingPrice.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 11,
                            color: AppColors.sandText,
                          ),
                        ),
                        Text(
                          '${p.sellingPrice.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                          style: TextStyles.customStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              // Current Quantity Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 10 : 10.w,
                  vertical: isDesktop ? 5 : 5.h,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 14, color: statusColor),
                    SizedBox(width: 4.w),
                    Text(
                      '${p.currentQuantity.toSmartAmount()} ${p.unit}',
                      style: TextStyles.customStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../../domain/entities/inventory_product_entity.dart';

class ProductCardItem extends StatelessWidget {
  final InventoryProductEntity product;
  final int index;
  final bool isBestSeller;
  final VoidCallback onTap;
  final VoidCallback onManualAdjustment;
  final VoidCallback onEdit;

  const ProductCardItem({
    super.key,
    required this.product,
    required this.index,
    this.isBestSeller = false,
    required this.onTap,
    required this.onManualAdjustment,
    required this.onEdit,
  });

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

    return FadeInUp(
      duration: Duration(milliseconds: 200 + (index * 30).clamp(0, 300)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isOut || isLow
                    ? statusColor.withValues(alpha: 0.6)
                    : AppColors.surface,
                width: isOut || isLow ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 8 : 8.w,
                        vertical: isDesktop ? 3 : 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
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
                    if (isBestSeller) ...[
                      SizedBox(width: isDesktop ? 8 : 8.w),
                      Transform.rotate(
                        angle: -0.12,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 9 : 9.w,
                            vertical: isDesktop ? 4 : 4.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.bestSellerStart,
                                AppColors.bestSellerEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 8 : 8.r,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.bestSellerStart.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: isDesktop ? 3 : 3.w),
                              Text(
                                AppStrings.bestSeller.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 10.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: AppColors.lowStockOrange,
                      ),
                      onPressed: onManualAdjustment,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_note,
                        color: AppColors.primaryColor,
                      ),
                      onPressed: onEdit,
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 8 : 8.h),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      radius: isDesktop ? 22 : 22.r,
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: statusColor,
                        size: isDesktop ? 22 : 20,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 14 : 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyles.customStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blackReal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isDesktop ? 6 : 6.h),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (p.sku.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 8 : 6.w,
                                    vertical: isDesktop ? 2 : 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.scafoldBackGround,
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: AppColors.dividerColor,
                                    ),
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
                               if (p.barcode != null &&
                                  p.barcode!.isNotEmpty) ...[
                                SizedBox(width: isDesktop ? 6 : 4.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 8 : 6.w,
                                    vertical: isDesktop ? 2 : 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.08,
                                    ),
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

                              // if (p.supplierName.isNotEmpty)
                              //   Container(
                              //     padding: EdgeInsets.symmetric(
                              //       horizontal: isDesktop ? 8 : 6.w,
                              //       vertical: isDesktop ? 2 : 2.h,
                              //     ),
                              //     decoration: BoxDecoration(
                              //       color: AppColors.inventorySupplierTeal.withValues(
                              //         alpha: 0.1,
                              //       ),
                              //       borderRadius: BorderRadius.circular(
                              //         6.r,
                              //       ),
                              //       border: Border.all(
                              //         color: AppColors.inventorySupplierTeal.withValues(
                              //           alpha: 0.3,
                              //         ),
                              //       ),
                              //     ),
                              //     child: Row(
                              //       mainAxisSize: MainAxisSize.min,
                              //       children: [
                              //         Icon(
                              //           Icons.local_shipping_outlined,
                              //           size: 12,
                              //           color: AppColors.inventorySupplierTeal,
                              //         ),
                              //         SizedBox(
                              //           width: 4.w,
                              //         ),
                              //         Text(
                              //           '${AppStrings.supplier.tr()}: ${p.supplierName}',
                              //           style: TextStyles.customStyle(
                              //             fontSize: 11,
                              //             fontWeight: FontWeight.w600,
                              //             color: AppColors.inventorySupplierTeal,
                              //           ),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                            ],
                          ),
                          SizedBox(height: isDesktop ? 6 : 6.h),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 8 : 6.w,
                                  vertical: isDesktop ? 3 : 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${AppStrings.quantity.tr()}: ${p.currentQuantity.toSmartAmount()} ${p.unit}',
                                      style: TextStyles.customStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 8 : 6.w,
                                  vertical: isDesktop ? 3 : 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sell_outlined,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${AppStrings.sellingPrice.tr()}: ${p.sellingPrice.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                                      style: TextStyles.customStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
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
}

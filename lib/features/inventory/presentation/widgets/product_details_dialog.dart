import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import '../../domain/entities/inventory_product_entity.dart';

class ProductDetailsDialog extends StatelessWidget {
  final InventoryProductEntity product;
  final VoidCallback onEdit;
  final VoidCallback onAdjustStock;

  const ProductDetailsDialog({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isOut = product.currentQuantity <= 0;
    final isLow = product.isLowStock && !isOut;

    final statusColor = isOut
        ? AppColors.error
        : isLow
            ? AppColors.warning
            : AppColors.success;

    final statusText = isOut
        ? AppStrings.outOfStock.tr()
        : isLow
            ? AppStrings.lowStockCount.tr()
            : AppStrings.stableStock.tr();

    final profitMargin = product.purchasePrice > 0
        ? (((product.sellingPrice - product.purchasePrice) / product.purchasePrice) * 100).toStringAsFixed(1)
        : '0';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 10 : 10.w),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: AppColors.primaryColor,
                          size: isDesktop ? 24 : 24.sp,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 12 : 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyles.customStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackReal,
                            ),
                          ),
                          Text(
                            'SKU: ${product.sku}',
                            style: TextStyles.customStyle(
                              fontSize: 12,
                              color: AppColors.sandText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.blackLight),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: isDesktop ? 12 : 12.h),

              // Content Body
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Stock Status Banner
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 16 : 16.w,
                          vertical: isDesktop ? 12 : 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isOut
                                      ? Icons.remove_shopping_cart_rounded
                                      : isLow
                                          ? Icons.warning_amber_rounded
                                          : Icons.check_circle_rounded,
                                  color: statusColor,
                                  size: 22,
                                ),
                                SizedBox(width: isDesktop ? 8 : 8.w),
                                Text(
                                  statusText,
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${product.currentQuantity.toStringAsFixed(0)} ${product.unit}',
                              style: TextStyles.customStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isDesktop ? 16 : 16.h),

                      // Metrics Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: AppStrings.purchasePrice.tr(),
                              value: '${product.purchasePrice.toStringAsFixed(2)} ${AppStrings.egp.tr()}',
                              icon: Icons.shopping_bag_outlined,
                              color: AppColors.primaryColor,
                              isDesktop: isDesktop,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 10 : 10.w),
                          Expanded(
                            child: _buildMetricTile(
                              label: AppStrings.sellingPrice.tr(),
                              value: '${product.sellingPrice.toStringAsFixed(2)} ${AppStrings.egp.tr()}',
                              icon: Icons.sell_outlined,
                              color: AppColors.success,
                              isDesktop: isDesktop,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isDesktop ? 10 : 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: AppStrings.minQuantity.tr(),
                              value: '${product.minQuantity.toStringAsFixed(0)} ${product.unit}',
                              icon: Icons.compress_rounded,
                              color: AppColors.sandText,
                              isDesktop: isDesktop,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 10 : 10.w),
                          Expanded(
                            child: _buildMetricTile(
                              label: AppStrings.profitMargin.tr(),
                              value: '+$profitMargin%',
                              icon: Icons.trending_up_rounded,
                              color: AppColors.inventoryPurchasePurple,
                              isDesktop: isDesktop,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isDesktop ? 16 : 16.h),

                      // Category & Supplier Section
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
                        decoration: BoxDecoration(
                          color: AppColors.scafoldBackGround,
                          borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
                          border: Border.all(color: AppColors.dividerColor),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.category_outlined,
                              label: AppStrings.category.tr(),
                              value: product.categoryName.isNotEmpty ? product.categoryName : AppStrings.noCategory.tr(),
                              isDesktop: isDesktop,
                            ),
                            const Divider(height: 16),
                            _buildInfoRow(
                              icon: Icons.local_shipping_outlined,
                              label: AppStrings.supplier.tr(),
                              value: product.supplierName.isNotEmpty ? product.supplierName : AppStrings.noSupplier.tr(),
                              isDesktop: isDesktop,
                            ),
                            if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                              const Divider(height: 16),
                              _buildInfoRow(
                                icon: Icons.qr_code_rounded,
                                label: AppStrings.barcode.tr(),
                                value: product.barcode!,
                                isDesktop: isDesktop,
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (product.notes != null && product.notes!.isNotEmpty) ...[
                        SizedBox(height: isDesktop ? 12 : 12.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                            border: Border.all(color: AppColors.dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.notes.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandText,
                                ),
                              ),
                              SizedBox(height: isDesktop ? 4 : 4.h),
                              Text(
                                product.notes!,
                                style: TextStyles.customStyle(
                                  fontSize: 13,
                                  color: AppColors.blackReal,
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

              SizedBox(height: isDesktop ? 16 : 16.h),

              // Bottom Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isDesktop ? 12 : 12.h),
                        side: BorderSide(color: AppColors.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onAdjustStock();
                      },
                      icon: Icon(Icons.tune_rounded, color: AppColors.primaryColor, size: 18),
                      label: Text(
                        AppStrings.manualStockAdjustment.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isDesktop ? 10 : 10.w),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 20 : 20.w,
                        vertical: isDesktop ? 12 : 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    label: Text(
                      AppStrings.edit.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: isDesktop ? 8 : 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    color: AppColors.sandText,
                  ),
                ),
                Text(
                  value,
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackReal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDesktop,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.sandText),
        SizedBox(width: isDesktop ? 10 : 10.w),
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 13,
            color: AppColors.sandText,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyles.customStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.blackReal,
          ),
        ),
      ],
    );
  }
}

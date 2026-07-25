import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

import '../../domain/entities/inventory_product_entity.dart';
import 'inventory_tab_selector.dart';

class ManualStockAdjustmentDialog extends StatefulWidget {
  final InventoryProductEntity product;
  final Function(double delta, String reason) onAdjust;

  const ManualStockAdjustmentDialog({
    super.key,
    required this.product,
    required this.onAdjust,
  });

  @override
  State<ManualStockAdjustmentDialog> createState() =>
      _ManualStockAdjustmentDialogState();
}

class _ManualStockAdjustmentDialogState
    extends State<ManualStockAdjustmentDialog> {
  int _selectedTab = 0; // 0 = addition, 1 = subtraction
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _reasonController = TextEditingController();

  bool get _isAddition => _selectedTab == 0;

  double get _enteredQty => double.tryParse(_qtyController.text.trim()) ?? 0;

  double get _projectedQty => _isAddition
      ? widget.product.currentQuantity + _enteredQty
      : (widget.product.currentQuantity - _enteredQty).clamp(
          0.0,
          double.infinity,
        );

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_onQtyChanged);
  }

  void _onQtyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _qtyController.removeListener(_onQtyChanged);
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _adjustQty(double step) {
    final current = double.tryParse(_qtyController.text.trim()) ?? 0;
    final next = (current + step).clamp(1.0, 999999.0);
    _qtyController.text = next.toSmartAmount();
  }

  void _submit() {
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    final reason = _reasonController.text.trim();

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseEnterQtyGreaterThanZero.tr())),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseEnterAdjustmentReason.tr())),
      );
      return;
    }

    final delta = _isAddition ? qty : -qty;
    widget.onAdjust(delta, reason);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final themeColor = _isAddition
        ? AppColors.stockAdditionGreen
        : AppColors.stockSubtractionRed;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 22 : 18.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 10 : 8.w),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: themeColor,
                      size: isDesktop ? 22 : 20.sp,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 10.w),
                  Expanded(
                    child: Text(
                      AppStrings.manualStockAdjustment.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 6 : 6.w),
                      decoration: BoxDecoration(
                        color: AppColors.scafoldBackGround,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.sandText,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 16 : 14.h),

              // Smart Product Card Live Preview
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 14 : 12.w,
                  vertical: isDesktop ? 12 : 10.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scafoldBackGround.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.dividerColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          '${AppStrings.quantity.tr()}: ${widget.product.currentQuantity.toSmartAmount()} ${widget.product.unit}',
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            color: AppColors.sandText,
                          ),
                        ),
                        if (_enteredQty > 0) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: Icon(
                              AppStrings.currentLang == 'ar'
                                  ? Icons.west_rounded
                                  : Icons.east_rounded,
                              size: 12,
                              color: themeColor,
                            ),
                          ),
                          Text(
                            '${_projectedQty.toSmartAmount()} ${widget.product.unit}',
                            style: TextStyles.customStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 16 : 14.h),

              // Operation Tab Selector
              InventoryTabSelector(
                tabs: [
                  (AppStrings.increaseStock.tr()),
                  (AppStrings.decreaseStock.tr()),
                ],
                selectedIndex: _selectedTab,
                onTabChanged: (index) => setState(() => _selectedTab = index),
              ),
              SizedBox(height: isDesktop ? 14 : 14.h),

              // Quantity Input with Stepper Controls
              Row(
                children: [
                  Expanded(
                    child: QuickAddTextField(
                      controller: _qtyController,
                      isNumber: true,
                      labelText: AppStrings.quantity.tr(),
                      hint: AppStrings.quantity.tr(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.scafoldBackGround,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.dividerColor),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 18),
                          onPressed: () => _adjustQty(-1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          onPressed: () => _adjustQty(1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 10 : 8.h),

              // Quick Amount Pills
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [1, 5, 10, 50, 100].map((val) {
                  return InkWell(
                    onTap: () => _qtyController.text = val.toString(),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 10 : 8.w,
                        vertical: isDesktop ? 4 : 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: themeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '+$val',
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: isDesktop ? 14 : 12.h),

              // Adjustment Reason Field
              QuickAddTextField(
                controller: _reasonController,
                maxLines: 2,
                labelText: AppStrings.adjustmentReason.tr(),
                hint: AppStrings.adjustmentReasonHint.tr(),
              ),
              SizedBox(height: isDesktop ? 8 : 6.h),

              // Quick Reason Chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children:
                    (_isAddition
                            ? [
                                AppStrings.reasonPeriodicInventory.tr(),
                                AppStrings.reasonSurplusGoods.tr(),
                                AppStrings.reasonUnregisteredPurchases.tr(),
                                AppStrings.reasonErrorCorrection.tr(),
                              ]
                            : [
                                AppStrings.reasonDamagedScrap.tr(),
                                AppStrings.reasonPeriodicInventory.tr(),
                                AppStrings.reasonSampleDemo.tr(),
                                AppStrings.reasonManualDeduction.tr(),
                              ])
                        .map((reason) {
                          return InkWell(
                            onTap: () => _reasonController.text = reason,
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 8 : 6.w,
                                vertical: isDesktop ? 3 : 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.scafoldBackGround,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.dividerColor,
                                ),
                              ),
                              child: Text(
                                reason,
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  color: AppColors.sandText,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
              ),
              SizedBox(height: isDesktop ? 20 : 18.h),

              // Dynamic Submit Button
              SizedBox(
                width: double.infinity,
                height: isDesktop ? 48 : 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 12.r,
                      ),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _submit,
                  child: Text(
                    _isAddition
                        ? '${AppStrings.confirmManualAdjustment.tr()} (+${_enteredQty.toSmartAmount()})'
                        : '${AppStrings.confirmManualAdjustment.tr()} (-${_enteredQty.toSmartAmount()})',
                    style: TextStyles.customStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

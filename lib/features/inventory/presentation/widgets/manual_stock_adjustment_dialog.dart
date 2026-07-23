import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  State<ManualStockAdjustmentDialog> createState() => _ManualStockAdjustmentDialogState();
}

class _ManualStockAdjustmentDialogState extends State<ManualStockAdjustmentDialog> {
  int _selectedTab = 0; // 0 = addition, 1 = subtraction
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _reasonController = TextEditingController();

  bool get _isAddition => _selectedTab == 0;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    final reason = _reasonController.text.trim();

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كمية أكبر من صفر')),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة سبب التعديل')),
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

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 18.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.manualStockAdjustment.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackReal,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 6 : 6.h),
              Text(
                'المنتج: ${widget.product.name} (${widget.product.currentQuantity} ${widget.product.unit})',
                style: TextStyles.customStyle(fontSize: 13, color: AppColors.sandText),
              ),
              SizedBox(height: isDesktop ? 16 : 16.h),

              // Type Selector — DebtsTabSelector style
              InventoryTabSelector(
                tabs: const ['زيادة مخزون (+)', 'خصم مخزون (-)'],
                selectedIndex: _selectedTab,
                onTabChanged: (index) => setState(() => _selectedTab = index),
              ),
              SizedBox(height: isDesktop ? 14 : 14.h),

              QuickAddTextField(
                controller: _qtyController,
                isNumber: true,
                labelText: AppStrings.quantity.tr(),
                hint: AppStrings.quantity.tr(),
              ),
              SizedBox(height: isDesktop ? 12 : 12.h),

              QuickAddTextField(
                controller: _reasonController,
                maxLines: 2,
                labelText: AppStrings.adjustmentReason.tr(),
                hint: 'مثال: تلف، جرد سنوي، تسوية',
              ),
              SizedBox(height: isDesktop ? 20 : 20.h),

              SizedBox(
                width: double.infinity,
                height: isDesktop ? 46 : 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAddition ? AppColors.stockAdditionGreen : AppColors.stockSubtractionRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    'تأكيد التعديل اليدوي',
                    style: TextStyles.customStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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

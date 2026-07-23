import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import '../../domain/entities/inventory_product_entity.dart';

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
  bool _isAddition = true;
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _reasonController = TextEditingController();

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
              SizedBox(height: 6.h),
              Text(
                'المنتج: ${widget.product.name} (${widget.product.currentQuantity} ${widget.product.unit})',
                style: TextStyles.customStyle(fontSize: 13, color: AppColors.sandText),
              ),
              SizedBox(height: 16.h),

              // Type Selector
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('زيادة مخزون (+)')),
                      selected: _isAddition,
                      selectedColor: Colors.green.withValues(alpha: 0.2),
                      onSelected: (val) => setState(() => _isAddition = true),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('خصم مخزون (-)')),
                      selected: !_isAddition,
                      selectedColor: Colors.red.withValues(alpha: 0.2),
                      onSelected: (val) => setState(() => _isAddition = false),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.quantity.tr(),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 12.h),

              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: AppStrings.adjustmentReason.tr(),
                  hintText: 'مثال: تلف، جرد سنوي، تسوية',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAddition ? Colors.green[700] : Colors.red[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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

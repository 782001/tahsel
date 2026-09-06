import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

/// A single editable line-item row used inside the invoice form.
class InvoiceItemRow extends StatefulWidget {
  final int index;
  final TextEditingController descController;
  final TextEditingController priceController;
  final TextEditingController qtyController;
  final TextEditingController unitController;
  final TextEditingController discountController;
  final double? purchasePrice;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const InvoiceItemRow({
    super.key,
    required this.index,
    required this.descController,
    required this.priceController,
    required this.qtyController,
    required this.unitController,
    required this.discountController,
    this.purchasePrice,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<InvoiceItemRow> createState() => _InvoiceItemRowState();
}

class _InvoiceItemRowState extends State<InvoiceItemRow> {
  @override
  Widget build(BuildContext context) {
    final qty = double.tryParse(widget.qtyController.text) ?? 1.0;
    final price = double.tryParse(widget.priceController.text) ?? 0.0;
    final discountAmount =
        double.tryParse(widget.discountController.text) ?? 0.0;
    final subtotal = qty * price;
    final lineTotal = (subtotal - discountAmount).clamp(0.0, double.infinity);

    final effectiveUnitPrice =
        qty > 0 ? ((qty * price) - discountAmount) / qty : (price - discountAmount);
    final hasPurchasePrice =
        widget.purchasePrice != null && widget.purchasePrice! > 0;
    final isBelowCost = hasPurchasePrice &&
        (effectiveUnitPrice < widget.purchasePrice! ||
            lineTotal < (qty * widget.purchasePrice!));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: item number + delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.invoiceItem.tr()} ${widget.index + 1}',
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              InkWell(
                onTap: widget.onRemove,
                borderRadius: BorderRadius.circular(8),
                child: Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description field
          _ItemField(
            controller: widget.descController,
            hint: AppStrings.invoiceItemDescHint.tr(),
            label: AppStrings.invoiceItemDesc.tr(),
            onChanged: (_) => widget.onChanged(),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Price field
              Expanded(
                child: _ItemField(
                  controller: widget.priceController,
                  hint: '0.00',
                  label: AppStrings.invoiceItemPrice.tr(),
                  isNumber: true,
                  suffix: AppStrings.currencyEgp.tr(),
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Quantity field
              SizedBox(
                width: 80,
                child: _ItemField(
                  controller: widget.qtyController,
                  hint: '1',
                  label: AppStrings.invoiceItemQty.tr(),
                  isNumber: true,
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Unit field (e.g. قطعة، كرتونة)
              SizedBox(
                width: 80,
                child: _ItemField(
                  controller: widget.unitController,
                  hint: 'قطعة',
                  label: AppStrings.unit.tr(),
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Discount amount field (in Currency)
              Expanded(
                child: _ItemField(
                  controller: widget.discountController,
                  hint: '0',
                  label: AppStrings.invoiceItemDiscount.tr(),
                  isNumber: true,
                  suffix: AppStrings.currencyEgp.tr(),
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Line total (after discount)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppStrings.invoiceLineTotal.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        color: AppColors.blackLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lineTotal.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                      style: TextStyles.customStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Warning if selling price after discount is below purchase cost
          if (isBelowCost) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.sellingBelowCostWarning
                          .tr()
                          .replaceAll(
                            '{cost}',
                            widget.purchasePrice!.toSmartAmount(),
                          )
                          .replaceAll('{currency}', AppStrings.currencyEgp.tr()),
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final bool isNumber;
  final String? suffix;
  final void Function(String)? onChanged;

  const _ItemField({
    required this.controller,
    required this.hint,
    required this.label,
    this.isNumber = false,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          cursorColor: AppColors.primaryColor,
          controller: controller,
          onChanged: onChanged,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyles.customStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.customStyle(
              fontSize: 14,
              color: AppColors.disabledColor,
            ),
            suffixText: suffix,
            suffixStyle: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.blackLight,
            ),
            filled: true,
            fillColor: AppColors.veryLightGrey,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

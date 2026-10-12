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
  final double taxRate;
  final bool isQuotation;
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
    this.taxRate = 0.0,
    this.isQuotation = false,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<InvoiceItemRow> createState() => _InvoiceItemRowState();
}

class _InvoiceItemRowState extends State<InvoiceItemRow> {
  bool _isTotalExpanded = false;

  void _changeQty(double delta) {
    final currentQty = double.tryParse(widget.qtyController.text) ?? 1.0;
    final newQty = (currentQty + delta).clamp(1.0, 999999.0);
    widget.qtyController.text = newQty.toSmartAmount();
    setState(() {});
    widget.onChanged();
  }

  void _applyDiscountPercent(double percent) {
    final qty = double.tryParse(widget.qtyController.text) ?? 1.0;
    final price = double.tryParse(widget.priceController.text) ?? 0.0;
    final subtotal = qty * price;
    if (subtotal <= 0) return;
    final discount = subtotal * (percent / 100.0);
    widget.discountController.text = discount.toSmartAmount();
    setState(() {});
    widget.onChanged();
  }

  void _clearDiscount() {
    widget.discountController.text = '0';
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final qty = double.tryParse(widget.qtyController.text) ?? 1.0;
    final price = double.tryParse(widget.priceController.text) ?? 0.0;
    final discountAmount =
        double.tryParse(widget.discountController.text) ?? 0.0;
    final subtotal = qty * price;
    final lineTotal = (subtotal - discountAmount).clamp(0.0, double.infinity);
    final hasTax = widget.taxRate > 0;
    final itemTax = hasTax ? lineTotal * (widget.taxRate / 100.0) : 0.0;
    final itemBeforeTax = hasTax ? (lineTotal - itemTax) : lineTotal;

    final effectiveUnitPrice = qty > 0
        ? ((qty * price) - discountAmount) / qty
        : (price - discountAmount);
    final hasPurchasePrice =
        widget.purchasePrice != null && widget.purchasePrice! > 0;
    final isBelowCost =
        hasPurchasePrice &&
        (effectiveUnitPrice < widget.purchasePrice! ||
            lineTotal < (qty * widget.purchasePrice!));
    final currency = AppStrings.currencyEgp.tr();

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
          // Header row: item badge + delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 13,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${AppStrings.invoiceItem.tr()} #${widget.index + 1}',
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onRemove,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.delete.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description field
          InvoiceItemRowItemField(
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
                flex: 3,
                child: InvoiceItemRowItemField(
                  controller: widget.priceController,
                  hint: '0.00',
                  label: AppStrings.invoiceItemPrice.tr(),
                  isNumber: true,
                  suffix: currency,
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Quantity field with stepper controls
              Expanded(
                flex: 2,
                child: InvoiceItemRowItemField(
                  controller: widget.qtyController,
                  hint: '1',
                  label: AppStrings.invoiceItemQty.tr(),
                  isNumber: true,
                  suffixWidget: SizedBox(
                    width: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => _changeQty(-1),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 15,
                              color: AppColors.blackLight,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _changeQty(1),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 15,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
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
                flex: 2,
                child: InvoiceItemRowItemField(
                  controller: widget.discountController,
                  hint: '0',
                  label: AppStrings.invoiceItemDiscount.tr(),
                  isNumber: true,
                  suffix: currency,
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Unit field (e.g. قطعة، كرتونة)
              Expanded(
                flex: 1,
                child: InvoiceItemRowItemField(
                  controller: widget.unitController,
                  hint: AppStrings.unitPieceHint.tr(),
                  label: AppStrings.unit.tr(),
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),

          // Quick discount percentages helper
          if (subtotal > 0) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${AppStrings.quickDiscount.tr()}:',
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    color: AppColors.subTitleColor,
                  ),
                ),
                ...[5, 10, 15, 20].map((pct) {
                  final isSelected =
                      discountAmount > 0 &&
                      ((discountAmount / subtotal) * 100 - pct).abs() < 0.2;
                  return InkWell(
                    onTap: () => _applyDiscountPercent(pct.toDouble()),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '$pct%',
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryColor,
                        ),
                      ),
                    ),
                  );
                }),
                if (discountAmount > 0)
                  InkWell(
                    onTap: _clearDiscount,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 12, color: AppColors.error),
                          const SizedBox(width: 2),
                          Text(
                            AppStrings.clear.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Smart Line Total & Financial Insights
          _buildSmartLineTotalCard(
            subtotal: subtotal,
            discountAmount: discountAmount,
            lineTotal: lineTotal,
            effectiveUnitPrice: effectiveUnitPrice,
            qty: qty,
            price: price,
            unit: widget.unitController.text.trim(),
            hasTax: hasTax,
            itemTax: itemTax,
            itemBeforeTax: itemBeforeTax,
            hasPurchasePrice: hasPurchasePrice,
            isBelowCost: isBelowCost,
            currency: currency,
          ),
        ],
      ),
    );
  }

  /// Builds a smart, contextual summary card for the line item total
  Widget _buildSmartLineTotalCard({
    required double subtotal,
    required double discountAmount,
    required double lineTotal,
    required double effectiveUnitPrice,
    required double qty,
    required double price,
    required String unit,
    required bool hasTax,
    required double itemTax,
    required double itemBeforeTax,
    required bool hasPurchasePrice,
    required bool isBelowCost,
    required String currency,
  }) {
    final discountPercent = subtotal > 0
        ? ((discountAmount / subtotal) * 100).clamp(0.0, 100.0)
        : 0.0;
    final totalCost = hasPurchasePrice ? (widget.purchasePrice! * qty) : 0.0;
    final totalProfit = hasPurchasePrice ? (lineTotal - totalCost) : 0.0;
    final profitMarginPercent = (hasPurchasePrice && lineTotal > 0)
        ? ((totalProfit / lineTotal) * 100).clamp(-999.0, 999.0)
        : 0.0;

    // Determine background, border & status icon based on business condition
    Color cardBg;
    Color cardBorder;
    Color statusIconBg;
    Color statusIconColor;
    IconData statusIcon;

    if (isBelowCost) {
      cardBg = AppColors.warning.withValues(
        alpha: AppColors.isDark ? 0.16 : 0.08,
      );
      cardBorder = AppColors.warning.withValues(alpha: 0.45);
      statusIconBg = AppColors.warning.withValues(alpha: 0.2);
      statusIconColor = AppColors.warning;
      statusIcon = Icons.warning_amber_rounded;
    } else if (hasPurchasePrice && totalProfit > 0) {
      cardBg = AppColors.isDark
          ? const Color(0xFF1B2A20)
          : const Color(0xFFF1F8F4);
      cardBorder = AppColors.success.withValues(alpha: 0.3);
      statusIconBg = AppColors.success.withValues(alpha: 0.15);
      statusIconColor = AppColors.success;
      statusIcon = Icons.trending_up_rounded;
    } else if (discountAmount > 0) {
      cardBg = AppColors.isDark
          ? const Color(0xFF28251C)
          : const Color(0xFFFFFDF5);
      cardBorder = AppColors.orange100.withValues(alpha: 0.3);
      statusIconBg = AppColors.orange100.withValues(alpha: 0.15);
      statusIconColor = AppColors.orange100;
      statusIcon = Icons.local_offer_outlined;
    } else {
      cardBg = AppColors.veryLightGrey;
      cardBorder = AppColors.dividerColor;
      statusIconBg = AppColors.primaryColor.withValues(alpha: 0.1);
      statusIconColor = AppColors.primaryColor;
      statusIcon = Icons.receipt_long_rounded;
    }

    final hasInsights = subtotal > 0 || isBelowCost || hasTax;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: isBelowCost ? 1.3 : 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: hasInsights
              ? () {
                  setState(() {
                    _isTotalExpanded = !_isTotalExpanded;
                  });
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Summary Row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status icon badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusIconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusIconColor, size: 20),
                    ),
                    const SizedBox(width: 10),

                    // Title and dynamic subtitle / formula
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  hasTax
                                      ? AppStrings.totalAfterTax.tr()
                                      : AppStrings.invoiceLineTotal.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasInsights) ...[
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: _isTotalExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.subTitleColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (discountAmount > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${subtotal.toSmartAmount()} $currency',
                                      style:
                                          TextStyles.customStyle(
                                            fontSize: 11,
                                            color: AppColors.disabledColor,
                                          ).copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text:
                                          '(${AppStrings.savedAmount.tr()} ${discountAmount.toSmartAmount()})',
                                      style: TextStyles.customStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.orange100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (price > 0 && qty > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '${qty.toSmartAmount()} ${unit.isNotEmpty ? "$unit " : ""}× ${price.toSmartAmount()} $currency',
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  color: AppColors.blackLight,
                                ),
                              ),
                            )
                          else
                            Text(
                              '0.00 $currency',
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                color: AppColors.disabledColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Net Line Total
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  lineTotal.toSmartAmount(),
                                  style: TextStyles.customStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isBelowCost
                                        ? AppColors.warning
                                        : AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  currency,
                                  style: TextStyles.customStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isBelowCost
                                        ? AppColors.warning
                                        : AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasTax) ...[
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                '${AppStrings.totalBeforeTax.tr()}\n ${itemBeforeTax.toSmartAmount()}',
                                style: TextStyles.customStyle(
                                  fontSize: 10,
                                  color: AppColors.subTitleColor,
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Animated Expandable Details / Smart Badges ──
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: _isTotalExpanded && hasInsights
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Divider(
                                  height: 1,
                                  thickness: 0.8,
                                  color: AppColors.dividerColor,
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Formula breakdown pill
                                  if (price > 0 && qty > 0)
                                    _buildSmartBadge(
                                      context: context,
                                      icon: Icons.calculate_outlined,
                                      label:
                                          '${qty.toSmartAmount()} × ${price.toSmartAmount()}${discountAmount > 0 ? " - ${discountAmount.toSmartAmount()}" : ""}',
                                      color: AppColors.blackLight,
                                      bgColor: AppColors.surface,
                                      borderColor: AppColors.dividerColor,
                                    ),

                                  // Discount pill
                                  if (discountAmount > 0) ...[
                                    _buildSmartBadge(
                                      context: context,
                                      icon: Icons.local_offer_outlined,
                                      label:
                                          '${AppStrings.invoiceItemDiscount.tr()}: -${discountAmount.toSmartAmount()} $currency (${discountPercent.toSmartAmount(decimalDigits: 1)}%)',
                                      color: AppColors.orange100,
                                      bgColor: AppColors.orange100.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderColor: AppColors.orange100
                                          .withValues(alpha: 0.3),
                                    ),
                                    if (qty > 1)
                                      _buildSmartBadge(
                                        context: context,
                                        icon: Icons.sell_outlined,
                                        label:
                                            '${AppStrings.unitPriceAfterDiscount.tr()}: ${effectiveUnitPrice.toSmartAmount(decimalDigits: 2)} $currency',
                                        color: AppColors.blackLight,
                                        bgColor: AppColors.surface,
                                        borderColor: AppColors.dividerColor,
                                      ),
                                  ],

                                  // Cost & Profit pills
                                  if (hasPurchasePrice) ...[
                                    if (isBelowCost) ...[
                                      _buildSmartBadge(
                                        context: context,
                                        icon: Icons.warning_amber_rounded,
                                        label:
                                            '${AppStrings.lossAlert.tr()}: -${(totalCost - lineTotal).toSmartAmount()} $currency • ${AppStrings.sellingBelowCostWarning.tr().replaceAll('{cost}', widget.purchasePrice!.toSmartAmount()).replaceAll('{currency}', currency)}',
                                        color: AppColors.warning,
                                        bgColor: AppColors.warning.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderColor: AppColors.warning
                                            .withValues(alpha: 0.5),
                                      ),
                                    ] else if (totalProfit > 0) ...[
                                      _buildSmartBadge(
                                        context: context,
                                        icon: Icons.trending_up_rounded,
                                        label:
                                            '${AppStrings.profitEstimate.tr()} +${totalProfit.toSmartAmount()} $currency (${profitMarginPercent.toSmartAmount(decimalDigits: 0)}% ${AppStrings.profitMargin.tr()})',
                                        color: AppColors.success,
                                        bgColor: AppColors.success.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderColor: AppColors.success
                                            .withValues(alpha: 0.3),
                                      ),
                                    ] else ...[
                                      _buildSmartBadge(
                                        context: context,
                                        icon: Icons.balance_rounded,
                                        label: AppStrings.atCostNoProfit.tr(),
                                        color: AppColors.blackLight,
                                        bgColor: AppColors.surface,
                                        borderColor: AppColors.dividerColor,
                                      ),
                                    ],
                                  ],

                                  // Tax breakdown pill
                                  if (hasTax)
                                    _buildSmartBadge(
                                      context: context,
                                      icon: Icons.account_balance_outlined,
                                      label:
                                          '${AppStrings.vatAmount.tr()} (${widget.taxRate.toSmartAmount()}%): +${itemTax.toSmartAmount()} $currency',
                                      color: AppColors.primaryColor,
                                      bgColor: AppColors.primaryColor
                                          .withValues(alpha: 0.08),
                                      borderColor: AppColors.primaryColor
                                          .withValues(alpha: 0.2),
                                    ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartBadge({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    final maxBadgeWidth = (MediaQuery.of(context).size.width - 64).clamp(
      100.0,
      600.0,
    );
    return Container(
      constraints: BoxConstraints(maxWidth: maxBadgeWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.customStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceItemRowItemField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final bool isNumber;
  final String? suffix;
  final Widget? suffixWidget;
  final Widget? prefixWidget;
  final void Function(String)? onChanged;

  const InvoiceItemRowItemField({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    this.isNumber = false,
    this.suffix,
    this.suffixWidget,
    this.prefixWidget,
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
            suffixIcon: suffixWidget,
            prefixIcon: prefixWidget,
            suffixIconConstraints: suffixWidget != null
                ? const BoxConstraints(maxHeight: 36, minWidth: 44)
                : null,
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

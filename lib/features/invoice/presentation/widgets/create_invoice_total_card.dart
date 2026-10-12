import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

/// A smart, contextual, and expandable summary card for the invoice or quotation grand total.
class CreateInvoiceTotalCard extends StatefulWidget {
  final double rawSubtotal;
  final double totalDiscount;
  final double grandTotal;
  final double taxRate;
  final bool isQuotation;

  const CreateInvoiceTotalCard({
    super.key,
    required this.rawSubtotal,
    required this.totalDiscount,
    required this.grandTotal,
    this.taxRate = 0.0,
    this.isQuotation = false,
  });

  @override
  State<CreateInvoiceTotalCard> createState() => _CreateInvoiceTotalCardState();
}

class _CreateInvoiceTotalCardState extends State<CreateInvoiceTotalCard> {
  bool _isExpanded = false;

  Widget _buildRow({
    required String label,
    required String value,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
    int labelFlex = 1,
    int valueFlex = 1,
  }) {
    return Row(
      children: [
        Expanded(
          flex: labelFlex,
          child: Text(
            label,
            style: labelStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: valueFlex,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(value, style: valueStyle, maxLines: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
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
              style: TextStyles.customStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTax = widget.taxRate > 0;
    final taxAmount = hasTax
        ? widget.grandTotal * (widget.taxRate / 100.0)
        : 0.0;
    final beforeTax = hasTax
        ? (widget.grandTotal - taxAmount)
        : widget.grandTotal;
    final discountPercent = widget.rawSubtotal > 0
        ? ((widget.totalDiscount / widget.rawSubtotal) * 100).clamp(0.0, 100.0)
        : 0.0;
    final currency = AppStrings.currencyEgp.tr();
    final hasDetails = widget.totalDiscount > 0 || hasTax;

    final IconData statusIcon = widget.isQuotation
        ? Icons.request_quote_rounded
        : widget.totalDiscount > 0
        ? Icons.local_offer_outlined
        : hasTax
        ? Icons.receipt_long_rounded
        : Icons.receipt_long_rounded;

    final String title = hasTax
        ? AppStrings.totalAfterTax.tr()
        : (widget.isQuotation
              ? AppStrings.quotationTotal.tr()
              : AppStrings.invoiceGrandTotal.tr());

    final cardGradient = AppColors.isDark
        ? const LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF132238)],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          )
        : LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withValues(alpha: 0.82),
            ],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: AppColors.isDark ? 0.12 : 0.22),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: hasDetails
              ? () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Summary Row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status icon badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),

                    // Title & dynamic subtitle
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
                                  title,
                                  style: TextStyles.customStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasDetails) ...[
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: _isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (widget.totalDiscount > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${widget.rawSubtotal.toSmartAmount()} $currency',
                                      style:
                                          TextStyles.customStyle(
                                            fontSize: 11,
                                            color: Colors.white.withValues(
                                              alpha: 0.65,
                                            ),
                                          ).copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text:
                                          '(${AppStrings.savedAmount.tr()} ${widget.totalDiscount.toSmartAmount()})',
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
                          else if (hasTax)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '${AppStrings.totalBeforeTax.tr()}: ${beforeTax.toSmartAmount()} $currency',
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            )
                          else
                            Text(
                              widget.isQuotation
                                  ? AppStrings.createQuotation.tr()
                                  : AppStrings.createInvoice.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Net Grand Total
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
                                  widget.grandTotal.toSmartAmount(),
                                  style: TextStyles.customStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  currency,
                                  style: TextStyles.customStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withValues(alpha: 0.85),
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
                                '${AppStrings.totalBeforeTax.tr()}\n${beforeTax.toSmartAmount()}',
                                style: TextStyles.customStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Animated Expandable Details ──
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: _isExpanded && hasDetails
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                  color: Colors.white24,
                                  height: 1,
                                ),
                              ),
                              if (widget.totalDiscount > 0) ...[
                                _buildRow(
                                  label: AppStrings.subtotalBeforeDiscount.tr(),
                                  value:
                                      '${widget.rawSubtotal.toSmartAmount()} $currency',
                                  labelStyle: TextStyles.customStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  valueStyle: TextStyles.customStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildRow(
                                  label: AppStrings.overallDiscountAmount.tr(),
                                  value:
                                      '-${widget.totalDiscount.toSmartAmount()} $currency (${discountPercent.toSmartAmount(decimalDigits: 1)}%)',
                                  labelStyle: TextStyles.customStyle(
                                    fontSize: 12,
                                    color: AppColors.orange100.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                  valueStyle: TextStyles.customStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.orange100,
                                  ),
                                ),
                              ],
                              if (hasTax) ...[
                                if (widget.totalDiscount > 0)
                                  const SizedBox(height: 4),
                                _buildRow(
                                  label: AppStrings.totalBeforeTax.tr(),
                                  value:
                                      '${beforeTax.toSmartAmount()} $currency',
                                  labelStyle: TextStyles.customStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  valueStyle: TextStyles.customStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildRow(
                                  label:
                                      '${AppStrings.vatAmount.tr()} (${widget.taxRate.toSmartAmount()}%)',
                                  value:
                                      '+${taxAmount.toSmartAmount()} $currency',
                                  labelStyle: TextStyles.customStyle(
                                    fontSize: 12,
                                    color: AppColors.orange100.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                  valueStyle: TextStyles.customStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.orange100,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (widget.totalDiscount > 0)
                                    _buildBadge(
                                      icon: Icons.local_offer_outlined,
                                      label:
                                          '${AppStrings.savedAmount.tr()}: ${widget.totalDiscount.toSmartAmount()} $currency (${discountPercent.toSmartAmount(decimalDigits: 1)}%)',
                                      color: AppColors.orange100,
                                      bgColor: AppColors.orange100.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderColor: AppColors.orange100
                                          .withValues(alpha: 0.35),
                                    ),
                                  if (hasTax)
                                    _buildBadge(
                                      icon: Icons.account_balance_outlined,
                                      label:
                                          '${AppStrings.vatAmount.tr()} (${widget.taxRate.toSmartAmount()}%): +${taxAmount.toSmartAmount()} $currency',
                                      color: Colors.white,
                                      bgColor: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderColor: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  _buildBadge(
                                    icon: widget.isQuotation
                                        ? Icons.request_quote_outlined
                                        : Icons.receipt_long_outlined,
                                    label: widget.isQuotation
                                        ? "${AppStrings.quotationTotal.tr()}: ${widget.grandTotal.toSmartAmount()} $currency"
                                        : "${AppStrings.invoiceGrandTotal.tr()}: ${widget.grandTotal.toSmartAmount()} $currency",
                                    color: Colors.white.withValues(alpha: 0.9),
                                    bgColor: Colors.white.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderColor: Colors.white.withValues(
                                      alpha: 0.2,
                                    ),
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
}

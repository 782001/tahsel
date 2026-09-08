import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';

class InvoiceItemsCard extends StatefulWidget {
  final List<InvoiceItem> items;
  final double taxRate;
  final bool isQuotation;

  const InvoiceItemsCard({
    super.key,
    required this.items,
    this.taxRate = 0.0,
    this.isQuotation = false,
  });

  @override
  State<InvoiceItemsCard> createState() => _InvoiceItemsCardState();
}

class _InvoiceItemsCardState extends State<InvoiceItemsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool hasMoreItems = widget.items.length > 3;
    final displayedItems = (!_isExpanded && hasMoreItems)
        ? widget.items.take(3).toList()
        : widget.items;
    final hasTax = widget.taxRate > 0 && !widget.isQuotation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedItems.length,
              separatorBuilder: (_, __) =>
                   Divider(height: 1, color: AppColors.dividerColor),
              itemBuilder: (context, i) {
                final item = displayedItems[i];
                final itemTotal = item.total;
                final itemTax = hasTax ? itemTotal * (widget.taxRate / 100.0) : 0.0;
                final itemBeforeTax = hasTax ? (itemTotal - itemTax) : itemTotal;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantity.toSmartAmount()} ${item.unit != null && item.unit!.isNotEmpty ? "${item.unit!} " : ""}× ${item.unitPrice.toSmartAmount()}${item.discountAmount > 0 ? " • ${AppStrings.invoiceItemDiscount.tr()}: ${item.discountAmount.toSmartAmount()}" : ""}',
                              style: TextStyles.customStyle(
                                fontSize: 12,
                                color: AppColors.blackLight,
                              ),
                            ),
                            if (hasTax) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    '${AppStrings.totalBeforeTax.tr()}: ${itemBeforeTax.toSmartAmount()}',
                                    style: TextStyles.customStyle(
                                      fontSize: 11,
                                      color: AppColors.subTitleColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${AppStrings.vatAmount.tr()}: ${itemTax.toSmartAmount()}',
                                    style: TextStyles.customStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasTax)
                            Text(
                              AppStrings.totalAfterTax.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 10,
                                color: AppColors.subTitleColor,
                              ),
                            ),
                          Text(
                            '${itemTotal.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                            style: TextStyles.customStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (hasMoreItems) ...[
             Divider(height: 1, color: AppColors.dividerColor),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded
                          ? AppStrings.showLess.tr()
                          : '${AppStrings.showMore.tr()} (${widget.items.length - 3})',
                      style: TextStyles.customStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryColor,
                      size: 18,
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
}

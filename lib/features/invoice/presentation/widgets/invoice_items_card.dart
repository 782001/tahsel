import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';

class InvoiceItemsCard extends StatefulWidget {
  final List<InvoiceItem> items;
  const InvoiceItemsCard({super.key, required this.items});

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
                          ],
                        ),
                      ),
                      Text(
                        '${item.total.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
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

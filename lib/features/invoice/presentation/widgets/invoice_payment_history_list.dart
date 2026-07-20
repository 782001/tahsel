import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';

class InvoicePaymentHistoryList extends StatefulWidget {
  final List<InvoicePayment> payments;
  const InvoicePaymentHistoryList({super.key, required this.payments});

  @override
  State<InvoicePaymentHistoryList> createState() => _InvoicePaymentHistoryListState();
}

class _InvoicePaymentHistoryListState extends State<InvoicePaymentHistoryList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Center(
          child: Text(
            AppStrings.invoiceNoPayments.tr(),
            style: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.disabledColor,
            ),
          ),
        ),
      );
    }

    final reversedPayments = widget.payments.reversed.toList();
    final bool hasMoreItems = reversedPayments.length > 3;
    final displayedPayments = (!_isExpanded && hasMoreItems)
        ? reversedPayments.take(3).toList()
        : reversedPayments;

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
              itemCount: displayedPayments.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.dividerColor),
              itemBuilder: (context, i) {
                final payment = displayedPayments[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.payments_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${payment.amount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                              style: TextStyles.customStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            if (payment.note?.isNotEmpty == true)
                              Text(
                                payment.note!,
                                style: TextStyles.customStyle(
                                  fontSize: 12,
                                  color: AppColors.blackLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(payment.paidAt),
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: AppColors.disabledColor,
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
                          : '${AppStrings.showMore.tr()} (${reversedPayments.length - 3})',
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

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}


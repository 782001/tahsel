import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_summary_column.dart';

class PaymentSummaryCard extends StatelessWidget {
  final InvoiceEntity invoice;
  const PaymentSummaryCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final hasTax = invoice.effectiveTaxRate > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: Column(
        children: [
          if (invoice.totalDiscountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.subtotalBeforeDiscount.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: AppColors.subTitleColor,
                  ),
                ),
                Text(
                  '${invoice.rawSubtotalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.overallDiscountAmount.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: AppColors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '-${invoice.totalDiscountAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
            Divider(color: AppColors.dividerColor, height: 20),
          ],
          if (hasTax) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.totalBeforeTax.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: AppColors.subTitleColor,
                  ),
                ),
                Text(
                  '${invoice.totalBeforeTaxAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.vatAmount.tr()} (${invoice.effectiveTaxRate.toSmartAmount()}%)',
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${invoice.calculatedTaxAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            Divider(color: AppColors.dividerColor, height: 20),
          ],
          if (invoice.isQuotation)
            Center(
              child: InvoiceSummaryColumn(
                label: hasTax
                    ? AppStrings.totalAfterTax.tr()
                    : AppStrings.quotationTotal.tr(),
                amount: invoice.totalAmount,
                color: AppColors.primaryColor,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InvoiceSummaryColumn(
                  label: hasTax
                      ? AppStrings.totalAfterTax.tr()
                      : AppStrings.totalDueLabel.tr(),
                  amount: invoice.totalAmount,
                  color: AppColors.black,
                ),
                Container(width: 1, height: 40, color: AppColors.dividerColor),
                InvoiceSummaryColumn(
                  label: AppStrings.invoiceTotalPaid.tr(),
                  amount: invoice.totalPaid,
                  color: AppColors.success,
                ),
                Container(width: 1, height: 40, color: AppColors.dividerColor),
                InvoiceSummaryColumn(
                  label: AppStrings.invoiceRemainingAmount.tr(),
                  amount: invoice.remainingAmount,
                  color: invoice.remainingAmount > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

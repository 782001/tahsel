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

  Widget _buildRow({
    required String label,
    required String value,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
    int labelFlex = 2,
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
              child: Text(value, style: valueStyle, maxLines: 1),
            ),
          ),
        ),
      ],
    );
  }

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
            _buildRow(
              label: AppStrings.subtotalBeforeDiscount.tr(),
              value:
                  '${invoice.rawSubtotalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
              labelStyle: TextStyles.customStyle(
                fontSize: 13,
                color: AppColors.subTitleColor,
              ),
              valueStyle: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 6),
            _buildRow(
              label: AppStrings.overallDiscountAmount.tr(),
              value:
                  '-${invoice.totalDiscountAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
              labelStyle: TextStyles.customStyle(
                fontSize: 13,
                color: AppColors.orange,
                fontWeight: FontWeight.w600,
              ),
              valueStyle: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
            Divider(color: AppColors.dividerColor, height: 20),
          ],
          if (hasTax) ...[
            _buildRow(
              label: AppStrings.totalBeforeTax.tr(),
              value:
                  '${invoice.totalBeforeTaxAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
              labelStyle: TextStyles.customStyle(
                fontSize: 13,
                color: AppColors.subTitleColor,
              ),
              valueStyle: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 6),
            _buildRow(
              label:
                  '${AppStrings.vatAmount.tr()} (${invoice.effectiveTaxRate.toSmartAmount()}%)',
              value:
                  '${invoice.calculatedTaxAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
              labelStyle: TextStyles.customStyle(
                fontSize: 13,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              valueStyle: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
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
              children: [
                Expanded(
                  child: InvoiceSummaryColumn(
                    label: AppStrings.totalDueLabel.tr(),
                    amount: invoice.totalAmount,
                    color: AppColors.black,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.dividerColor),
                Expanded(
                  child: InvoiceSummaryColumn(
                    label: AppStrings.invoiceTotalPaid.tr(),
                    amount: invoice.totalPaid,
                    color: AppColors.success,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.dividerColor),
                Expanded(
                  child: InvoiceSummaryColumn(
                    label: AppStrings.invoiceRemainingAmount.tr(),
                    amount: invoice.remainingAmount,
                    color: invoice.remainingAmount > 0
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

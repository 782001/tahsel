import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_summary_column.dart';

class PaymentSummaryCard extends StatelessWidget {
  final InvoiceEntity invoice;
  const PaymentSummaryCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InvoiceSummaryColumn(
            label: AppStrings.totalDueLabel.tr(),
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
    );
  }
}

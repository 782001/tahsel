import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/widgets/amount_column.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final bool isPendingSync;
  final VoidCallback onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
    this.isPendingSync = false,
  });

  Color _statusColor() {
    switch (invoice.status) {
      case InvoiceStatus.paid:
        return AppColors.success;
      case InvoiceStatus.partial:
        return AppColors.warning;
      case InvoiceStatus.voided:
        return AppColors.error;
      case InvoiceStatus.pending:
        return AppColors.info;
      case InvoiceStatus.quotation:
        return AppColors.primaryColor;
    }
  }

  String _statusLabel() {
    switch (invoice.status) {
      case InvoiceStatus.paid:
        return AppStrings.invoiceStatusPaid.tr();
      case InvoiceStatus.partial:
        return AppStrings.invoiceStatusPartial.tr();
      case InvoiceStatus.voided:
        return AppStrings.invoiceStatusVoided.tr();
      case InvoiceStatus.pending:
        return AppStrings.invoiceStatusPending.tr();
      case InvoiceStatus.quotation:
        return AppStrings.invoiceStatusQuotation.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: const [AppColors.shadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName ??
                              AppStrings.walkingCustomer.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        ...[
                          const SizedBox(height: 2),
                          Text(
                            '# ${invoice.id}',
                            style: TextStyles.customStyle(
                              fontSize: 12,
                              color: AppColors.blackLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Amount Row ──────────────────────────────────────────
              if (invoice.isQuotation)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AmountColumn(
                      label: AppStrings.quotationTotal.tr(),
                      value: invoice.totalAmount,
                      color: AppColors.primaryColor,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${invoice.items.length} ${AppStrings.invoiceItem.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AmountColumn(
                      label: AppStrings.totalDueLabel.tr(),
                      value: invoice.totalAmount,
                      color: AppColors.black,
                    ),
                    AmountColumn(
                      label: AppStrings.paidAmount.tr(),
                      value: invoice.totalPaid,
                      color: AppColors.success,
                    ),
                    AmountColumn(
                      label: AppStrings.remainingDebt.tr(),
                      value: invoice.remainingAmount,
                      color: invoice.remainingAmount > 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // ── Date + Arrow ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDate(invoice.createdAt),
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: AppColors.disabledColor,
                        ),
                      ),
                      if (isPendingSync) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sync_rounded,
                                size: 12,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.syncing.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 10,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.disabledColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

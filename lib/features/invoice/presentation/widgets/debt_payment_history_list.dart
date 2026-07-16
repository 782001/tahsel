import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';

/// Shows payment history sourced directly from the linked Debt's payments
/// sub-collection — ensures the invoice detail always reflects the live data.
class DebtPaymentHistoryList extends StatelessWidget {
  final List<PaymentEntity> transactions;
  const DebtPaymentHistoryList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Filter to actual payment entries (exclude internal "debtAdded" marker)
    final payments =
        transactions
            .where(
              (t) =>
                  t.type != PaymentType.debtAdded &&
                  t.type != PaymentType.reversal,
            )
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );

    if (payments.isEmpty) {
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payments.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.dividerColor),
        itemBuilder: (context, i) {
          final p = payments[i];
          final isSettlement = p.type == PaymentType.settlement;
          final color = p.type == PaymentType.adjustment
              ? AppColors.warning
              : AppColors.success;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSettlement
                        ? Icons.check_circle_rounded
                        : Icons.payments_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.amountPaid.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (p.activityName?.isNotEmpty == true)
                        Text(
                          p.activityName!,
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            color: AppColors.blackLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  p.createdAt != null ? _fmt(p.createdAt!) : '',
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
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

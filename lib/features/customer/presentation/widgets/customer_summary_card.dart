import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_summary_row.dart';

class CustomerSummaryCard extends StatelessWidget {
  final double totalSpent;
  final double totalPaid;
  final double remaining;
  final double openingBalance;

  const CustomerSummaryCard({
    super.key,
    required this.totalSpent,
    required this.totalPaid,
    required this.remaining,
    this.openingBalance = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSettled = remaining == 0;
    final bool isDebit = remaining > 0;

    final statusColor = isDebit
        ? Colors.amber.shade200
        : isSettled
            ? Colors.greenAccent.shade100
            : Colors.lightBlueAccent.shade100;

    final statusIcon = isDebit
        ? Icons.access_time_rounded
        : isSettled
            ? Icons.check_circle_rounded
            : Icons.account_balance_wallet_rounded;

    final statusLabel = isDebit
        ? AppStrings.customerDebitStatus.tr()
        : isSettled
            ? AppStrings.accountSettled.tr()
            : AppStrings.customerCreditStatus.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withAlpha(210),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withAlpha(70),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Badge
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    statusLabel,
                    style: TextStyles.customStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Opening Balance (if active period)
          if (openingBalance != 0.0) ...[
            CustomerSummaryRow(
              label: AppStrings.openingBalance.tr(),
              value: openingBalance,
              isWhite: true,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white24, height: 1),
            ),
          ],

          CustomerSummaryRow(
            label: AppStrings.totalPurchases.tr(),
            value: totalSpent,
            isWhite: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white24, height: 1),
          ),
          CustomerSummaryRow(
            label: AppStrings.totalPaid.tr(),
            value: totalPaid,
            isWhite: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white24, height: 1),
          ),
          CustomerSummaryRow(
            label: AppStrings.remainingAmount.tr(),
            value: remaining.abs(),
            isWhite: true,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

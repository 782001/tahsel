import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class CustomerDebtCard extends StatelessWidget {
  final String customerName;
  final String lastTransactionDate;
  final double amount;
  final String status;
  final Color statusColor;
  final VoidCallback onPartialPayment;
  final VoidCallback onFullPayment;
  final VoidCallback? onTap;

  const CustomerDebtCard({
    super.key,
    required this.customerName,
    required this.lastTransactionDate,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.onPartialPayment,
    required this.onFullPayment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Slidable(
        key: ValueKey(customerName),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onPartialPayment(),
              backgroundColor: AppColors.slidablePartialPayment,
              foregroundColor: AppColors.whiteColor,
              icon: Icons.payments,
              label: AppStrings.partialPayLabel.tr(),
            ),
            SlidableAction(
              onPressed: (_) => onFullPayment(),
              backgroundColor: AppColors.slidableFullPayment,
              foregroundColor: AppColors.whiteColor,
              icon: Icons.check_circle,
              label: AppStrings.fullPaymentLabel.tr(),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.debtCardSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Status accent bar on the right
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Customer info column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: TextStyles.customStyle(
                                  color: AppColors.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppStrings.lastTransactionPrefix.tr()} $lastTransactionDate',
                                style: TextStyles.customStyle(
                                  color: AppColors.disabledColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Amount + status badge column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${amount.toStringAsFixed(2)} ${AppStrings.currencyEgp.tr()}',
                              style: TextStyles.customStyle(
                                color: statusColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyles.customStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
  final String? ledgerNumber;
  final String? description;
  final VoidCallback onPartialPayment;
  final VoidCallback onFullPayment;
  final VoidCallback onDelete;
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
    required this.onDelete,
    this.ledgerNumber,
    this.description,
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
            if (amount != 0)
              SlidableAction(
                onPressed: (_) => onPartialPayment(),
                backgroundColor: AppColors.slidablePartialPayment,
                foregroundColor: AppColors.whiteColor,
                icon: Icons.payments,
                label: AppStrings.partialPayLabel.tr(),
              ),

            if (amount != 0)
              SlidableAction(
                onPressed: (_) => onFullPayment(),
                backgroundColor: AppColors.slidableFullPayment,
                foregroundColor: AppColors.whiteColor,
                icon: Icons.check_circle,
                label: AppStrings.fullPaymentLabel.tr(),
              ),
            if (amount == 0)
              SlidableAction(
                onPressed: (_) => onDelete(),
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.whiteColor,
                icon: Icons.delete_forever_rounded,
                label: AppStrings.delete.tr(),
              ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.debtCardSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Status accent bar on the right
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: const BorderRadiusDirectional.only(
                          topStart: Radius.circular(12),
                          bottomStart: Radius.circular(12),
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
                              if (description != null &&
                                  description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  description!,
                                  style: TextStyles.customStyle(
                                    color: AppColors.textColor.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Amount + status badge column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${amount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
                              style: TextStyles.customStyle(
                                color: statusColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (ledgerNumber != null &&
                                ledgerNumber!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ledgerNumber ?? "",
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

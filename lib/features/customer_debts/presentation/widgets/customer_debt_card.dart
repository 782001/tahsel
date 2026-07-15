import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

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
      padding: EdgeInsets.only(
        bottom: ResponsiveLayout.isDesktop(context) ? 0 : 12.0,
      ),
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
            // if (amount == 0)
            //   SlidableAction(
            //     onPressed: (_) => onDelete(),
            //     backgroundColor: AppColors.error,
            //     foregroundColor: AppColors.whiteColor,
            //     icon: Icons.delete_forever_rounded,
            //     label: AppStrings.delete.tr(),
            //   ),
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
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Customer info column
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                customerName.isNotEmpty
                                    ? customerName
                                    : (description != null &&
                                          description!.isNotEmpty)
                                    ? description!
                                    : "Unknown Customer",
                                style: TextStyles.customStyle(
                                  color: AppColors.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppStrings.lastTransactionPrefix.tr()} $lastTransactionDate',
                                style: TextStyles.customStyle(
                                  color: AppColors.disabledColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (description != null &&
                                  description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  description!,
                                  style: TextStyles.customStyle(
                                    color: AppColors.textColor.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Amount + status badge column
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                child: Text(
                                  amount > 0.0
                                      ? '${amount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}'
                                      : '0.0 ${AppStrings.currencyEgp.tr()}',
                                  style: TextStyles.customStyle(
                                    color: statusColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),
                              if (ledgerNumber != null &&
                                  ledgerNumber!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ledgerNumber ?? "",
                                    style: TextStyles.customStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
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

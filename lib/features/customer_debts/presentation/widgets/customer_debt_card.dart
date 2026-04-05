import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/utils/app_colors.dart';

class CustomerDebtCard extends StatelessWidget {
  final String customerName;
  final String lastTransactionDate;
  final double amount;
  final String status;
  final Color statusColor;
  final VoidCallback onPartialPayment;
  final VoidCallback onFullPayment;

  const CustomerDebtCard({
    super.key,
    required this.customerName,
    required this.lastTransactionDate,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.onPartialPayment,
    required this.onFullPayment,
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
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              icon: Icons.payments,
              label: 'دفع جزء',
            ),
            SlidableAction(
              onPressed: (_) => onFullPayment(),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              icon: Icons.check_circle,
              label: 'تم الدفع',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.scafoldBackGround == const Color(0xFFF8F8F8)
                ? Colors.white
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Stack(
            children: [
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
                    Column(
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
                          'آخر عملية: $lastTransactionDate',
                          style: TextStyles.customStyle(
                            color: AppColors.disabledColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${amount.toStringAsFixed(2)} ج.م',
                          style: TextStyles.customStyle(
                            color: statusColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status,
                          style: TextStyles.customStyle(
                            color: statusColor.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
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
    );
  }
}

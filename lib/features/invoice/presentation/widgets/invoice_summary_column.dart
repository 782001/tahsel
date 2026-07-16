import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class InvoiceSummaryColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const InvoiceSummaryColumn({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 11,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount.toSmartAmount(),
          style: TextStyles.customStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

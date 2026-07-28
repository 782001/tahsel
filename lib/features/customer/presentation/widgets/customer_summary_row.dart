import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class CustomerSummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isWhite;
  final bool isBold;

  const CustomerSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isWhite = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            color: isWhite ? Colors.white70 : AppColors.blackLight,
            fontSize: 14,
          ),
        ),
        Text(
          '${value.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
          style: TextStyles.customStyle(
            color: isWhite ? Colors.white : AppColors.black,
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

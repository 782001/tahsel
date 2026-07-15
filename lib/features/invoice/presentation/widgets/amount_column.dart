import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class AmountColumn extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const AmountColumn({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
          '${value.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

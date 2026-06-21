import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class BuildReportInsightDetailRow extends StatelessWidget {
  const BuildReportInsightDetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.textColor,
  });

  final String label;
  final double value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.blackLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          "${value.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
          style: TextStyles.customStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

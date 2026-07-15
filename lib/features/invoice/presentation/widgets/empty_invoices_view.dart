import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class EmptyInvoicesView extends StatelessWidget {
  const EmptyInvoicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: AppColors.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.invoicesEmpty.tr(),
            style: TextStyles.customStyle(
              fontSize: 16,
              color: AppColors.blackLight,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.invoicesEmptyDesc.tr(),
            style: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

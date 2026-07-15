import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class OfflineEmptyInvoicesView extends StatelessWidget {
  const OfflineEmptyInvoicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 72,
            color: AppColors.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noInternetConnection.tr(),
            style: TextStyles.customStyle(
              fontSize: 18,
              color: AppColors.blackLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppStrings.offlineNoRecentInvoices.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                color: AppColors.disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

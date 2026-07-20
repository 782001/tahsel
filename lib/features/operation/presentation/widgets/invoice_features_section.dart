import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';

class InvoiceFeaturesSection extends StatelessWidget {
  const InvoiceFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.invoiceFeaturesTitle.tr(),
          style: TextStyles.customStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 24),
        _buildFeatureItem(
          icon: Icons.auto_awesome_rounded,
          title: AppStrings.invoiceFeaturesItem1Title.tr(),
          subtitle: AppStrings.invoiceFeaturesItem1Subtitle.tr(),
          color: Colors.blueAccent,
        ),
        _buildFeatureItem(
          icon: Icons.send_rounded,
          title: AppStrings.invoiceFeaturesItem2Title.tr(),
          subtitle: AppStrings.invoiceFeaturesItem2Subtitle.tr(),
          color: Colors.green,
        ),
        _buildFeatureItem(
          icon: Icons.account_balance_wallet_rounded,
          title: AppStrings.invoiceFeaturesItem3Title.tr(),
          subtitle: AppStrings.invoiceFeaturesItem3Subtitle.tr(),
          color: Colors.orange,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<MainLayoutCubit>().changeBottomNav(3);
            },
            icon: Icon(Icons.list_alt_rounded, color: AppColors.primaryColor),
            label: Text(
              AppStrings.invoiceFeaturesManageBtn.tr(),
              style: TextStyles.customStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: AppColors.primaryColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.customStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: AppColors.blackLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

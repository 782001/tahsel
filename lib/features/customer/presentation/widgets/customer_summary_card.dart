import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class CustomerSummaryCard extends StatelessWidget {
  final double totalSpent;
  final double totalPaid;
  final double remaining;

  const CustomerSummaryCard({
    super.key,
    required this.totalSpent,
    required this.totalPaid,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: AppColors.shadowColor.withAlpha(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.primaryColor,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    AppStrings.totalSpent.tr(),
                    totalSpent,
                    Colors.white.withAlpha(200),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    AppStrings.paid.tr(),
                    totalPaid,
                    Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildSummaryItem(
              context,
              AppStrings.remainingBalance.tr(),
              remaining,
              Colors.white,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    Color color, {
    bool isLarge = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyles.customStyle(
            color: color.withAlpha(200),
            fontSize: (isLarge ? 16 : 14).sp,
            fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyles.customStyle(
            color: color,
            fontSize: (isLarge ? 28 : 20).sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

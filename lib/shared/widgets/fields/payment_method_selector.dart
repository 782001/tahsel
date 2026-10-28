import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

/// A modern, responsive segmented selector for choosing sales payment method:
/// - Cash: 'cash'
/// - Card / POS: 'card'
/// - Debt / Deferred: 'debt'
class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;
  final bool showDebtOption;
  final bool showCardOption;
  final String? title;
  final EdgeInsetsGeometry? margin;
  final bool isCompact;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.showDebtOption = true,
    this.showCardOption = true,
    this.title,
    this.margin,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 17,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                title ?? AppStrings.paymentMethod.tr(),
                style: TextStyles.customStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Cash option
              Expanded(
                child: _buildItem(
                  id: 'cash',
                  label: AppStrings.paymentCashSales.tr(),
                  icon: Icons.payments_rounded,
                  accentColor: const Color(0xFF2E7D32), // Emerald Green
                ),
              ),
              if (showCardOption) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildItem(
                    id: 'card',
                    label: AppStrings.paymentCardSales.tr(),
                    icon: Icons.credit_card_rounded,
                    accentColor: AppColors.primaryColor, // Royal Blue
                  ),
                ),
              ],
              if (showDebtOption) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildItem(
                    id: 'debt',
                    label: AppStrings.paymentDebtSales.tr(),
                    icon: Icons.receipt_long_rounded,
                    accentColor: const Color(0xFFE65100), // Deep Amber
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String id,
    required String label,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = selectedMethod == id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onMethodChanged(id);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 8 : 10,
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : (AppColors.isDark
                      ? AppColors.surfaceContainerHigh
                      : const Color(0xFFF6F8FA)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : AppColors.dividerColor.withValues(alpha: 0.6),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: isCompact ? 18 : 22,
                      color: isSelected ? accentColor : AppColors.sandText,
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyles.customStyle(
                          fontSize: isCompact ? 11 : 12.5,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected
                              ? accentColor
                              : AppColors.blackLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                PositionedDirectional(
                  top: -2,
                  end: 0,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

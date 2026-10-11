import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class CreateInvoiceTotalCard extends StatelessWidget {
  final double rawSubtotal;
  final double totalDiscount;
  final double grandTotal;
  final double taxRate;
  final bool isQuotation;

  const CreateInvoiceTotalCard({
    super.key,
    required this.rawSubtotal,
    required this.totalDiscount,
    required this.grandTotal,
    this.taxRate = 0.0,
    this.isQuotation = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasTax = taxRate > 0;
    final taxAmount = hasTax ? grandTotal * (taxRate / 100.0) : 0.0;
    final beforeTax = hasTax ? (grandTotal - taxAmount) : grandTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.75),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (totalDiscount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.subtotalBeforeDiscount.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '${rawSubtotal.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.overallDiscountAmount.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: Colors.yellowAccent.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  '-${totalDiscount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
          ],
          if (hasTax) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.totalBeforeTax.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '${beforeTax.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.vatAmount.tr()} (${taxRate.toSmartAmount()}%)',
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: Colors.yellowAccent.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  '${taxAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasTax
                    ? AppStrings.totalAfterTax.tr()
                    : (isQuotation
                          ? AppStrings.quotationTotal.tr()
                          : AppStrings.invoiceGrandTotal.tr()),
                style: TextStyles.customStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${grandTotal.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                style: TextStyles.customStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

class QuickAddShopForm extends StatelessWidget {
  final TextEditingController customerController;
  final TextEditingController productController;
  final TextEditingController paidController;
  final TextEditingController debtController;

  const QuickAddShopForm({
    super.key,
    required this.customerController,
    required this.productController,
    required this.paidController,
    required this.debtController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.customerName.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          QuickAddTextField(
            hint: AppStrings.customerNameHint.tr(),
            controller: customerController,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.productName.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          QuickAddTextField(
            hint: AppStrings.productNameHint.tr(),
            controller: productController,
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.paidAmount.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    QuickAddTextField(
                      hint: '0.00',
                      controller: paidController,
                      prefixText: AppStrings.currencyEgp.tr(),
                      isNumber: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.remainingDebt.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    QuickAddTextField(
                      hint: '0.00',
                      controller: debtController,
                      prefixText: AppStrings.currencyEgp.tr(),
                      isNumber: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

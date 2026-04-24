import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_autocomplete_field.dart';
import 'package:tahsel/features/product/presentation/widgets/product_autocomplete_field.dart';

class QuickAddShopForm extends StatelessWidget {
  final TextEditingController customerController;
  final TextEditingController productController;
  final TextEditingController paidController;
  final TextEditingController debtController;
  final TextEditingController ledgerController;
  final bool isShop;
  final String? customerError;
  final FocusNode customerFocus;
  final FocusNode ledgerFocus;
  final FocusNode productFocus;
  final FocusNode paidFocus;
  final FocusNode debtFocus;
  final TextInputAction customerInputAction;
  final TextInputAction ledgerInputAction;
  final TextInputAction productInputAction;
  final TextInputAction paidInputAction;
  final TextInputAction debtInputAction;
  final ValueChanged<String>? onDebtSubmitted;
  final VoidCallback? onContactPickerPressed;

  const QuickAddShopForm({
    super.key,
    required this.customerController,
    required this.productController,
    required this.paidController,
    required this.debtController,
    required this.ledgerController,
    required this.isShop,
    this.customerError,
    required this.customerFocus,
    required this.ledgerFocus,
    required this.productFocus,
    required this.paidFocus,
    required this.debtFocus,
    this.customerInputAction = TextInputAction.next,
    this.ledgerInputAction = TextInputAction.next,
    this.productInputAction = TextInputAction.next,
    this.paidInputAction = TextInputAction.next,
    this.debtInputAction = TextInputAction.done,
    this.onDebtSubmitted,
    this.onContactPickerPressed,
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
          CustomerAutocompleteField(
            hint: AppStrings.customerNameHint.tr(),
            controller: customerController,
            errorText: customerError,
            icon: Icons.person_outline,
            suffixIcon: Icons.contact_phone_rounded,
            onSuffixIconPressed: onContactPickerPressed,
            focusNode: customerFocus,
            textInputAction: customerInputAction,
            onSubmitted: (_) => isShop
                ? ledgerFocus.requestFocus()
                : productFocus.requestFocus(),
          ),
          if (isShop) ...[
            const SizedBox(height: 20),
            Text(
              AppStrings.ledgerNumber.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            QuickAddTextField(
              hint: AppStrings.ledgerNumber.tr(),
              controller: ledgerController,
              icon: Icons.menu_book_outlined,
              isNumber: true,
              focusNode: ledgerFocus,
              textInputAction: ledgerInputAction,
              onSubmitted: (_) => productFocus.requestFocus(),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            AppStrings.productName.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ProductAutocompleteField(
            hint: AppStrings.productNameHint.tr(),
            controller: productController,
            icon: Icons.shopping_bag_outlined,
            focusNode: productFocus,
            textInputAction: productInputAction,
            onSubmitted: (_) => paidFocus.requestFocus(),
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
                      focusNode: paidFocus,
                      textInputAction: paidInputAction,
                      onSubmitted: (_) => debtFocus.requestFocus(),
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
                      focusNode: debtFocus,
                      textInputAction: debtInputAction,
                      onSubmitted: onDebtSubmitted,
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

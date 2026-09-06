import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_autocomplete_field.dart';
import 'package:tahsel/features/invoice/presentation/widgets/multi_inventory_picker_bottom_sheet.dart';
import 'package:tahsel/features/product/presentation/widgets/product_autocomplete_field.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';
import 'package:tahsel/shared/widgets/quick_due_date_selector.dart';

class QuickAddShopForm extends StatefulWidget {
  final TextEditingController totalAmountController;
  final TextEditingController customerController;
  final TextEditingController productController;
  final TextEditingController paidController;
  final TextEditingController debtController;
  final TextEditingController ledgerController;
  final bool isShop;
  final String? customerError;
  final FocusNode totalAmountFocus;
  final FocusNode customerFocus;
  final FocusNode ledgerFocus;
  final FocusNode productFocus;
  final FocusNode paidFocus;
  final FocusNode debtFocus;
  final TextInputAction totalAmountInputAction;
  final TextInputAction customerInputAction;
  final TextInputAction ledgerInputAction;
  final TextInputAction productInputAction;
  final TextInputAction paidInputAction;
  final TextInputAction debtInputAction;
  final ValueChanged<String>? onDebtSubmitted;
  final VoidCallback? onContactPickerPressed;
  final DateTime? dueDate;
  final ValueChanged<DateTime?>? onDueDateChanged;

  const QuickAddShopForm({
    super.key,
    required this.totalAmountController,
    required this.customerController,
    required this.productController,
    required this.paidController,
    required this.debtController,
    required this.ledgerController,
    required this.isShop,
    this.customerError,
    required this.totalAmountFocus,
    required this.customerFocus,
    required this.ledgerFocus,
    required this.productFocus,
    required this.paidFocus,
    required this.debtFocus,
    this.totalAmountInputAction = TextInputAction.next,
    this.customerInputAction = TextInputAction.next,
    this.ledgerInputAction = TextInputAction.next,
    this.productInputAction = TextInputAction.next,
    this.paidInputAction = TextInputAction.next,
    this.debtInputAction = TextInputAction.done,
    this.onDebtSubmitted,
    this.onContactPickerPressed,
    this.dueDate,
    this.onDueDateChanged,
  });

  @override
  State<QuickAddShopForm> createState() => _QuickAddShopFormState();
}

class _QuickAddShopFormState extends State<QuickAddShopForm> {
  List<SelectedInventoryItem> _selectedInventoryItems = [];

  void _openInventoryPicker(BuildContext context) {
    if (widget.productController.text.trim().isEmpty) {
      _selectedInventoryItems.clear();
    }

    final Map<String, double> initialQuantities = {};
    for (final item in _selectedInventoryItems) {
      initialQuantities[item.product.id] = item.quantity;
      initialQuantities[item.product.name] = item.quantity;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiInventoryPickerBottomSheet(
        confirmButtonText: AppStrings.confirmSelection.tr(),
        initialSelectedItems:
            _selectedInventoryItems.isNotEmpty ? _selectedInventoryItems : null,
        initialSelectedQuantities:
            initialQuantities.isNotEmpty ? initialQuantities : null,
        onItemsConfirmed: (selectedItems) {
          setState(() {
            _selectedInventoryItems = List.from(selectedItems);
          });

          if (selectedItems.isEmpty) {
            widget.productController.text = '';
            widget.totalAmountController.text = '';
            widget.debtController.text = '';
            return;
          }

          final productNames = selectedItems
              .map((item) {
                final qtyStr = item.quantity.toSmartAmount();
                final priceStr = item.product.sellingPrice.toSmartAmount();
                return item.quantity > 1
                    ? '${item.product.name} ($qtyStr × $priceStr)'
                    : item.product.name;
              })
              .join(' + ');

          widget.productController.text = productNames;

          double totalPrice = 0.0;
          for (final item in selectedItems) {
            totalPrice += item.totalPrice;
          }

          final formattedTotal = totalPrice.toSmartAmount();
          widget.totalAmountController.text = formattedTotal;

          final paid = double.tryParse(widget.paidController.text) ?? 0.0;
          final debt = (totalPrice - paid).clamp(0.0, double.infinity);
          widget.debtController.text = debt.toSmartAmount();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerController = widget.customerController;
    final customerError = widget.customerError;
    final onContactPickerPressed = widget.onContactPickerPressed;
    final customerFocus = widget.customerFocus;
    final customerInputAction = widget.customerInputAction;
    final isShop = widget.isShop;
    final ledgerFocus = widget.ledgerFocus;
    final totalAmountFocus = widget.totalAmountFocus;
    final ledgerController = widget.ledgerController;
    final ledgerInputAction = widget.ledgerInputAction;
    final productFocus = widget.productFocus;
    final productController = widget.productController;
    final totalAmountController = widget.totalAmountController;
    final totalAmountInputAction = widget.totalAmountInputAction;
    final paidController = widget.paidController;
    final paidFocus = widget.paidFocus;
    final paidInputAction = widget.paidInputAction;
    final debtFocus = widget.debtFocus;
    final debtInputAction = widget.debtInputAction;
    final debtController = widget.debtController;
    final onDebtSubmitted = widget.onDebtSubmitted;
    final dueDate = widget.dueDate;
    final onDueDateChanged = widget.onDueDateChanged;
    final productInputAction = widget.productInputAction;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            style: TextStyles.customStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
                : totalAmountFocus.requestFocus(),
          ),
          if (isShop) ...[
            const SizedBox(height: 20),
            Text(
              AppStrings.ledgerNumber.tr(),
              style: TextStyles.customStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.productName.tr(),
                style: TextStyles.customStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (AppStrings.isVip && isShop)
                InkWell(
                  onTap: () => _openInventoryPicker(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.selectFromInventory.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ProductAutocompleteField(
            hint: isShop
                ? AppStrings.productNameHint.tr()
                : "${AppStrings.productName.tr()} (${AppStrings.optional.tr()})",
            controller: productController,
            icon: Icons.shopping_bag_outlined,
            focusNode: productFocus,
            textInputAction: productInputAction,
            onSubmitted: (_) => isShop
                ? totalAmountFocus.requestFocus()
                : paidFocus.requestFocus(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (isShop)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.totalDueLabel.tr(),
                        style: TextStyles.customStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      QuickAddTextField(
                        hint: AppStrings.totalAmountHint.tr(),
                        hintFontSize: 12,
                        controller: totalAmountController,
                        // icon: Icons.payments_outlined,
                        isNumber: true,
                        focusNode: totalAmountFocus,
                        textInputAction: totalAmountInputAction,
                        onSubmitted: (_) => paidFocus.requestFocus(),
                      ),
                    ],
                  ),
                ),
              if (isShop) const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.paidAmount.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    QuickAddTextField(
                      hint: '0.00',
                      controller: paidController,
                      // prefixText: AppStrings.currencyEgp.tr(),
                      isNumber: true,
                      focusNode: paidFocus,
                      textInputAction: paidInputAction,
                      onSubmitted: (_) => isShop
                          ? debtFocus.requestFocus()
                          : debtFocus.requestFocus(),
                    ),
                  ],
                ),
              ),
              if (!isShop) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.remainingDebt.tr(),
                        style: TextStyles.customStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      QuickAddTextField(
                        hint: '0.00',
                        controller: debtController,
                        isNumber: true,
                        focusNode: debtFocus,
                        textInputAction: debtInputAction,
                        onSubmitted: onDebtSubmitted,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: debtController,
            builder: (context, value, child) {
              final debt = double.tryParse(value.text) ?? 0.0;
              if (debt <= 0) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  if (isShop)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${AppStrings.remainingDebt.tr()}: ${value.text} ${AppStrings.currencyEgp.tr()}",
                              style: TextStyles.customStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  QuickDueDateSelector(
                    selectedDate: dueDate,
                    onDateChanged: (date) => onDueDateChanged?.call(date),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

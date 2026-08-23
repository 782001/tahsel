import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/shared/widgets/buttons/custom_button.dart';

import '../../domain/entities/vault_transaction_entity.dart';

class EditManualTransactionDialog extends StatefulWidget {
  final VaultTransactionEntity transaction;
  final Function(double newAmount, String newDescription) onSubmit;

  const EditManualTransactionDialog({
    super.key,
    required this.transaction,
    required this.onSubmit,
  });

  @override
  State<EditManualTransactionDialog> createState() =>
      _EditManualTransactionDialogState();
}

class _EditManualTransactionDialogState
    extends State<EditManualTransactionDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(
      text: widget.transaction.description,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() => _errorText = AppStrings.validationFieldRequired.tr());
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(
        () => _errorText = AppStrings.validationAmountGreaterThanZero.tr(),
      );
      return;
    }

    final note = _noteController.text.trim();
    widget.onSubmit(amount, note);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isIn = widget.transaction.direction == VaultTransactionDirection.inFlow;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.scafoldBackGround,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIn
                        ? AppStrings.editManualDeposit.tr()
                        : AppStrings.editManualWithdrawal.tr(),
                    style: TextStyles.customStyle(
                      color: AppColors.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.enterAmount.tr(),
                    style: TextStyles.customStyle(
                      color: AppColors.disabledColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: _errorText != null
                          ? Border.all(color: AppColors.error)
                          : null,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Text(
                          AppStrings.currencyEgp.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.disabledColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            cursorColor: AppColors.primaryColor,
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            autofocus: true,
                            style: TextStyles.customStyle(
                              color: AppColors.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyles.customStyle(
                                color: AppColors.disabledColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorText!,
                      style: TextStyles.customStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.enterNotes.tr(),
                    style: TextStyles.customStyle(
                      color: AppColors.disabledColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      cursorColor: AppColors.primaryColor,
                      controller: _noteController,
                      style: TextStyles.customStyle(
                        color: AppColors.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: AppStrings.enterNotes.tr(),
                        hintStyle: TextStyles.customStyle(
                          color: AppColors.disabledColor,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      CustomButton(
                        text: AppStrings.edit.tr(),
                        height: 56,
                        borderRadius: 12,
                        color: AppColors.primaryColor,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: AppStrings.cancel.tr(),
                        height: 56,
                        borderRadius: 12,
                        color: Colors.transparent,
                        textColor: AppColors.disabledColor,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:tahsel/features/invoice/presentation/widgets/sheet_field.dart';

class RecordPaymentSheet extends StatefulWidget {
  final InvoiceEntity invoice;
  final VoidCallback onSuccess;

  const RecordPaymentSheet({
    super.key,
    required this.invoice,
    required this.onSuccess,
  });

  @override
  State<RecordPaymentSheet> createState() => RecordPaymentSheetState();
}

class RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // amount may be 0 — that means full-debt with no cash collected right now.
    if (amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invoicePaymentValidation.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (amount > widget.invoice.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invoicePaymentExceedsRemaining.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final uid = AppStrings.userToken;
    // Debt is created automatically inside recordPayment when remaining > 0.
    context.read<InvoiceCubit>().recordPayment(
      uid: uid,
      invoiceId: widget.invoice.id,
      invoice: widget.invoice,
      paidNow: amount,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );

    Navigator.of(context).pop();
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.invoice.remainingAmount;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            AppStrings.invoiceRecordPayment.tr(),
            style: TextStyles.customStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.invoiceRemainingAmount.tr()}: ${remaining.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
            style: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.blackLight,
            ),
          ),
          const SizedBox(height: 20),

          // Amount field
          SheetField(
            controller: _amountController,
            label: AppStrings.invoicePaymentAmount.tr(),
            hint: '0.00',
            isNumber: true,
            suffix: AppStrings.currencyEgp.tr(),
          ),
          const SizedBox(height: 12),

          // Note field
          SheetField(
            controller: _noteController,
            label: AppStrings.invoicePaymentNote.tr(),
            hint: AppStrings.invoicePaymentNoteHint.tr(),
          ),
          const SizedBox(height: 24),

          // Info banner: auto-debt notice when amount < remaining
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.invoiceAutoDebtNotice.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submit(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppStrings.confirm.tr(),
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

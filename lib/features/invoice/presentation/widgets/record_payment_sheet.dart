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
import 'package:tahsel/shared/widgets/fields/payment_method_selector.dart';

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
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _customerNameController;
  String _paymentMethod = 'cash'; // 'cash', 'card', 'debt'

  @override
  void initState() {
    super.initState();
    final rem = widget.invoice.remainingAmount;
    final initialAmountStr = rem == rem.truncateToDouble()
        ? rem.toInt().toString()
        : rem.toString();
    _amountController = TextEditingController(text: initialAmountStr);
    _noteController = TextEditingController();
    _customerNameController = TextEditingController(
      text: widget.invoice.customerName ?? '',
    );

    if (widget.invoice.paymentMethod != null &&
        ['cash', 'card', 'debt'].contains(widget.invoice.paymentMethod)) {
      _paymentMethod = widget.invoice.paymentMethod!;
      if (_paymentMethod == 'debt') {
        _amountController.text = '0';
      }
    }

    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final remaining = widget.invoice.remainingAmount;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invoicePaymentValidation.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (amount > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invoicePaymentExceedsRemaining.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if ((_paymentMethod == 'cash' || _paymentMethod == 'card') && amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.paymentAmountMustBePositive.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final effectiveCustomerName = _customerNameController.text.trim().isNotEmpty
        ? _customerNameController.text.trim()
        : (widget.invoice.customerName ?? '').trim();

    if ((_paymentMethod == 'debt' || amount < remaining) &&
        effectiveCustomerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.customerNameRequiredForDebt.tr()),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    final uid = AppStrings.userToken;
    final String methodLabel;
    switch (_paymentMethod) {
      case 'card':
        methodLabel = AppStrings.paymentCardSales.tr();
        break;
      case 'debt':
        methodLabel = AppStrings.paymentDebtSales.tr();
        break;
      case 'cash':
      default:
        methodLabel = AppStrings.paymentCashSales.tr();
        break;
    }

    final userNote = _noteController.text.trim();
    final combinedNote = userNote.isNotEmpty
        ? '$userNote ($methodLabel)'
        : methodLabel;

    context.read<InvoiceCubit>().recordPayment(
      uid: uid,
      invoiceId: widget.invoice.id,
      invoice: widget.invoice,
      paidNow: amount,
      note: combinedNote,
      paymentMethod: _paymentMethod,
      customerName: effectiveCustomerName.isNotEmpty
          ? effectiveCustomerName
          : null,
    );

    Navigator.of(context).pop();
    widget.onSuccess();
  }

  Widget _buildStatusExplainingCard(double amount, double remaining) {
    final IconData icon;
    final Color color;
    final String text;

    if (_paymentMethod == 'debt') {
      if (amount <= 0) {
        icon = Icons.receipt_long_rounded;
        color = const Color(0xFFE65100);
        text = AppStrings.invoiceDebtFullInfo.tr();
      } else {
        icon = Icons.payments_outlined;
        color = const Color(0xFFE65100);
        text = AppStrings.invoiceDebtPartialInfo.tr();
      }
    } else if (_paymentMethod == 'card') {
      if (amount >= remaining) {
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.primaryColor;
        text = AppStrings.invoiceCardFullInfo.tr();
      } else if (amount > 0) {
        icon = Icons.info_outline_rounded;
        color = AppColors.orange;
        text = AppStrings.invoiceCardPartialInfo.tr();
      } else {
        icon = Icons.warning_amber_rounded;
        color = AppColors.warning;
        text = AppStrings.paymentAmountMustBePositive.tr();
      }
    } else {
      if (amount >= remaining) {
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.success;
        text = AppStrings.invoiceCashFullInfo.tr();
      } else if (amount > 0) {
        icon = Icons.info_outline_rounded;
        color = AppColors.orange;
        text = AppStrings.invoiceCashPartialInfo.tr();
      } else {
        icon = Icons.warning_amber_rounded;
        color = AppColors.warning;
        text = AppStrings.paymentAmountMustBePositive.tr();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyles.customStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.invoice.remainingAmount;
    final currentAmount = double.tryParse(_amountController.text) ?? 0.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool hasExistingCustomer =
        widget.invoice.customerName != null &&
        widget.invoice.customerName!.trim().isNotEmpty;
    final bool isDebtOrPartial =
        _paymentMethod == 'debt' || currentAmount < remaining;

    final String confirmLabel;
    switch (_paymentMethod) {
      case 'card':
        confirmLabel = AppStrings.confirmCardPayment.tr();
        break;
      case 'debt':
        confirmLabel = AppStrings.confirmDebtRecording.tr();
        break;
      case 'cash':
      default:
        confirmLabel = AppStrings.confirmCashPayment.tr();
        break;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 14),

            // Header Row (Title + Remaining + Close Button)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.invoiceRecordPayment.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppStrings.invoiceRemainingAmount.tr()}: ${remaining.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.blackLight,
                  tooltip: AppStrings.cancel.tr(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer Info / Missing Customer Input
            if (hasExistingCustomer)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scafoldBackGround,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${AppStrings.customerName.tr()}: ${widget.invoice.customerName!}',
                        style: TextStyles.customStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else if (isDebtOrPartial) ...[
              SheetField(
                controller: _customerNameController,
                label: AppStrings.customerNameRequiredForDebt.tr(),
                hint: AppStrings.customerName.tr(),
              ),
              const SizedBox(height: 14),
            ],

            // Payment method selection (Cash vs Card vs Debt)
            PaymentMethodSelector(
              selectedMethod: _paymentMethod,
              showDebtOption: true,
              isCompact: false,
              onMethodChanged: (method) {
                setState(() {
                  _paymentMethod = method;
                  final currentAmt =
                      double.tryParse(_amountController.text) ?? 0.0;
                  if (method == 'debt') {
                    if ((currentAmt - remaining).abs() < 0.001) {
                      _amountController.text = '0';
                    }
                  } else {
                    if (currentAmt == 0) {
                      _amountController.text =
                          remaining == remaining.truncateToDouble()
                          ? remaining.toInt().toString()
                          : remaining.toString();
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 14),

            // Amount field
            SheetField(
              controller: _amountController,
              label: _paymentMethod == 'debt'
                  ? AppStrings.downPayment.tr()
                  : AppStrings.invoicePaymentAmount.tr(),
              hint: '0.00',
              isNumber: true,
              suffix: AppStrings.currencyEgp.tr(),
              actionLabel: _paymentMethod == 'debt'
                  ? (_amountController.text != '0'
                        ? AppStrings.noDownPayment.tr()
                        : AppStrings.paidFull.tr())
                  : AppStrings.paidFull.tr(),
              onAction: () {
                if (_paymentMethod == 'debt' && _amountController.text != '0') {
                  _amountController.text = '0';
                } else {
                  if (remaining == remaining.truncateToDouble()) {
                    _amountController.text = remaining.toInt().toString();
                  } else {
                    _amountController.text = remaining.toString();
                  }
                }
              },
            ),
            const SizedBox(height: 12),

            // Explanatory card
            _buildStatusExplainingCard(currentAmount, remaining),
            const SizedBox(height: 14),

            // Note field
            SheetField(
              controller: _noteController,
              label: AppStrings.invoicePaymentNote.tr(),
              hint: AppStrings.invoicePaymentNoteHint.tr(),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _paymentMethod == 'debt'
                      ? AppColors.warning
                      : (_paymentMethod == 'card'
                            ? AppColors.primaryColor
                            : AppColors.success),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: TextStyles.customStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Pay later button
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppStrings.payLater.tr(),
                  style: TextStyles.customStyle(
                    color: AppColors.blackLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

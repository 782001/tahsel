import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debt_card.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/partial_payment_dialog.dart';

class CustomerDebtsList extends StatelessWidget {
  const CustomerDebtsList({super.key});

  void _showPartialPaymentModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const PartialPaymentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        CustomerDebtCard(
          customerName: 'ألكسندر رايت',
          lastTransactionDate: '٢٤ أكتوبر ٢٠٢٣',
          amount: 1240.00,
          status: 'متأخر',
          statusColor: AppColors.warning,
          onPartialPayment: () => _showPartialPaymentModal(context),
          onFullPayment: () {},
        ),
        CustomerDebtCard(
          customerName: 'إيلينا رودريغيز',
          lastTransactionDate: '١٢ نوفمبر ٢٠٢٣',
          amount: 450.25,
          status: 'رصيد',
          statusColor: AppColors.info,
          onPartialPayment: () => _showPartialPaymentModal(context),
          onFullPayment: () {},
        ),
        CustomerDebtCard(
          customerName: 'ماركوس ثورن',
          lastTransactionDate: '٠٨ نوفمبر ٢٠٢٣',
          amount: 2890.00,
          status: 'حرج',
          statusColor: AppColors.error,
          onPartialPayment: () => _showPartialPaymentModal(context),
          onFullPayment: () {},
        ),
        CustomerDebtCard(
          customerName: 'سارة جينكينز',
          lastTransactionDate: '٣٠ أكتوبر ٢٠٢٣',
          amount: 85.00,
          status: 'بسيط',
          statusColor: AppColors.success,
          onPartialPayment: () => _showPartialPaymentModal(context),
          onFullPayment: () {},
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

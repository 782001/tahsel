import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/customer_debts/presentation/screens/customer_debt_detail_screen.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debt_card.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/partial_payment_dialog.dart';

class CustomerDebtsList extends StatelessWidget {
  const CustomerDebtsList({super.key});

  // ── Sample data (replace with real data from Cubit/Repository) ──────────────
  static final List<CustomerDebtDetail> _customers = [
    CustomerDebtDetail(
      customerName: 'ألكسندر رايت',
      status: AppStrings.debtStatusOverdue,
      statusColor: AppColors.warning,
      items: [
        const DebtItem(
          itemDescription: 'بلايستيشن - ٣ ساعات',
          amountPaid: 0,
          remainingDebt: 450,
          date: '١٠ أكتوبر ٢٠٢٣',
        ),
        const DebtItem(
          itemDescription: 'كافيه - مشروبات',
          amountPaid: 90,
          remainingDebt: 60,
          date: '١٨ أكتوبر ٢٠٢٣',
        ),
        const DebtItem(
          itemDescription: 'بلايستيشن - ٥ ساعات',
          amountPaid: 0,
          remainingDebt: 740,
          date: '٢٤ أكتوبر ٢٠٢٣',
        ),
      ],
    ),
    CustomerDebtDetail(
      customerName: 'إيلينا رودريغيز',
      status: AppStrings.debtStatusBalance,
      statusColor: AppColors.info,
      items: [
        const DebtItem(
          itemDescription: 'بلايستيشن - ٢ ساعات',
          amountPaid: 150,
          remainingDebt: 150,
          date: '٠٥ نوفمبر ٢٠٢٣',
        ),
        const DebtItem(
          itemDescription: 'مستلزمات متنوعة',
          amountPaid: 50,
          remainingDebt: 100.25,
          date: '١٢ نوفمبر ٢٠٢٣',
        ),
      ],
    ),
    CustomerDebtDetail(
      customerName: 'ماركوس ثورن',
      status: AppStrings.debtStatusCritical,
      statusColor: AppColors.error,
      items: [
        const DebtItem(
          itemDescription: 'بلايستيشن - ٤ ساعات',
          amountPaid: 0,
          remainingDebt: 800,
          date: '٠١ نوفمبر ٢٠٢٣',
        ),
        const DebtItem(
          itemDescription: 'كافيه - طلبات',
          amountPaid: 0,
          remainingDebt: 390,
          date: '٠٤ نوفمبر ٢٠٢٣',
        ),
        const DebtItem(
          itemDescription: 'بلايستيشن - ٦ ساعات',
          amountPaid: 200,
          remainingDebt: 1000,
          date: '٠٨ نوفمبر ٢٠٢٣',
        ),
        const DebtItem(
          itemDescription: 'مستلزمات',
          amountPaid: 0,
          remainingDebt: 700,
          date: '٠٩ نوفمبر ٢٠٢٣',
        ),
      ],
    ),
    CustomerDebtDetail(
      customerName: 'سارة جينكينز',
      status: AppStrings.debtStatusMinor,
      statusColor: AppColors.primaryColor,
      items: [
        const DebtItem(
          itemDescription: 'كافيه - مشروب',
          amountPaid: 35,
          remainingDebt: 50,
          date: '٢٨ أكتوبر ٢٠٢٣',
        ),
        const DebtItem(
          itemDescription: 'بلايستيشن - ١ ساعة',
          amountPaid: 50,
          remainingDebt: 35,
          date: '٣٠ أكتوبر ٢٠٢٣',
        ),
      ],
    ),
  ];

  void _showPartialPaymentModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const PartialPaymentDialog(),
    );
  }

  void _navigateToDetail(BuildContext context, CustomerDebtDetail detail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDebtDetailScreen(detail: detail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _customers.length + 1, // +1 for bottom spacing
      itemBuilder: (context, index) {
        if (index == _customers.length) {
          return const SizedBox(height: 100);
        }

        final detail = _customers[index];
        return CustomerDebtCard(
          customerName: detail.customerName,
          lastTransactionDate: detail.lastTransactionDate,
          amount: detail.totalDebt,
          status: detail.status.tr(),
          statusColor: detail.statusColor,
          onTap: () => _navigateToDetail(context, detail),
          onPartialPayment: () => _showPartialPaymentModal(context),
          onFullPayment: () {},
        );
      },
    );
  }
}

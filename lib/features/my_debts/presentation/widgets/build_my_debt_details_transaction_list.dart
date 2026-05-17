import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/presentation/screens/my_debt_details_report_screen.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_details_transaction_item.dart';

class BuildMyDebtDetailsTransactionList extends StatelessWidget {
  const BuildMyDebtDetailsTransactionList({
    super.key,
    required this.widget,
    required this.transactions,
    required this.debt,
    this.isPaginationLoading = false,
  });

  final MyDebtDetailsReportScreen widget;
  final List<PaymentEntity> transactions;
  final MyDebtItemEntity? debt;
  final bool isPaginationLoading;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == transactions.length) {
            if (isPaginationLoading) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                    strokeWidth: 4,
                  ),
                ),
              );
            }
            return const SizedBox(height: 50);
          }
          final transaction = transactions[index];
          return MyDebtDetailsTransactionItem(
            transaction: transaction,
            debtId: widget.debtId,
            customerName: debt?.personName ?? '',
          );
        }, childCount: transactions.length + 1),
      ),
    );
  }
}

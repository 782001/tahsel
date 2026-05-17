import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/presentation/screens/my_debt_details_report_screen.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_details_transaction_item.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

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
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = isDesktop && screenWidth > 800
        ? (screenWidth - 800) / 2
        : 16.w;

    if (isDesktop) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 8,
        ),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 140,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= transactions.length) {
                if (index == transactions.length && isPaginationLoading) {
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
            },
            childCount: transactions.length + 2,
          ),
        ),
      );
    }

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

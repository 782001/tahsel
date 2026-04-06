import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
// Removed unused import
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/customer_debts/presentation/screens/customer_debt_detail_screen.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debt_card.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/partial_payment_dialog.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import '../../../debt/presentation/cubit/debt_state.dart';
import '../../../debt/domain/entities/debt_entity.dart';

class CustomerDebtsList extends StatefulWidget {
  final String searchQuery;
  const CustomerDebtsList({super.key, this.searchQuery = ''});

  @override
  State<CustomerDebtsList> createState() => _CustomerDebtsListState();
}

class _CustomerDebtsListState extends State<CustomerDebtsList> {
  @override
  void initState() {
    super.initState();
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid != null) {
      context.read<DebtCubit>().getDebts(uid);
    }
  }

  void _showPartialPaymentModal(BuildContext context, String customerName, double totalRemaining) {
    final cubit = context.read<DebtCubit>();
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: PartialPaymentDialog(
          customerName: customerName,
          totalRemaining: totalRemaining,
        ),
      ),
    );
  }

  void _onPayFull(BuildContext context, String customerName) {
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid != null) {
      context.read<DebtCubit>().markAsPaid(uid, customerName);
    }
  }

  void _navigateToDetail(BuildContext context, CustomerDebtDetail detail) {
    final cubit = context.read<DebtCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: CustomerDebtDetailScreen(detail: detail),
        ),
      ),
    );
  }

  List<CustomerDebtDetail> _groupDebts(List<DebtEntity> debts) {
    final Map<String, List<DebtEntity>> grouped = {};
    for (var debt in debts) {
      final name = debt.customerName ?? 'Unknown';
      if (widget.searchQuery.isEmpty ||
          name.toLowerCase().contains(widget.searchQuery.toLowerCase())) {
        grouped.putIfAbsent(name, () => []).add(debt);
      }
    }

    return grouped.entries
        .map((entry) => CustomerDebtDetail.fromEntities(entry.key, entry.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebtCubit, DebtState>(
      builder: (context, state) {
        if (state is DebtLoading) {
          return  Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        if (state is DebtFailure) {
          return Center(child: Text(state.message));
        }

        if (state is DebtsFetchSuccess) {
          final customers = _groupDebts(state.debts);

          if (customers.isEmpty) {
            return Center(
              child: Text(
                AppStrings.noCustomerDebts
                    .tr(), // Or a more specific empty state string
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(color: AppColors.primaryColor,
            onRefresh: () async {
              final uid = sl<FirebaseAuth>().currentUser?.uid;
              if (uid != null) {
                await context.read<DebtCubit>().getDebts(uid);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: customers.length + 1, // +1 for bottom spacing
              itemBuilder: (context, index) {
                if (index == customers.length) {
                  return const SizedBox(height: 100);
                }

                final detail = customers[index];
                return CustomerDebtCard(
                  customerName: detail.customerName,
                  lastTransactionDate: detail.lastTransactionDate,
                  amount: detail.totalDebt,
                  status: detail.status.tr(),
                  statusColor: detail.statusColor,
                  onTap: () => _navigateToDetail(context, detail),
                  onPartialPayment: () => _showPartialPaymentModal(
                    context,
                    detail.customerName,
                    detail.totalDebt,
                  ),
                  onFullPayment: () => _onPayFull(context, detail.customerName),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/presentation/widgets/notification_dialog.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/customer_debts/presentation/screens/customer_debt_detail_screen.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debt_card.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/partial_payment_dialog.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/skeletons/customer_debt_skeleton.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';

import '../../../debt/domain/entities/debt_entity.dart';
import '../../../debt/presentation/cubit/debt_state.dart';

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
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<DebtCubit>().getDebts(uid);
    }
  }

  void _showPartialPaymentModal(
    BuildContext context,
    String customerName,
    double totalRemaining,
    DebtEntity? debt,
  ) {
    final cubit = context.read<DebtCubit>();
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: PartialPaymentDialog(
          customerName: customerName,
          totalRemaining: totalRemaining,
          debt: debt,
        ),
      ),
    );
  }

  void _onPayFull(BuildContext context, DebtEntity debt) {
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<DebtCubit>().markItemAsPaid(
        debt: debt,
        totalRemainingBefore: debt.remainingAmount,
      );
    }
  }

  void _onDeleteDebt(BuildContext context, DebtEntity debt) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),

          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.confirmDeleteDebtTitle.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              AppStrings.confirmDeleteDebtMessage.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.blackLight,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  AppStrings.cancel.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.disabledColor,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final uid = AppStrings.userToken;
                  if (uid.isNotEmpty) {
                    context.read<DebtCubit>().deleteDebtItem(
                      uid,
                      debt.id ?? '',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppStrings.delete.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(
    BuildContext context,
    CustomerDebtDetail detail,
  ) async {
    final cubit = context.read<DebtCubit>();
    final isShop = context.read<MainLayoutCubit>().isShop;
    final hasChanged = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: CustomerDebtDetailScreen(detail: detail, isShop: isShop),
        ),
      ),
    );

    if (hasChanged == true) {
      final uid = AppStrings.userToken;
      if (uid.isNotEmpty) {
        cubit.getDebts(uid, forceRefresh: true);
      }
    }
  }

  static List<CustomerDebtDetail> _filterAndGroupDebts(
    Map<String, dynamic> params,
  ) {
    final List<DebtEntity> debts = params['debts'];
    final String query = params['query'].toString().toLowerCase();

    // Group debts by customerName
    final Map<String, List<DebtEntity>> groupedMap = {};
    for (var debt in debts) {
      final name = debt.customerName ?? 'Unknown';

      final nameMatches = name.toLowerCase().contains(query);
      final ledgerMatches = (debt.ledgerNumber ?? '').toLowerCase().contains(
        query,
      );
      final detailsMatches = (debt.productOrSessionDetails ?? '')
          .toLowerCase()
          .contains(query);
      final phoneNumberMatches = (debt.phoneNumber ?? '').contains(query);

      if (query.isEmpty ||
          nameMatches ||
          ledgerMatches ||
          detailsMatches ||
          phoneNumberMatches) {
        if (!groupedMap.containsKey(name)) {
          groupedMap[name] = [];
        }
        groupedMap[name]!.add(debt);
      }
    }

    final List<CustomerDebtDetail> results = groupedMap.entries.map((entry) {
      return CustomerDebtDetail.fromEntities(entry.key, entry.value);
    }).toList();

    return results..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtCubit, DebtState>(
      listener: (context, state) {
        if (state is DebtDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 500),
              content: Text(AppStrings.deleteDebtSuccess.tr()),
            ),
          );
        }
        if (state is DebtPaymentSuccess) {
          NotificationDialog.show(
            context: context,
            customerName: state.customerName,
            amountPaid: state.amountPaid,
            remainingBalance: state.remainingBalance,
            note: state.note,
            totalDebt: state.totalAmount,
          );
        }
        if (state is DebtFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 500),
              content: Text(AppStrings.deleteDebtFailed.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DebtLoading) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const CustomerDebtCardSkeleton(),
              childCount: 5,
            ),
          );
        }

        if (state is DebtFailure) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                AppStrings.noCustomerDebts.tr(),
                style: TextStyles.customStyle(color: AppColors.grey),
              ),
            ),
          );
        }

        if (state is DebtsFetchSuccess) {
          final customers = _filterAndGroupDebts({
            'debts': state.debts,
            'query': widget.searchQuery,
          });

          if (customers.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Text(
                  AppStrings.noCustomerDebts.tr(),
                  style: TextStyles.customStyle(color: AppColors.grey),
                ),
              ),
            );
          }

          final isDesktop = ResponsiveLayout.isDesktop(context);

          if (isDesktop) {
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 130,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: customers.length,
                      itemBuilder: (context, index) =>
                          _buildDebtCard(context, customers[index], state),
                    ),
                    _buildFooter(state),
                  ],
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == customers.length) {
                  return _buildFooter(state);
                }

                return _buildDebtCard(context, customers[index], state);
              }, childCount: customers.length + 1),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildDebtCard(
    BuildContext context,
    CustomerDebtDetail detail,
    DebtsFetchSuccess state,
  ) {
    final debtEntity = detail.items.first.entity;
    return CustomerDebtCard(
      customerName: detail.customerName,
      ledgerNumber: detail.ledgerNumber,
      description: detail.items.isNotEmpty
          ? detail.items.first.itemDescription
          : null,
      lastTransactionDate: detail.lastTransactionDate,
      amount: detail.totalDebt,
      status: detail.status.tr(),
      statusColor: detail.statusColor,
      onTap: () => _navigateToDetail(context, detail),
      onPartialPayment: () => _showPartialPaymentModal(
        context,
        detail.customerName,
        detail.totalDebt,
        debtEntity,
      ),
      onFullPayment: () => _onPayFull(context, debtEntity),
      onDelete: () => _onDeleteDebt(context, debtEntity),
    );
  }

  Widget _buildFooter(DebtsFetchSuccess state) {
    if (state.isPaginationLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return const SizedBox(height: 100);
  }
}

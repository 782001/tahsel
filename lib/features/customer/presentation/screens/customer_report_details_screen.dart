import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

import '../../../../core/services/injection_container.dart';
import '../../domain/entities/customer_operation.dart';
import '../cubit/customer_details/customer_details_cubit.dart';
import '../cubit/customer_details/customer_details_state.dart';
import '../widgets/customer_summary_card.dart';

class CustomerReportDetailsScreen extends StatelessWidget {
  final String uid;
  final String customerName;

  const CustomerReportDetailsScreen({
    super.key,
    required this.uid,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CustomerDetailsCubit>()..fetchCustomerDetails(uid, customerName),
      child: Scaffold(
        appBar: AppBar(
          title: Text(customerName),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _CustomerDetailsBody(),
      ),
    );
  }
}

class _CustomerDetailsBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerDetailsCubit, CustomerDetailsState>(
      builder: (context, state) {
        if (state is CustomerDetailsLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        if (state is CustomerDetailsError) {
          return Center(child: Text(state.message));
        }

        if (state is CustomerDetailsLoaded) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: CustomerSummaryCard(
                    totalSpent: state.totalSpent,
                    totalPaid: state.totalPaid,
                    remaining: state.remaining,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      AppStrings.allOperations.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              if (state.operations.isEmpty)
                SliverFillRemaining(
                  child: Center(child: Text(AppStrings.noData.tr())),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final op = state.operations[index];
                      return _buildOperationItem(context, op);
                    }, childCount: state.operations.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOperationItem(BuildContext context, CustomerOperation op) {
    final isPayment = op.type == CustomerOperationType.payment;
    final isDebt = op.type == CustomerOperationType.debt;

    Color iconColor;
    IconData icon;
    String typeLabel;

    if (isPayment) {
      iconColor = AppColors.success;
      icon = Icons.arrow_downward;
      typeLabel = AppStrings.payment.tr();
    } else if (isDebt) {
      iconColor = AppColors.orange;
      icon = Icons.history;
      typeLabel = AppStrings.debts.tr();
    } else {
      iconColor = AppColors.primaryColor;
      icon = Icons.shopping_bag;
      typeLabel = AppStrings.purchase.tr();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.debtCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blackLight.withAlpha(50)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (op.details != null && op.details!.isNotEmpty) ...[
              Expanded(
                child: Text(
                  op.details!,
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    color: AppColors.blackLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            Text(
              '${isPayment ? "-" : "+"}${op.amount.toStringAsFixed(2)} ${AppStrings.currencyEgp.tr()}',
              style: TextStyles.customStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPayment ? AppColors.success : AppColors.redColor,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(' • ', style: TextStyles.customStyle(color: AppColors.blackLight)),
                Text(
                  typeLabel,
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    color: AppColors.blackLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('yyyy/MM/dd hh:mm a').format(op.date),
              style: TextStyles.customStyle(
                fontSize: 11,
                color: AppColors.blackLight.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

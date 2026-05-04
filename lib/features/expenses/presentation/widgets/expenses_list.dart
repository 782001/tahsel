import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/expenses/domain/entities/expense_entity.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_state.dart';
import 'package:tahsel/features/expenses/presentation/screens/month_expenses_screen.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectivityState) {
        final bool isOffline = connectivityState is ConnectivityDisconnected;

        return BlocBuilder<ExpenseCubit, ExpenseState>(
          buildWhen: (previous, current) =>
              current is ExpenseLoading ||
              current is ExpenseFetchSuccess ||
              current is ExpenseFailure,
          builder: (context, state) {
            if (state is ExpenseLoading) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                ),
              );
            }

            if (state is ExpenseFetchSuccess) {
              final pending = state.pendingRecords;
              final months = state.months;

              if (pending.isEmpty && (months.isEmpty || isOffline)) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: Text(
                      AppStrings.noData.tr(),
                      style: const TextStyle(color: AppColors.grey),
                    ),
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pending.isNotEmpty) ...[
                      Text(
                        AppStrings.pendingUpload.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ...pending.map(
                        (record) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildPendingRecordItem(record),
                        ),
                      ),
                      if (months.isNotEmpty && !isOffline) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Divider(
                            color: AppColors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        Text(
                          AppStrings.allExpenses.tr(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ],
                    if (!isOffline)
                      ListView.separated(
                        itemCount: months.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final month = months[index];
                          return _buildMonthItem(context, month);
                        },
                      ),
                  ],
                ),
              );
            }

            if (state is ExpenseFailure) {
              return Center(child: Text(state.message));
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildPendingRecordItem(OfflineRecord record) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: 24.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.customerName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppStrings.waitingForInternet.tr(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${record.amount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthItem(BuildContext context, MonthlyExpenseGroup month) {
    return Slidable(
      key: ValueKey(month.monthKey),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) =>
                _confirmDeleteMonth(context, month.monthKey, month.monthName),
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            icon: Icons.delete,
            label: AppStrings.delete.tr(),
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final expenseCubit = context.read<ExpenseCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: expenseCubit,
                child: MonthExpensesScreen(
                  monthKey: month.monthKey,
                  monthName: month.monthName,
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primaryColor,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month.monthName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "${month.transactionCount} ${AppStrings.transactionCount.tr()}",
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${month.totalAmount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14.r,
                      color: AppColors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMonth(
    BuildContext context,
    String monthKey,
    String monthName,
  ) {
    final expenseCubit = context.read<ExpenseCubit>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.confirmDeleteTitle.tr()),
        content: Text(
          "${AppStrings.confirmDeleteMonthMessage.tr()} ($monthName)؟",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyle(color: AppColors.blackLight),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              expenseCubit.deleteMonth(AppStrings.userToken, monthKey);
            },
            child: Text(
              AppStrings.delete.tr(),
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

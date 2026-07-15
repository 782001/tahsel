import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/skeletons/customer_debt_skeleton.dart';
import 'package:tahsel/features/expenses/domain/entities/expense_entity.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_state.dart';
import 'package:tahsel/features/expenses/presentation/screens/month_expenses_screen.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';

import '../../../../core/utils/app_logger.dart';

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
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemBuilder: (context, index) =>
                      const CustomerDebtCardSkeleton(),
                  itemCount: 2,
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
                      style: TextStyles.customStyle(color: AppColors.grey),
                    ),
                  ),
                );
              }

              final isDesktop = ResponsiveLayout.isDesktop(context);

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 24.w,
                  vertical: 12.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pending.isNotEmpty) ...[
                      Text(
                        AppStrings.pendingUpload.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      if (isDesktop)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 110,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                          itemCount: pending.length,
                          itemBuilder: (context, index) =>
                              _buildPendingRecordItem(pending[index], true),
                        )
                      else
                        ...pending.map(
                          (record) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _buildPendingRecordItem(record, false),
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
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ],
                    if (!isOffline)
                      isDesktop
                          ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisExtent: 110,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                  ),
                              itemCount: months.length,
                              itemBuilder: (context, index) {
                                final month = months[index];
                                return _buildMonthItem(context, month, true);
                              },
                            )
                          : ListView.separated(
                              itemCount: months.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: 12.h),
                              itemBuilder: (context, index) {
                                final month = months[index];
                                return _buildMonthItem(context, month, false);
                              },
                            ),
                  ],
                ),
              );
            }

            if (state is ExpenseFailure) {
              AppLogger.printMessage(state.message);
              return Center(
                child: Text(
                  state.message,
                  style: TextStyles.customStyle(color: AppColors.error),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildPendingRecordItem(OfflineRecord record, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
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
            padding: EdgeInsets.all(isDesktop ? 10 : 12.r),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: isDesktop ? 24 : 24.r,
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  record.customerName,
                  style: TextStyles.customStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.waitingForInternet.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            "${record.amount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}",
            style: TextStyles.customStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthItem(
    BuildContext context,
    MonthlyExpenseGroup month,
    bool isDesktop,
  ) {
    return InkWell(
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
        padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
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
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 10 : 12.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primaryColor,
                size: isDesktop ? 24 : 24.r,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 16.w),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    month.monthName,
                    style: TextStyles.customStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${month.transactionCount} ${AppStrings.transactionCount.tr()}",
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${month.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                    style: TextStyles.customStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: isDesktop ? 14 : 14.r,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _confirmDeleteMonth(
    BuildContext context,
    String monthKey,
    String monthName,
  ) {
    final expenseCubit = context.read<ExpenseCubit>();
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),

          child: AlertDialog(
            title: Text(AppStrings.confirmDeleteTitle.tr()),
            content: Text(
              "${AppStrings.confirmDeleteMonthMessage.tr()} ($monthName)؟",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppStrings.cancel.tr(),
                  style: TextStyles.customStyle(color: AppColors.blackLight),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  expenseCubit.deleteMonth(AppStrings.userToken, monthKey);
                },
                child: Text(
                  AppStrings.delete.tr(),
                  style: TextStyles.customStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

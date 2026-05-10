import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/config/locale/app_localizations.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/skeletons/customer_debt_skeleton.dart';
import 'package:tahsel/features/expenses/domain/entities/expense_entity.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_state.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expense_card.dart';

class MonthExpensesScreen extends StatefulWidget {
  final String monthKey;
  final String monthName;

  const MonthExpensesScreen({
    super.key,
    required this.monthKey,
    required this.monthName,
  });

  @override
  State<MonthExpensesScreen> createState() => _MonthExpensesScreenState();
}

class _MonthExpensesScreenState extends State<MonthExpensesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseCubit>().fetchMonthDetails(
      AppStrings.userToken,
      widget.monthKey,
      widget.monthName,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        context.read<ExpenseCubit>().fetchMonths(AppStrings.userToken);
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.monthName,
            style: TextStyles.customStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.black,
              size: 20.r,
            ),
            onPressed: () {
              context.read<ExpenseCubit>().fetchMonths(AppStrings.userToken);
              Navigator.pop(context);
            },
          ),
        ),
        body: BlocListener<ExpenseCubit, ExpenseState>(
          listenWhen: (previous, current) =>
              current is ExpenseDeleteSuccess || current is ExpenseFailure,
          listener: (context, state) {
            if (state is ExpenseDeleteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.deleteSuccess.tr()),
                  backgroundColor: AppColors.success,
                ),
              );
              context.read<ExpenseCubit>().fetchMonthDetails(
                AppStrings.userToken,
                widget.monthKey,
                widget.monthName,
              );
            } else if (state is ExpenseFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: BlocBuilder<ExpenseCubit, ExpenseState>(
            builder: (context, state) {
              if (state is ExpenseLoading) {
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  itemCount: 8,
                  itemBuilder: (context, index) => const CustomerDebtCardSkeleton(),
                );
              } else if (state is ExpenseFailure) {
                return Center(child: Text(state.message));
              } else if (state is ExpenseMonthDetailsSuccess) {
                if (state.expenses.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.tr(AppStrings.noData),
                      style: TextStyles.customStyle(color: AppColors.grey),
                    ),
                  );
                }

                // Flatten the groups for efficient Sliver scrolling
                final List<dynamic> items = [];
                for (final group in state.expenses) {
                  items.add(group.date);
                  items.addAll(group.expenses);
                }

                final String locale = AppStrings.currentLang;

                return SizedBox.expand(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 24.h,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= items.length) return null;
                              final item = items[index];

                              // Header Item
                              if (item is DateTime) {
                                final dateStr = DateFormatter.formatLocalizedDate(
                                  item,
                                  locale,
                                );
                                return Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                  margin: EdgeInsets.only(
                                    bottom: 8.h,
                                    top: index == 0 ? 0 : 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.stitchBlue.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    dateStr,
                                    style: TextStyles.customStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.stitchBlue,
                                    ),
                                  ),
                                );
                              }

                              // Expense Item
                              if (item is ExpenseEntity) {
                                final expense = item;
                                IconData iconData = Icons.money;
                                
                                // Safe translation call
                                final categoryStr = AppLocalizations.tr(expense.category);

                                if (categoryStr == AppLocalizations.tr(AppStrings.operations)) {
                                  iconData = Icons.build_outlined;
                                } else if (categoryStr == AppLocalizations.tr(AppStrings.employees)) {
                                  iconData = Icons.people_outline;
                                } else if (categoryStr == AppLocalizations.tr(AppStrings.rents) ||
                                    categoryStr == AppLocalizations.tr(AppStrings.rent)) {
                                  iconData = Icons.home_outlined;
                                } else if (categoryStr == AppLocalizations.tr(AppStrings.salaries)) {
                                  iconData = Icons.attach_money_outlined;
                                }

                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: ExpenseCard(
                                    icon: iconData,
                                    title: categoryStr,
                                    subtitle: expense.description,
                                    amount: expense.amount,
                                    date: DateFormatter.formatNumericDate(
                                      expense.createdAt,
                                    ),
                                    onDelete: () =>
                                        _confirmDelete(context, expense.id ?? ''),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            childCount: items.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String expenseId) {
    final expenseCubit = context.read<ExpenseCubit>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.confirmDeleteTitle.tr()),
        content: Text(AppStrings.confirmDeleteMessage.tr()),
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
              expenseCubit.deleteExpense(
                AppStrings.userToken,
                expenseId,
                monthKey: widget.monthKey,
                monthName: widget.monthName,
              );
            },
            child: Text(
              AppStrings.delete.tr(),
              style: TextStyles.customStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

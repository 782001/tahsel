import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
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
            style: TextStyle(
              fontSize: 20.sp,
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
              // Refresh details
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
            buildWhen: (previous, current) =>
                current is ExpenseLoading ||
                current is ExpenseMonthDetailsSuccess ||
                current is ExpenseFailure,
            builder: (context, state) {
              if (state is ExpenseLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                );
              } else if (state is ExpenseFailure) {
                return Center(child: Text(state.message));
              } else if (state is ExpenseMonthDetailsSuccess) {
                if (state.expenses.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.noData.tr(),
                      style: const TextStyle(color: AppColors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 24.h,
                  ),
                  itemCount: state.expenses.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final expense = state.expenses[index];

                    IconData iconData = Icons.money;
                    if (expense.category.tr() == AppStrings.operations.tr()) {
                      iconData = Icons.build_outlined;
                    } else if (expense.category.tr() ==
                        AppStrings.employees.tr()) {
                      iconData = Icons.people_outline;
                    } else if (expense.category.tr() == AppStrings.rents.tr() ||
                        expense.category.tr() == AppStrings.rent.tr()) {
                      iconData = Icons.home_outlined;
                    } else if (expense.category.tr() ==
                        AppStrings.salaries.tr()) {
                      iconData = Icons.attach_money_outlined;
                    }

                    return ExpenseCard(
                      icon: iconData,
                      title: expense.category
                          .tr(), // Using translation for display
                      subtitle: expense.description,
                      amount: expense.amount,
                      date: DateFormatter.formatNumericDate(expense.createdAt),
                      onDelete: () => _confirmDelete(context, expense.id ?? ''),
                    );
                  },
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
              style: TextStyle(color: AppColors.blackLight),
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
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

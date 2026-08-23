import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/utils/vault_balance_helper.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/skeletons/customer_debt_skeleton.dart';
import 'package:tahsel/features/expenses/domain/entities/expense_entity.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_state.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expense_card.dart';
import 'package:tahsel/features/offline_sync/presentation/cubit/offline_sync_cubit.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<ExpenseCubit>().fetchMonthDetails(
      AppStrings.userToken,
      widget.monthKey,
      widget.monthName,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ExpenseCubit>().loadMoreExpenses(AppStrings.userToken);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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
          scrolledUnderElevation: 0,
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
        body: MultiBlocListener(
          listeners: [
            BlocListener<ExpenseCubit, ExpenseState>(
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
                  // We no longer auto-refresh details here.
                  // The user can refresh manually if they want to verify the deletion on the server.
                } else if (state is ExpenseFailure) {
                  if (state.message.contains(AppStrings.insufficientBalance) ||
                      state.message.contains('insufficient_balance')) {
                    VaultBalanceHelper.showInsufficientBalanceDialog(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            BlocListener<OfflineSyncCubit, OfflineSyncState>(
              listener: (context, state) {
                if (state is OfflineSyncSuccess) {
                  // We no longer auto-refresh details here to respect user preference for manual refresh.
                }
              },
            ),
          ],
          child: BlocBuilder<ExpenseCubit, ExpenseState>(
            builder: (context, state) {
              if (state is ExpenseLoading) {
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  itemCount: 8,
                  itemBuilder: (context, index) =>
                      const CustomerDebtCardSkeleton(),
                );
              } else if (state is ExpenseFailure) {
                return Center(child: Text(state.message));
              } else if (state is ExpenseMonthDetailsSuccess) {
                if (state.expenses.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.noData.tr(),
                      style: TextStyles.customStyle(color: AppColors.grey),
                    ),
                  );
                }

                final isDesktop = ResponsiveLayout.isDesktop(context);

                // Flatten the groups for efficient Sliver scrolling
                final List<dynamic> items = [];
                for (final group in state.expenses) {
                  items.add(group);
                  if (isDesktop) {
                    // On desktop, we keep the expenses list as a single item
                    // so we can render it in a grid within the day section
                    items.add(group.expenses);
                  } else {
                    items.addAll(group.expenses);
                  }
                }

                final String locale = AppStrings.currentLang;

                return SizedBox.expand(
                  child: RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: () async {
                      await context.read<ExpenseCubit>().fetchMonthDetails(
                        AppStrings.userToken,
                        widget.monthKey,
                        widget.monthName,
                        forceRefresh: true,
                      );
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : 24.w,
                            vertical: 24.h,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              if (index >= items.length) return null;
                              final item = items[index];

                              // Header Item
                              if (item is DayExpenseGroup) {
                                final dateStr =
                                    DateFormatter.formatLocalizedDate(
                                      item.date,
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
                                    color: AppColors.stitchBlue.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: TextStyles.customStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.stitchBlue,
                                        ),
                                      ),
                                      Text(
                                        "${item.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                        style: TextStyles.customStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Expense Grid (Desktop)
                              if (item is List<ExpenseEntity>) {
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisExtent: 120,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                  itemCount: item.length,
                                  itemBuilder: (context, idx) =>
                                      _buildExpenseItem(
                                        context,
                                        item[idx],
                                        isDesktop,
                                      ),
                                );
                              }

                              // Expense Item (Mobile)
                              if (item is ExpenseEntity) {
                                return _buildExpenseItem(
                                  context,
                                  item,
                                  isDesktop,
                                );
                              }
                              return const SizedBox.shrink();
                            }, childCount: items.length),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: state.isPaginationLoading
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.h),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
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

  Widget _buildExpenseItem(
    BuildContext context,
    ExpenseEntity expense,
    bool isDesktop,
  ) {
    IconData iconData = Icons.money;

    // Safe translation call
    final categoryStr = expense.category.tr();

    if (categoryStr == AppStrings.operations.tr()) {
      iconData = Icons.build_outlined;
    } else if (categoryStr == AppStrings.employees.tr()) {
      iconData = Icons.people_outline;
    } else if (categoryStr == AppStrings.rents.tr() ||
        categoryStr == AppStrings.rent.tr()) {
      iconData = Icons.home_outlined;
    } else if (categoryStr == AppStrings.salaries.tr()) {
      iconData = Icons.attach_money_outlined;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 0 : 8.h),
      child: ExpenseCard(
        icon: iconData,
        title: categoryStr,
        subtitle: expense.description,
        amount: expense.amount,
        date: DateFormatter.formatNumericDate(expense.createdAt),
        expenseId: expense.id,
        onDelete:
            (expense.id != null &&
                (expense.id!.startsWith('exp_pur_') ||
                    expense.id!.startsWith('exp_pay_') ||
                    expense.id!.startsWith('exp_emp_') ||
                    expense.id!.startsWith('exp_vault_manual_with_')))
            ? null
            : () => _confirmDelete(context, expense.id ?? ''),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String expenseId) {
    final expenseCubit = context.read<ExpenseCubit>();
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),

          child: AlertDialog(
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
        ),
      ),
    );
  }
}

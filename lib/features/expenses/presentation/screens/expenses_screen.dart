import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_state.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_app_bar.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_balance.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_list.dart';
import 'package:tahsel/features/offline_sync/presentation/cubit/offline_sync_cubit.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseCubit>().fetchMonths(AppStrings.userToken);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ExpenseCubit, ExpenseState>(
          listenWhen: (previous, current) =>
              current is ExpenseDeleteMonthSuccess || current is ExpenseFailure,
          listener: (context, state) {
            if (state is ExpenseDeleteMonthSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.deleteSuccess.tr()),
                  backgroundColor: AppColors.success,
                ),
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
        ),
        BlocListener<OfflineSyncCubit, OfflineSyncState>(
          listener: (context, state) {
            if (state is OfflineSyncSuccess) {
              // Refresh list when sync is successful
              context.read<ExpenseCubit>().fetchMonths(AppStrings.userToken, forceRefresh: true);
            }
          },
        ),
      ],
      child: SafeArea(
        child: Column(
          children: [
            const ExpensesAppBar(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryColor,
                onRefresh: () async {
                  context.read<ExpenseCubit>().fetchMonths(
                    AppStrings.userToken,
                  );
                },
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 20.h),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [ExpensesBalance(), ExpensesList()],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: QuickActionButton(
                        label: AppStrings.addExpense.tr(),
                        icon: Icons.add,
                        onPressed: () {
                          nav().pushNamed(AppRoutes.addExpense);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

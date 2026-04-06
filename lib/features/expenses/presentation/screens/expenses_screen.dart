import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_app_bar.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_balance.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_list.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';
import 'package:tahsel/routes/app_routes.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExpensesAppBar(),
            const ExpensesBalance(),

            const ExpensesList(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: QuickActionButton(
                label: AppStrings.addExpense.tr(),
                icon: Icons.add,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addExpense);
                },
              ),
            ),
            SizedBox(height: 100.h), // Padding for BottomNavBar
          ],
        ),
      ),
    );
  }
}

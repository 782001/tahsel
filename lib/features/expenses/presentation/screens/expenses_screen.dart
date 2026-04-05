import 'package:flutter/material.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_app_bar.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_balance.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_filters.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expenses_list.dart';

import '../../../../core/utils/app_colors.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      body: const SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpensesAppBar(),
              ExpensesBalance(),
              ExpensesFilters(),
              ExpensesList(),
              SizedBox(height: 100), // Padding for BottomNavBar
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

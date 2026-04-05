import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expense_card.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          ExpenseCard(
            icon: Icons.payments,
            title: AppStrings.salaries.tr(),
            subtitle: AppStrings.payrollDesc.tr(),
            amount: 8200.00,
            date: '٢٨ أكتوبر، ٢٠٢٣',
          ),
          Row(
            children: [
              Expanded(
                child: ExpenseCard(
                  icon: Icons.domain,
                  title: AppStrings.rent.tr(),
                  subtitle: '',
                  amount: 3500.00,
                  date: '٢٥ أكتوبر، ٢٠٢٣',
                  isGrid: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ExpenseCard(
                  icon: Icons.inventory_2,
                  title: AppStrings.supplies.tr(),
                  subtitle: '',
                  amount: 750.40,
                  date: '٢٢ أكتوبر، ٢٠٢٣',
                  isGrid: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Maintain spacing after the grid
          ExpenseCard(
            icon: Icons.electric_bolt,
            title: AppStrings.electricityBill.tr(),
            subtitle: AppStrings.mainOfficeServices.tr(),
            amount: 240.15,
            date: '٢٠ أكتوبر، ٢٠٢٣',
          ),
        ],
      ),
    );
  }
}

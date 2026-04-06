import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/expenses/presentation/widgets/expense_card.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: ListView.separated(
        itemCount: 5,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          return ExpenseCard(
            icon: Icons.payments_outlined,
            title: AppStrings.salaries.tr(),
            subtitle: AppStrings.payrollDesc.tr(),
            amount: 8200.00,
            date: '٢٨ أكتوبر، ٢٠٢٣',
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class ExpensesAppBar extends StatelessWidget {
  const ExpensesAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Center(
        child: Text(
          AppStrings.expenses.tr(),
          style: TextStyles.customStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

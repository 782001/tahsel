import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debts_header.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debts_list.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../shared/widgets/text_fields/custom_search_field.dart';

class CustomerDebtsScreen extends StatelessWidget {
  const CustomerDebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomerDebtsHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomSearchField(
                hintText: AppStrings.searchCustomer.tr(),
                onChanged: (val) {},
              ),
            ),
            const SizedBox(height: 24),
            const Expanded(child: CustomerDebtsList()),
          ],
        ),
      ),
    );
  }
}

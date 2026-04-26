import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer_debts/presentation/screens/customer_debts_screen.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debts_tab_view.dart';
import 'package:tahsel/core/services/injection_container.dart';

class UnifiedDebtsScreen extends StatelessWidget {
  const UnifiedDebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          backgroundColor: AppColors.scafoldBackGround,
          elevation: 0,
          toolbarHeight: 0, // Hide main toolbar
          bottom: TabBar(
            indicatorColor: AppColors.primaryColor,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.subTitleColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'DGAgnadeen',
            ),
            tabs: [
              Tab(text: AppStrings.myDebtsTab.tr()),
              Tab(text: AppStrings.customerDebtsTab.tr()),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MyDebtsTabView(),
            CustomerDebtsScreen(),
          ],
        ),
      ),
    );
  }
}

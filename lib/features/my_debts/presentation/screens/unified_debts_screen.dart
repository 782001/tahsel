import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer_debts/presentation/screens/customer_debts_screen.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/debts_tab_selector.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debts_tab_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/total_debts/total_debts_cubit.dart';

class UnifiedDebtsScreen extends StatefulWidget {
  const UnifiedDebtsScreen({super.key});

  @override
  State<UnifiedDebtsScreen> createState() => _UnifiedDebtsScreenState();
}

class _UnifiedDebtsScreenState extends State<UnifiedDebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<DebtCubit>()),
        BlocProvider(create: (context) => sl<MyDebtsCubit>()),
        BlocProvider(create: (context) => sl<TotalDebtsCubit>()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          backgroundColor: AppColors.scafoldBackGround,
          elevation: 0,
          toolbarHeight: 70, // Height for the custom tab selector
          flexibleSpace: SafeArea(
            child: DebtsTabSelector(
              selectedIndex: _tabController.index,
              onTabChanged: (index) {
                _tabController.animateTo(index);
              },
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            CustomerDebtsScreen(),
            MyDebtsTabView(),
          ],
        ),
      ),
    );
  }
}

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
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_summary_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/total_debts/total_debts_cubit.dart';
import 'package:tahsel/features/offline_sync/presentation/cubit/offline_sync_cubit.dart';

class UnifiedDebtsScreen extends StatefulWidget {
  const UnifiedDebtsScreen({super.key});

  @override
  State<UnifiedDebtsScreen> createState() => _UnifiedDebtsScreenState();
}

class _UnifiedDebtsScreenState extends State<UnifiedDebtsScreen>
    with SingleTickerProviderStateMixin {
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
        BlocProvider.value(value: sl<DebtCubit>()),
        BlocProvider.value(value: sl<MyDebtsCubit>()),
        BlocProvider.value(value: sl<MyDebtsSummaryCubit>()),
        BlocProvider.value(value: sl<TotalDebtsCubit>()),
      ],
      child: BlocListener<OfflineSyncCubit, OfflineSyncState>(
        listener: (context, state) {
          if (state is OfflineSyncSuccess) {
            final uid = AppStrings.userToken;
            if (uid.isNotEmpty) {
              context.read<DebtCubit>().getDebts(uid, forceRefresh: true);
              context.read<MyDebtsCubit>().loadPersons(uid, forceRefresh: true);
              context.read<MyDebtsSummaryCubit>().refreshSummary(uid);
            }
          }
        },
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
            children: const [CustomerDebtsScreen(), MyDebtsTabView()],
          ),
        ),
      ),
    );
  }
}

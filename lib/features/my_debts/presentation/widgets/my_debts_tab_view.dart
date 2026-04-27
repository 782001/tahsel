import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_state.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_card.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debts_summary_card.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/skeletons/my_debt_skeleton.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_search_field.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyDebtsTabView extends StatefulWidget {
  const MyDebtsTabView({super.key});

  @override
  State<MyDebtsTabView> createState() => _MyDebtsTabViewState();
}

class _MyDebtsTabViewState extends State<MyDebtsTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      context.read<MyDebtsCubit>().loadPersons(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton.extended(
          heroTag: 'add_my_debt_fab',
          backgroundColor: AppColors.primaryColor,
          onPressed: () {
            sl<NavigatorService>().pushNamed(AppRoutes.addMyDebt).then((_) {
              if (context.mounted) {
                _loadData();
              }
            });
          },
          label: Text(
            AppStrings.addNewDebt.tr(),
            style: TextStyles.customStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          icon:  Icon(Icons.add, color: AppColors.white),
        ),
      ),
      body: BlocListener<MyDebtsCubit, MyDebtsState>(
        listener: (context, state) {
          if (state.status == MyDebtsStatus.loaded && state.lastPaymentPerson != null) {
             // Show success dialog if needed
          }
          if (state.status == MyDebtsStatus.error && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 500),
                content: Text(state.message!.tr()),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<MyDebtsCubit, MyDebtsState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async => _loadData(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: MyDebtsSummaryCard()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomSearchField(
                        controller: _searchController,
                        hintText: AppStrings.searchByNameOrPhone.tr(),
                        onChanged: (val) {
                          context.read<MyDebtsCubit>().search(val);
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  if (state.status == MyDebtsStatus.loading && state.persons.isEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const MyDebtCardSkeleton(),
                        childCount: 5,
                      ),
                    )
                  else if (state.filteredPersons.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          AppStrings.noData.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.subTitleColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((
                          context,
                          index,
                        ) {
                          if (index == state.filteredPersons.length) {
                            return const SizedBox(height: 100);
                          }
                          final person = state.filteredPersons[index];
                          return MyDebtCard(person: person);
                        }, childCount: state.filteredPersons.length + 1),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

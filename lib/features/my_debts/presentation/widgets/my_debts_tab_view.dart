import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_card.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debts_summary_card.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_search_field.dart';

class MyDebtsTabView extends StatefulWidget {
  const MyDebtsTabView({super.key});

  @override
  State<MyDebtsTabView> createState() => _MyDebtsTabViewState();
}

class _MyDebtsTabViewState extends State<MyDebtsTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<MyDebtDetail>> _groupDebts(List<MyDebtEntity> debts) async {
    return compute(_filterAndGroupDebts, {
      'debts': debts,
      'query': _searchQuery,
    });
  }

  static List<MyDebtDetail> _filterAndGroupDebts(Map<String, dynamic> params) {
    final List<MyDebtEntity> debts = params['debts'];
    final String query = params['query'].toString().toLowerCase();

    final Map<String, List<MyDebtEntity>> grouped = {};
    for (var debt in debts) {
      final name = debt.personName;
      grouped.putIfAbsent(name, () => []).add(debt);
    }

    List<MyDebtDetail> results = grouped.entries
        .map((entry) => MyDebtDetail.fromEntities(entry.key, entry.value))
        .toList();

    if (query.isNotEmpty) {
      results = results.where((detail) {
        final nameMatches = detail.personName.toLowerCase().contains(query);
        final phoneMatches = (detail.phoneNumber ?? '').contains(query);
        return nameMatches || phoneMatches;
      }).toList();
    }

    return results..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
  }

  @override
  void initState() {
    super.initState();
    // Load debts when tab is initialized
    Future.microtask(() {
      if (mounted) {
        context.read<MyDebtsCubit>().loadMyDebts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton.extended(
          heroTag: 'add_my_debt_fab',
          backgroundColor: AppColors.primaryColor,
          onPressed: () {
            sl<NavigatorService>().pushNamed(AppRoutes.addMyDebt).then((_) {
              if (context.mounted) {
                context.read<MyDebtsCubit>().loadMyDebts();
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
          icon: Icon(Icons.add, color: AppColors.white),
        ),
      ),
      body: BlocBuilder<MyDebtsCubit, MyDebtsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () => context.read<MyDebtsCubit>().loadMyDebts(),
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
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (state.status == MyDebtsStatus.loading &&
                    state.debts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                else
                  FutureBuilder<List<MyDebtDetail>>(
                    future: _groupDebts(state.debts),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          state.debts.isNotEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        );
                      }

                      final persons = snapshot.data ?? [];

                      if (persons.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Text(
                              AppStrings.noData.tr(),
                              style: TextStyles.customStyle(
                                color: AppColors.subTitleColor,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index == persons.length) {
                              return const SizedBox(height: 80);
                            }
                            final detail = persons[index];
                            return MyDebtCard(detail: detail);
                          }, childCount: persons.length + 1),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

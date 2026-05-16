import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debts_header.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debts_list.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/text_fields/custom_search_field.dart';
import '../../../debt/presentation/cubit/debt_cubit.dart';
import '../../../debt/presentation/cubit/debt_state.dart';
import '../../../debt/presentation/cubit/total_debts/total_debts_cubit.dart';
import '../widgets/total_debts_summary_card.dart';

class CustomerDebtsScreen extends StatefulWidget {
  const CustomerDebtsScreen({super.key});

  @override
  State<CustomerDebtsScreen> createState() => _CustomerDebtsScreenState();
}

class _CustomerDebtsScreenState extends State<CustomerDebtsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final uid = AppStrings.userToken;
      if (uid.isNotEmpty) {
        context.read<DebtCubit>().loadMoreDebts(uid);
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      body: SafeArea(
        child: BlocListener<DebtCubit, DebtState>(
          listener: (context, state) {
            // When DebtCubit refreshes debts after any operation,
            // fetch latest global totals from summary
            if (state is DebtsFetchSuccess) {
              final uid = AppStrings.userToken;
              if (uid.isNotEmpty) {
                context.read<TotalDebtsCubit>().updateFromDebts(uid);
              }
            }
          },
          child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivityState) {
              final bool isOffline =
                  connectivityState is ConnectivityDisconnected;

              return RefreshIndicator(
                color: AppColors.primaryColor,
                onRefresh: () async {
                  final uid = AppStrings.userToken;
                  if (uid.isNotEmpty) {
                    await context.read<DebtCubit>().getDebts(
                      uid,
                      forceRefresh: true,
                    );
                    // No need to manually refresh TotalDebtsCubit —
                    // the BlocListener above handles it automatically
                  }
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    const SliverToBoxAdapter(child: CustomerDebtsHeader()),
                    if (!isOffline) ...[
                      const SliverToBoxAdapter(child: TotalDebtsSummaryCard()),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: InkWell(
                            onTap: () {
                              final uid = AppStrings.userToken;
                              if (uid.isNotEmpty) {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.monthlyCollected,
                                  arguments: uid,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.analytics_rounded,
                                    color: AppColors.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppStrings.collectedAmount.tr(),
                                      style: TextStyles.customStyle(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppColors.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: CustomSearchField(
                            controller: _searchController,
                            hintText: AppStrings.searchCustomer.tr(),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      CustomerDebtsList(searchQuery: _searchQuery),
                    ] else
                      SliverFillRemaining(
                        child: NoInternetView(
                          onRetry: () {
                            context
                                .read<ConnectivityCubit>()
                                .checkConnectivity();
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

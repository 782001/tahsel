import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/presentation/widgets/add_customer_dialog.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_list_card.dart';
import 'package:tahsel/features/customer/presentation/widgets/skeletons/customer_card_skeleton.dart';

import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import '../../../../core/services/injection_container.dart';
import '../cubit/customer_reports/customer_reports_cubit.dart';
import '../cubit/customer_reports/customer_reports_state.dart';

class CustomersListScreen extends StatelessWidget {
  final String uid;

  const CustomersListScreen({super.key, required this.uid});

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: context.read<CustomerReportsCubit>(),
        child: AddCustomerDialog(uid: uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CustomerReportsCubit>()..fetchCustomers(uid),
      child: Builder(
        builder: (context) {
          final isDesktop = ResponsiveLayout.isDesktop(context);
          final isPushed = !(ModalRoute.of(context)?.isFirst ?? true);
          final showBackButton = isPushed || !isDesktop;
          return Scaffold(
            backgroundColor: AppColors.scafoldBackGround,
            appBar: AppBar(
              centerTitle: true,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                AppStrings.customers.tr(),
                style: TextStyles.customStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              leading: showBackButton
                  ? IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.black,
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          try {
                            context.read<MainLayoutCubit>().changeBottomNav(0);
                          } catch (_) {}
                        }
                      },
                    )
                  : null,
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddCustomerDialog(context),
              backgroundColor: AppColors.primaryColor,
              elevation: 3,
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
              ),
              label: Text(
                AppStrings.addCustomer.tr(),
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            body: _CustomersListBody(uid: uid),
          );
        },
      ),
    );
  }
}

class _CustomersListBody extends StatefulWidget {
  final String uid;
  const _CustomersListBody({required this.uid});

  @override
  State<_CustomersListBody> createState() => _CustomersListBodyState();
}

class _CustomersListBodyState extends State<_CustomersListBody> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    if (_searchController.text.trim().isNotEmpty) return;
    if (_isBottom) {
      context.read<CustomerReportsCubit>().fetchMoreCustomers(widget.uid);
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
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 900 : double.infinity,
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: TextField(
                  controller: _searchController,
                  style: TextStyles.customStyle(
                    color: AppColors.black,
                    fontSize: 16,
                  ),
                  cursorColor: AppColors.primaryColor,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchByNameOrPhone.tr(),
                    hintStyle: TextStyles.customStyle(
                      color: AppColors.blackLight,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.primaryColor,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<CustomerReportsCubit>()
                                  .searchCustomers('', immediate: true);
                              if (mounted) setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primaryColor,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    context.read<CustomerReportsCubit>().searchCustomers(value);
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
            BlocBuilder<CustomerReportsCubit, CustomerReportsState>(
              builder: (context, state) {
                if (state is CustomerReportsLoading) {
                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: isDesktop
                        ? SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 195,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const CustomerCardSkeleton(),
                              childCount: 8,
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const CustomerCardSkeleton(),
                              childCount: 6,
                            ),
                          ),
                  );
                }

                if (state is CustomerReportsError) {
                  AppLogger.printMessage(state.message);
                  return SliverFillRemaining(
                    child: Center(child: Text(state.message)),
                  );
                }

                if (state is CustomerReportsLoaded) {
                  final customers = state.filteredCustomers;

                  if (customers.isEmpty && !state.isFetchingMore) {
                    final isSearching = _searchController.text
                        .trim()
                        .isNotEmpty;
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSearching
                                  ? Icons.search_off_rounded
                                  : Icons.people_outline_rounded,
                              size: 64,
                              color: AppColors.blackLight.withAlpha(100),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isSearching
                                  ? AppStrings.noResults.tr()
                                  : AppStrings.noData.tr(),
                              style: TextStyles.customStyle(
                                color: AppColors.blackLight,
                                fontSize: 16,
                              ),
                            ),
                            if (!isSearching) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dialogCtx) => BlocProvider.value(
                                      value: context
                                          .read<CustomerReportsCubit>(),
                                      child: AddCustomerDialog(uid: widget.uid),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  AppStrings.addCustomer.tr(),
                                  style: TextStyles.customStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  final bool showLoadingFooter =
                      state.isFetchingMore &&
                      _searchController.text.trim().isEmpty;

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: isDesktop
                        ? SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 195,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= customers.length) {
                                  if (showLoadingFooter) {
                                    return const CustomerCardSkeleton();
                                  }
                                  return const SizedBox.shrink();
                                }
                                final customer = customers[index];
                                return CustomerListCard(
                                  customer: customer,
                                  uid: widget.uid,
                                );
                              },
                              childCount:
                                  customers.length +
                                  (showLoadingFooter ? 1 : 0),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= customers.length) {
                                  if (showLoadingFooter) {
                                    return const CustomerCardSkeleton();
                                  }
                                  return const SizedBox.shrink();
                                }
                                final customer = customers[index];
                                return CustomerListCard(
                                  customer: customer,
                                  uid: widget.uid,
                                );
                              },
                              childCount:
                                  customers.length +
                                  (showLoadingFooter ? 1 : 0),
                            ),
                          ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}

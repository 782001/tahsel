import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_list_card.dart';

import '../../../../core/services/injection_container.dart';
import '../cubit/customer_reports/customer_reports_cubit.dart';
import '../cubit/customer_reports/customer_reports_state.dart';

class CustomersListScreen extends StatelessWidget {
  final String uid;

  const CustomersListScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CustomerReportsCubit>()..fetchCustomers(uid),
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          centerTitle: true,
          scrolledUnderElevation: 0,
          title: Text(
            AppStrings.customers.tr(),
            style: TextStyles.customStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _CustomersListBody(uid: uid),
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
          maxWidth: isDesktop ? 800 : double.infinity,
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.scafoldBackGround,

              leading: const SizedBox.shrink(),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                    .searchCustomers('');
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
                      context.read<CustomerReportsCubit>().searchCustomers(
                        value,
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
            ),
            BlocBuilder<CustomerReportsCubit, CustomerReportsState>(
              builder: (context, state) {
                if (state is CustomerReportsLoading) {
                  return SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  );
                }

                if (state is CustomerReportsError) {
                  return SliverFillRemaining(
                    child: Center(child: Text(state.message)),
                  );
                }

                if (state is CustomerReportsLoaded) {
                  final customers = state.filteredCustomers;

                  if (customers.isEmpty && !state.isFetchingMore) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.blackLight.withAlpha(100),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.noData.tr(),
                              style: TextStyles.customStyle(
                                color: AppColors.blackLight,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: isDesktop
                        ? SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 105,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= customers.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                final customer = customers[index];
                                return CustomerListCard(
                                  customer: customer,
                                  uid: widget.uid,
                                );
                              },
                              childCount:
                                  customers.length +
                                  (state.isFetchingMore ? 1 : 0),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= customers.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                final customer = customers[index];
                                return CustomerListCard(
                                  customer: customer,
                                  uid: widget.uid,
                                );
                              },
                              childCount:
                                  customers.length +
                                  (state.isFetchingMore ? 1 : 0),
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

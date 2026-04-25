import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

import '../../../../core/services/injection_container.dart';
import '../../../../routes/app_routes.dart';
import '../cubit/customer_reports/customer_reports_cubit.dart';
import '../cubit/customer_reports/customer_reports_state.dart';

class CustomersListScreen extends StatelessWidget {
  final String uid;

  const CustomersListScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CustomerReportsCubit>()..fetchCustomers(uid),
      child: Scaffold(body: _CustomersListBody(uid: uid)),
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: AppColors.scafoldBackGround,
          title: Text(
            AppStrings.customers.tr(),
            style: TextStyles.customStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                style: TextStyles.customStyle(
                  color: AppColors.black,
                  fontSize: 16.sp,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.searchCustomer.tr(),
                  hintStyle: TextStyles.customStyle(
                    color: AppColors.blackLight,
                    fontSize: 14.sp,
                  ),
                  prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
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
                  context.read<CustomerReportsCubit>().searchCustomers(value);
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

              if (customers.isEmpty) {
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
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final customer = customers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: AppColors.blackLight.withAlpha(20),
                          width: 1,
                        ),
                      ),
                      color: AppColors.debtCardSurface,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.customerReportDetails,
                            arguments: {
                              'uid': widget.uid,
                              'customerName': customer.name,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyles.customStyle(
                                        color: AppColors.black,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor
                                                .withAlpha(15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.receipt_long_outlined,
                                                size: 14,
                                                color: AppColors.primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${customer.totalTransactions} ${AppStrings.operations.tr()}',
                                                style: TextStyles.customStyle(
                                                  color: AppColors.primaryColor,
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (customer.phoneNumber != null &&
                                            customer
                                                .phoneNumber!
                                                .isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.phone_outlined,
                                            size: 14,
                                            color: AppColors.blackLight,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              customer.phoneNumber!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyles.customStyle(
                                                color: AppColors.blackLight,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppColors.blackLight.withAlpha(100),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: customers.length),
                ),
              );
            }

            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
      ],
    );
  }
}

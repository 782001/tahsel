import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_operation_tile.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_summary_card.dart';

import '../../../../core/services/injection_container.dart';
import '../cubit/customer_details/customer_details_cubit.dart';
import '../cubit/customer_details/customer_details_state.dart';

class CustomerReportDetailsScreen extends StatelessWidget {
  final String uid;
  final String customerName;

  const CustomerReportDetailsScreen({
    super.key,
    required this.uid,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CustomerDetailsCubit>()..fetchOperations(uid, customerName),
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          backgroundColor: AppColors.scafoldBackGround,
          elevation: 0,
          title: Text(
            customerName,
            style: TextStyles.customStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _CustomerDetailsBody(uid: uid, customerName: customerName),
      ),
    );
  }
}

class _CustomerDetailsBody extends StatefulWidget {
  final String uid;
  final String customerName;

  const _CustomerDetailsBody({required this.uid, required this.customerName});

  @override
  State<_CustomerDetailsBody> createState() => _CustomerDetailsBodyState();
}

class _CustomerDetailsBodyState extends State<_CustomerDetailsBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CustomerDetailsCubit>().fetchMoreOperations(
        widget.uid,
        widget.customerName,
      );
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
    return BlocBuilder<CustomerDetailsCubit, CustomerDetailsState>(
      builder: (context, state) {
        if (state is CustomerDetailsLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        if (state is CustomerDetailsError) {
          return Center(child: Text(state.message));
        }

        if (state is CustomerDetailsLoaded) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : double.infinity,
              ),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomerSummaryCard(
                        totalSpent: state.totalSpent,
                        totalPaid: state.totalPaid,
                        remaining: state.remaining,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: isDesktop
                        ? SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 85,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= state.operations.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                final op = state.operations[index];
                                return CustomerOperationTile(operation: op);
                              },
                              childCount:
                                  state.operations.length +
                                  (state.isFetchingMore ? 1 : 0),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= state.operations.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                final op = state.operations[index];
                                return CustomerOperationTile(operation: op);
                              },
                              childCount:
                                  state.operations.length +
                                  (state.isFetchingMore ? 1 : 0),
                            ),
                          ),
                  ),
                  if (state.operations.isEmpty && !state.isFetchingMore)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          AppStrings.noData.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.blackLight,
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

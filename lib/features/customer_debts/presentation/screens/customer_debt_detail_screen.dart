import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/presentation/widgets/notification_dialog.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/add_debt_dialog.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/debt_item_card.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/header_banner.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/notification_preference_toggle.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/partial_payment_dialog.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/skeletons/customer_debt_skeleton.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/summary_row.dart';
import 'package:tahsel/features/debt/domain/entities/debt_entity.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_state.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class CustomerDebtDetailScreen extends StatefulWidget {
  final CustomerDebtDetail detail;
  final bool isShop;

  const CustomerDebtDetailScreen({
    super.key,
    required this.detail,
    required this.isShop,
  });

  @override
  State<CustomerDebtDetailScreen> createState() =>
      _CustomerDebtDetailScreenState();
}

class _CustomerDebtDetailScreenState extends State<CustomerDebtDetailScreen> {
  late CustomerDebtDetail currentDetail;
  bool _isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    currentDetail = widget.detail;
    _fetchDebts('initial');
  }

  Future<void> _fetchDebts([dynamic result]) async {
    // If no changes were made (result is explicitly false), do nothing
    if (result == false) return;

    // If the result is a DebtEntity, we can update locally without refetching
    if (result is DebtEntity) {
      _updateLocalItem(result);
      return;
    }

    // Determine if this is the first load (from initState) or a refresh
    final bool isInitial = result == 'initial';
    final bool forceRefresh = !isInitial;

    final debts = await context.read<DebtCubit>().fetchCustomerDebts(
      widget.detail.customerName,
      forceRefresh: forceRefresh,
    );
    if (mounted) {
      if (!isInitial) {
        _hasChanged = true;
      }
      final processedDetail = await compute(_processDebtsOnIsolate, {
        'name': widget.detail.customerName,
        'entities': debts,
      });
      setState(() {
        currentDetail = processedDetail;
        _isLoading = false;
      });
    }
  }

  void _updateLocalItem(DebtEntity updatedDebt) {
    final List<DebtEntity> updatedEntities = currentDetail.items.map((item) {
      return item.entity.id == updatedDebt.id ? updatedDebt : item.entity;
    }).toList();

    setState(() {
      currentDetail = CustomerDebtDetail.fromEntities(
        currentDetail.customerName,
        updatedEntities,
      );
      _hasChanged = true; // Propagate change to previous screen (customer list)
    });
  }

  void _onPayPartial(
    BuildContext context,
    String customerName,
    double totalDebt,
  ) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    final cubit = context.read<DebtCubit>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: PartialPaymentDialog(
          customerName: customerName,
          totalRemaining: totalDebt,
        ),
      ),
    ).then((_) => _fetchDebts());
  }

  void _onPayFull(BuildContext context, String customerName, double totalDebt) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context
          .read<DebtCubit>()
          .markAsPaid(
            uid: uid,
            customerName: customerName,
            totalAmount: totalDebt,
            note: AppStrings.fullSettlement.tr(),
          )
          .then((_) => _fetchDebts());
    }
  }

  void _onAddNewDebt(BuildContext context, String customerName) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    final cubit = context.read<DebtCubit>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AddDebtDialog(
          customerName: customerName,
          isShop: widget.isShop,
          ledgerNumber: currentDetail.ledgerNumber,
        ),
      ),
    ).then((_) => _fetchDebts());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocListener<DebtCubit, DebtState>(
      listener: (context, state) {
        if (state is DebtPaymentSuccess || state is DebtAddSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 500),
              content: Text(
                state is DebtPaymentSuccess
                    ? AppStrings.paymentSuccess.tr()
                    : AppStrings.addDebtSuccess.tr(),
              ),
            ),
          );

          if (state is DebtPaymentSuccess) {
            NotificationDialog.show(
              context: context,
              customerName: state.customerName,
              amountPaid: state.amountPaid,
              remainingBalance: state.remainingBalance,
              note: state.note,
              totalDebt: state.totalAmount,
             
            );
          }
          // Refresh data after success
          _fetchDebts();
        } else if (state is DebtFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 500),
              content: Text(state.message),
              backgroundColor: AppColors.redColor,
            ),
          );
        }
      },
      child: _isLoading
          ? Scaffold(
              backgroundColor: AppColors.scafoldBackGround,

              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Collapsible App Bar ─────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 180.h,
                    pinned: true,
                    backgroundColor: AppColors.primaryColor,
                    centerTitle: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24.r),
                      ),
                    ),
                    title: Text(
                      currentDetail.customerName,
                      style: TextStyles.customStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, _hasChanged),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: HeaderBanner(detail: currentDetail),
                    ),
                    // bottom: PreferredSize(
                    //   preferredSize: const Size.fromHeight(0),
                    //   child: Container(
                    //     height: 20.h,
                    //     decoration: BoxDecoration(
                    //       color: AppColors.scafoldBackGround,
                    //       borderRadius: BorderRadius.vertical(
                    //         top: Radius.circular(24.r),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ),
                  if (isDesktop)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisExtent: 330,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: 10,
                              itemBuilder: (context, index) {
                                return const CustomerDebtCardSkeleton();
                              },
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const CustomerDebtCardSkeleton(),
                        childCount: 5,
                      ),
                    ),
                ],
              ),
            )
          : _buildScaffold(context, currentDetail),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    CustomerDebtDetail currentDetail,
  ) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectivityState) {
        if (connectivityState is ConnectivityDisconnected) {
          return Scaffold(
            backgroundColor: AppColors.scafoldBackGround,
            appBar: AppBar(
              backgroundColor: AppColors.primaryColor,
              elevation: 0,
              centerTitle: true,
              title: Text(
                currentDetail.customerName,
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, _hasChanged),
              ),
            ),
            body: NoInternetView(
              onRetry: () {
                context.read<ConnectivityCubit>().checkConnectivity();
              },
            ),
          );
        }
        final isDesktop = ResponsiveLayout.isDesktop(context);

        return Scaffold(
          backgroundColor: AppColors.scafoldBackGround,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'add_debt',
            onPressed: () => _onAddNewDebt(context, currentDetail.customerName),
            backgroundColor: AppColors.primaryColor,
            label: Text(
              AppStrings.addNewDebt.tr(),
              style: TextStyles.customStyle(
                color: AppColors.whiteColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: Icon(Icons.add, color: AppColors.whiteColor),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Collapsible App Bar ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180.h,
                pinned: true,
                backgroundColor: AppColors.primaryColor,
                centerTitle: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24.r),
                  ),
                ),
                title: Text(
                  currentDetail.customerName,
                  style: TextStyles.customStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, _hasChanged),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: HeaderBanner(detail: currentDetail),
                ),
                // bottom: PreferredSize(
                //   preferredSize: const Size.fromHeight(0),
                //   child: Container(
                //     height: 20.h,
                //     decoration: BoxDecoration(
                //       color: AppColors.scafoldBackGround,
                //       borderRadius: BorderRadius.vertical(
                //         top: Radius.circular(24.r),
                //       ),
                //     ),
                //   ),
                // ),
              ),

              // ── Summary Cards ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 800 : double.infinity,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 0),
                      child: Column(
                        children: [
                          SizedBox(height: 20.h),
                          SummaryRow(detail: currentDetail),
                          SizedBox(height: 20.h),
                          NotificationPreferenceToggle(
                            customerName: currentDetail.customerName,
                          ),
                          SizedBox(height: 20.h),
                          if (currentDetail.totalDebt != 0)
                            BlocBuilder<DebtCubit, DebtState>(
                              builder: (context, state) {
                                final isLoading = state is DebtLoading;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : () => _onPayPartial(
                                                context,
                                                currentDetail.customerName,
                                                currentDetail.totalDebt,
                                              ),
                                        icon: isLoading
                                            ? SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors
                                                          .primaryColor,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.payment_rounded,
                                                size: 18,
                                              ),
                                        label: Text(
                                          AppStrings.partialPayment.tr(),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12.h,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : () => _onPayFull(
                                                context,
                                                currentDetail.customerName,
                                                currentDetail.totalDebt,
                                              ),
                                        icon: isLoading
                                            ? SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors
                                                          .primaryColor,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.check_circle_rounded,
                                                size: 18,
                                              ),
                                        label: Text(
                                          AppStrings.fullSettlement.tr(),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppColors.primaryColor,
                                          ),
                                          foregroundColor:
                                              AppColors.primaryColor,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12.h,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20.h)),

              // ── Section header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 800 : double.infinity,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 24.w,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4.w,
                            height: 18.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            AppStrings.activityDetails.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '${currentDetail.items.length} ${AppStrings.transactionCount.tr()}',
                              style: TextStyles.customStyle(
                                color: AppColors.primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),

              // ── Debt Items List ─────────────────────────────────────────────
              if (isDesktop)
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 800
                        ? (MediaQuery.of(context).size.width - 800) / 2
                        : 32.w,
                    vertical: 8,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 270,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return DebtItemCard(
                        item: currentDetail.items[index],
                        index: index + 1,
                        onPayPartial: (item) {
                          final cubit = context.read<DebtCubit>();
                          showDialog(
                            context: context,
                            builder: (context) => BlocProvider.value(
                              value: cubit,
                              child: PartialPaymentDialog(
                                customerName: currentDetail.customerName,
                                totalRemaining: item.remainingDebt,
                                debt: item.entity,
                              ),
                            ),
                          );
                        },
                        onPayFull: (item) {
                          context.read<DebtCubit>().markItemAsPaid(
                            debt: item.entity,
                            totalRemainingBefore: currentDetail.totalDebt,
                          );
                        },
                        onRefresh: _fetchDebts,
                      );
                    }, childCount: currentDetail.items.length),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: DebtItemCard(
                        item: currentDetail.items[index],
                        index: index + 1,
                        onPayPartial: (item) {
                          final cubit = context.read<DebtCubit>();
                          showDialog(
                            context: context,
                            builder: (context) => BlocProvider.value(
                              value: cubit,
                              child: PartialPaymentDialog(
                                customerName: currentDetail.customerName,
                                totalRemaining: item.remainingDebt,
                                debt: item.entity,
                              ),
                            ),
                          );
                        },
                        onPayFull: (item) {
                          context.read<DebtCubit>().markItemAsPaid(
                            debt: item.entity,
                            totalRemainingBefore: currentDetail.totalDebt,
                          );
                        },
                        onRefresh: _fetchDebts,
                      ),
                    );
                  }, childCount: currentDetail.items.length),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 120.h)),
            ],
          ),
        );
      },
    );
  }
}

/// Isolate entry point for processing debts
CustomerDebtDetail _processDebtsOnIsolate(Map<String, dynamic> data) {
  final name = data['name'] as String;
  final entities = data['entities'] as List<DebtEntity>;
  return CustomerDebtDetail.fromEntities(name, entities);
}

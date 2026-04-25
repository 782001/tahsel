import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_state.dart';
import 'package:tahsel/features/customer/presentation/widgets/notification_dialog.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/add_debt_dialog.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/debt_item_card.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/header_banner.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/partial_payment_dialog.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/summary_row.dart';
import 'package:tahsel/features/debt/domain/entities/debt_entity.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_state.dart';

class CustomerDebtDetailScreen extends StatelessWidget {
  final CustomerDebtDetail detail;
  final bool isShop;

  const CustomerDebtDetailScreen({
    super.key,
    required this.detail,
    required this.isShop,
  });

  void _onPayPartial(
    BuildContext context,
    String customerName,
    double totalDebt,
  ) {
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
    );
  }

  void _onPayFull(BuildContext context, String customerName, double totalDebt) {
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid != null) {
      context.read<DebtCubit>().markAsPaid(
        uid: uid,
        customerName: customerName,
        totalAmount: totalDebt,
        note: AppStrings.fullSettlement.tr(),
      );
    }
  }

  void _onAddNewDebt(BuildContext context, String customerName) {
    final cubit = context.read<DebtCubit>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AddDebtDialog(
          customerName: customerName,
          isShop: isShop,
          ledgerNumber: detail.ledgerNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            );
          }
        } else if (state is DebtFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(milliseconds: 500),
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<DebtCubit, DebtState>(
        builder: (context, state) {
          CustomerDebtDetail currentDetail = detail;

          if (state is DebtsFetchSuccess) {
            // Using a simple where for now, but compute could be used for large lists
            final customerDebts = state.debts
                .where((d) => d.customerName == detail.customerName)
                .toList();

            return FutureBuilder<CustomerDebtDetail>(
              future: compute(_processDebtsOnIsolate, {
                'name': detail.customerName,
                'entities': customerDebts,
              }),
              builder: (context, snapshot) {
                final currentDetail = snapshot.data ?? detail;
                return _buildScaffold(context, currentDetail);
              },
            );
          }

          return _buildScaffold(context, detail);
        },
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    CustomerDebtDetail currentDetail,
  ) {
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
            fontSize: 16.sp,
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
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 0),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  SummaryRow(detail: currentDetail),
                  SizedBox(height: 20.h),
                  _NotificationPreferenceToggle(
                    customerName: currentDetail.customerName,
                  ),
                  SizedBox(height: 20.h),
                  if (currentDetail.totalDebt != 0)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _onPayPartial(
                              context,
                              currentDetail.customerName,
                              currentDetail.totalDebt,
                            ),
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: Text(AppStrings.partialPayment.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _onPayFull(
                              context,
                              currentDetail.customerName,
                              currentDetail.totalDebt,
                            ),
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                            ),
                            label: Text(AppStrings.fullSettlement.tr()),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primaryColor),
                              foregroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // ── Section header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                      fontSize: 16.sp,
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
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${currentDetail.items.length} ${AppStrings.transactionCount.tr()}',
                      style: TextStyles.customStyle(
                        color: AppColors.primaryColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 12.h)),

          // ── Debt Items List ─────────────────────────────────────────────
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
                ),
              );
            }, childCount: currentDetail.items.length),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
  }
}

class _NotificationPreferenceToggle extends StatelessWidget {
  final String customerName;

  const _NotificationPreferenceToggle({required this.customerName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        String currentPreference = 'none';
        if (state is CustomerLoaded) {
          final customer = state.customers
              .where((c) => c.name.trim() == customerName.trim())
              .firstOrNull;
          currentPreference = customer?.notificationPreference ?? 'none';
        }

        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18.sp,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    AppStrings.notificationChannel.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'none',
                      label: Text(
                        AppStrings.none.tr(),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      icon: const Icon(Icons.notifications_off_outlined),
                    ),
                    ButtonSegment(
                      value: 'whatsapp',
                      label: Text(
                        AppStrings.whatsapp.tr(),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      icon: Image.asset(
                        Assets.imagesWhatsapp,
                        width: 22.w,
                        height: 22.w,
                      ),
                    ),
                    ButtonSegment(
                      value: 'sms',
                      label: Text(
                        AppStrings.sms.tr(),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      icon: const Icon(Icons.sms_outlined),
                    ),
                  ],
                  selected: {currentPreference},
                  onSelectionChanged: (Set<String> newSelection) {
                    if (newSelection.isEmpty) return;
                    final uid = sl<FirebaseAuth>().currentUser?.uid;
                    if (uid != null) {
                      context.read<CustomerCubit>().updateCustomerPreference(
                        uid,
                        customerName,
                        newSelection.first,
                      );
                    }
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    selectedBackgroundColor: AppColors.primaryColor,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: AppColors.disabledColor,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
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

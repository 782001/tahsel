import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/debt_item_card.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/header_banner.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/partial_payment_dialog.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/summary_row.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_state.dart';

class CustomerDebtDetailScreen extends StatelessWidget {
  final CustomerDebtDetail detail;

  const CustomerDebtDetailScreen({super.key, required this.detail});

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

  void _onPayFull(BuildContext context, String customerName) {
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid != null) {
      context.read<DebtCubit>().markAsPaid(uid, customerName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DebtCubit, DebtState>(
      listener: (context, state) {
        if (state is DebtPaymentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(milliseconds: 500),
              content: Text(AppStrings.paymentSuccess.tr()),
            ),
          );
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
            final customerDebts = state.debts
                .where((d) => d.customerName == detail.customerName)
                .toList();
            currentDetail = CustomerDebtDetail.fromEntities(
              detail.customerName,
              customerDebts,
            );
          }

          return Scaffold(
            backgroundColor: AppColors.scafoldBackGround,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Collapsible App Bar ─────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 200.h,
                  pinned: true,
                  backgroundColor: AppColors.primaryColor,
                  centerTitle: true,
                  title: Text(
                    currentDetail.customerName,
                    style: TextStyles.customStyle(
                      color: AppColors.whiteColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: HeaderBanner(detail: currentDetail),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(0),
                    child: Container(
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: AppColors.scafoldBackGround,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24.r),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Summary Cards ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 0),
                    child: Column(
                      children: [
                        SummaryRow(detail: currentDetail),
                        SizedBox(height: 16.h),
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
                                  icon: const Icon(
                                    Icons.payment_rounded,
                                    size: 18,
                                  ),
                                  label: Text(AppStrings.partialPayment.tr()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
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
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                  ),
                                  label: Text(AppStrings.fullSettlement.tr()),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.primaryColor,
                                    ),
                                    foregroundColor: AppColors.primaryColor,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
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
                          context.read<DebtCubit>().markItemAsPaid(item.entity);
                        },
                      ),
                    );
                  }, childCount: currentDetail.items.length),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 120.h)),
              ],
            ),
          );
        },
      ),
    );
  }
}

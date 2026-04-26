import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_add_debt_dialog.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_details_widgets.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_item_card.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_notification_dialog.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_partial_payment_dialog.dart';
import 'package:tahsel/routes/app_routes.dart';

class MyDebtDetailsScreen extends StatelessWidget {
  final MyDebtDetail detail;

  const MyDebtDetailsScreen({super.key, required this.detail});

  void _onPayPartial(
    BuildContext context,
    MyDebtItem item,
    MyDebtDetail currentDetail,
  ) {
    final cubit = context.read<MyDebtsCubit>();
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: MyPartialPaymentDialog(
          personName: currentDetail.personName,
          totalRemaining: item.remainingDebt,
          debt: item.entity,
        ),
      ),
    );
  }

  void _onPayFull(
    BuildContext context,
    MyDebtItem item,
    MyDebtDetail currentDetail,
  ) {
    context.read<MyDebtsCubit>().markItemAsPaid(
      debt: item.entity,
      totalRemainingBefore: currentDetail.totalDebt,
    );
  }

  void _onAddNewDebt(BuildContext context, String personName) {
    final cubit = context.read<MyDebtsCubit>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: MyAddDebtDialog(personName: personName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyDebtsCubit, MyDebtsState>(
      listener: (context, state) {
        if (state.lastPaymentAmount != null && state.lastPaymentAmount! > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 500),
              content: Text(AppStrings.paymentSuccess.tr()),
            ),
          );

          MyDebtsNotificationDialog.show(
            context: context,
            personName: state.lastPaymentPerson ?? '',
            amountPaid: state.lastPaymentAmount!,
            remainingBalance: state.lastPaymentRemaining ?? 0,
            note: state.lastPaymentNote,
          );
        } else if (state.status == MyDebtsStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 500),
              content: Text(state.message ?? 'Error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<MyDebtsCubit, MyDebtsState>(
        builder: (context, state) {
          return FutureBuilder<MyDebtDetail>(
            future: compute(_processMyDebtsOnIsolate, {
              'name': detail.personName,
              'entities': state.debts
                  .where((d) => d.personName == detail.personName)
                  .toList(),
            }),
            builder: (context, snapshot) {
              final currentDetail = snapshot.data ?? detail;
              return _buildScaffold(context, currentDetail, state);
            },
          );
        },
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    MyDebtDetail currentDetail,
    MyDebtsState state,
  ) {
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_my_debt_detail',
        onPressed: () => _onAddNewDebt(context, currentDetail.personName),
        backgroundColor: AppColors.primaryColor,
        label: Text(
          AppStrings.addMyDebt.tr(),
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
              currentDetail.personName,
              style: TextStyles.customStyle(
                color: Colors.white,
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
              background: MyDebtHeaderBanner(detail: currentDetail),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
              child: Column(
                children: [
                  MyDebtSummaryRow(detail: currentDetail),
                  SizedBox(height: 20.h),
                  _MyNotificationPreferenceToggle(
                    personName: currentDetail.personName,
                  ),
                  SizedBox(height: 20.h),
                  if (currentDetail.totalDebt != 0)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Global partial payment
                              final cubit = context.read<MyDebtsCubit>();
                              showDialog(
                                context: context,
                                builder: (context) => BlocProvider.value(
                                  value: cubit,
                                  child: MyPartialPaymentDialog(
                                    personName: currentDetail.personName,
                                    totalRemaining: currentDetail.totalDebt,
                                  ),
                                ),
                              );
                            },
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
                          child: OutlinedButton(
                            onPressed: (state.status == MyDebtsStatus.markingAsPaid &&
                                        state.processingId == currentDetail.personName)
                                ? null
                                : () {
                                    context.read<MyDebtsCubit>().markAsPaid(
                                      personName: currentDetail.personName,
                                      totalAmount: currentDetail.totalDebt,
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primaryColor),
                              foregroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (state.status == MyDebtsStatus.markingAsPaid &&
                                    state.processingId == currentDetail.personName) ...[
                                  SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ] else
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                  ),
                                const SizedBox(width: 8),
                                Text(AppStrings.fullSettlement.tr()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
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
                      color: AppColors.textColor,
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
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = currentDetail.items[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: MyDebtItemCard(
                  item: item,
                  index: index + 1,
                  onPayPartial: (i) => _onPayPartial(context, i, currentDetail),
                  onPayFull: (i) => _onPayFull(context, i, currentDetail),
                  isFullPaying: state.status == MyDebtsStatus.markingAsPaid &&
                      (state.processingId == item.entity.id ||
                          state.processingId == currentDetail.personName),
                  onTap: () {
                    // Navigate to transaction history for this specific debt entry
                    sl<NavigatorService>().pushNamedWithArgs(
                      routeName: AppRoutes.myDebtDetailsReport,
                      arguments: item.entity,
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

MyDebtDetail _processMyDebtsOnIsolate(Map<String, dynamic> data) {
  final name = data['name'] as String;
  final entities = data['entities'] as List<MyDebtEntity>;
  return MyDebtDetail.fromEntities(name, entities);
}

class _MyNotificationPreferenceToggle extends StatelessWidget {
  final String personName;

  const _MyNotificationPreferenceToggle({required this.personName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDebtsCubit, MyDebtsState>(
      builder: (context, state) {
        // Read preference from debts regardless of loading status
        // so the selection persists during reload cycles
        final debt = state.debts
            .where((d) => d.personName.trim() == personName.trim())
            .firstOrNull;
        final currentPreference = debt?.notificationPreference ?? 'none';

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
                    context.read<MyDebtsCubit>().updateNotificationPreference(
                      personName,
                      newSelection.first,
                    );
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

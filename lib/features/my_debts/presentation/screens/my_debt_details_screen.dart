import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_state.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_state.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_add_debt_dialog.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_details_widgets.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_item_card.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_notification_dialog.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_partial_payment_dialog.dart';
import 'package:tahsel/shared/widgets/shimmer/transaction_skeleton.dart';

class MyDebtDetailsScreen extends StatefulWidget {
  final MyDebtPersonEntity person;

  const MyDebtDetailsScreen({super.key, required this.person});

  @override
  State<MyDebtDetailsScreen> createState() => _MyDebtDetailsScreenState();
}

class _MyDebtDetailsScreenState extends State<MyDebtDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<MyDebtDetailsCubit>().loadDetails(uid, widget.person.name);
    }
  }

  void _onPayPartial(BuildContext context, double totalRemaining) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<MyDebtDetailsCubit>(),
        child: MyPartialPaymentDialog(
          personName: widget.person.name,
          totalRemaining: totalRemaining,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _onPayFull(BuildContext context, double totalRemaining) {
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<MyDebtDetailsCubit>().payDebt(
        uid: uid,
        personName: widget.person.name,
        amount: totalRemaining,
        note: AppStrings.fullSettlement.tr(),
      );
    }
  }

  void _onPayItemPartial(BuildContext context, MyDebtItemEntity item) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<MyDebtDetailsCubit>(),
        child: MyPartialPaymentDialog(
          personName: widget.person.name,
          totalRemaining: item.remainingAmount,
          debtId: item.id,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _onPayItemFull(BuildContext context, MyDebtItemEntity item) {
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty && item.id != null) {
      context.read<MyDebtDetailsCubit>().payItem(
        uid: uid,
        debtId: item.id!,
        amount: item.remainingAmount,
        personName: widget.person.name,
        note: AppStrings.fullSettlement.tr(),
      );
    }
  }

  void _onAddNewDebt(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<MyDebtDetailsCubit>(),
        child: MyAddDebtDialog(personName: widget.person.name),
      ),
    ).then((_) => _loadData());
  }

  void _onDeleteItem(BuildContext context, MyDebtItemEntity item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.confirmDeletion.tr()),
        content: Text(AppStrings.deleteDebtItemConfirmation.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                color: AppColors.disabledColor,
                fontSize: 16.sp,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final uid = AppStrings.userToken;
              if (uid.isNotEmpty && item.id != null) {
                context.read<MyDebtDetailsCubit>().deleteItem(
                  uid,
                  item.id!,
                  widget.person.name,
                );
              }
            },
            child: Text(
              AppStrings.delete.tr(),
              style: TextStyles.customStyle(
                color: AppColors.error,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyDebtDetailsCubit, MyDebtDetailsState>(
      listener: (context, state) {
        if (state.status == MyDebtDetailsStatus.loaded &&
            state.lastPaymentAmount != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text(AppStrings.paymentSuccess.tr()),
            ),
          );

          MyDebtsNotificationDialog.show(
            context: context,
            personName: widget.person.name,
            amountPaid: state.lastPaymentAmount!,
            remainingBalance: state.lastPaymentRemaining ?? 0,
            note: state.lastPaymentNote,
          );

          context.read<MyDebtsCubit>().loadPersons(
            AppStrings.userToken,
          );
          context.read<MyDebtDetailsCubit>().clearFlags();
        } else if (state.status == MyDebtDetailsStatus.error &&
            state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text(state.message!.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<MyDebtDetailsCubit, MyDebtDetailsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.scafoldBackGround,
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'add_my_debt_detail',
              onPressed: () => _onAddNewDebt(context),
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
                    widget.person.name,
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
                    background: MyDebtHeaderBanner(
                      personName: widget.person.name,
                      totalAmount: state.totalOwed,
                      remainingAmount: state.remainingAmount,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
                    child: Column(
                      children: [
                        MyDebtSummaryRow(
                          totalOwed: state.totalOwed,
                          remainingAmount: state.remainingAmount,
                        ),
                        SizedBox(height: 20.h),
                        _MyNotificationPreferenceToggle(person: widget.person),
                        SizedBox(height: 20.h),
                        if (state.remainingAmount > 0)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (state.items.isEmpty || state.items.any((i) => i.isPending))
                                      ? null
                                      : () => _onPayPartial(
                                            context,
                                            state.remainingAmount,
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
                                  onPressed: (state.items.isEmpty || state.items.any((i) => i.isPending))
                                      ? null
                                      : () => _onPayFull(
                                            context,
                                            state.remainingAmount,
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
                            '${state.items.length} ${AppStrings.transactionCount.tr()}',
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
                if (state.status == MyDebtDetailsStatus.loading &&
                    state.items.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const TransactionCardSkeleton(),
                        childCount: 3,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = state.items[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: MyDebtItemCard(
                          item: item,
                          index: index + 1,
                          onPayPartial: (i) => _onPayItemPartial(context, i),
                          onPayFull: (i) => _onPayItemFull(context, i),
                          onDelete: (i) => _onDeleteItem(context, i),
                        ),
                      );
                    }, childCount: state.items.length),
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

class _MyNotificationPreferenceToggle extends StatelessWidget {
  final MyDebtPersonEntity person;

  const _MyNotificationPreferenceToggle({required this.person});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDebtsCubit, MyDebtsState>(
      builder: (context, state) {
        // Find the person in the state to ensure we have the latest data (e.g. preference)
        final personInState = state.status == MyDebtsStatus.loaded
            ? state.persons.where((p) => p.name == person.name).firstOrNull ??
                  person
            : person;

        final currentPreference = personInState.notificationPreference;

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
                    final uid = AppStrings.userToken;
                    if (uid.isNotEmpty) {
                      context.read<MyDebtsCubit>().updatePreference(
                        uid,
                        person.name,
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

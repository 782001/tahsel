import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/utils/vault_balance_helper.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_state.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_summary_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_add_debt_dialog.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_details_widgets.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_item_card.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_notification_dialog.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_notification_preference_toggle.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_partial_payment_dialog.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';
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

  @override
  void dispose() {
    AppLogger.printMessage("MyDebtDetailsScreen disposed");
    // debugPrintStack(label: 'Dispose Stack');

    super.dispose();
  }

  void _loadData() {
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<MyDebtDetailsCubit>().loadDetails(uid, widget.person.name);
    }
  }

  void _onPayPartial(BuildContext context, double totalRemaining) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final cubit = context.read<MyDebtDetailsCubit>();
        return BlocProvider.value(
          value: cubit,
          child: MyPartialPaymentDialog(
            personName: widget.person.name,
            totalRemaining: totalRemaining,
            firstDate: cubit.state.firstDate,
          ),
        );
      },
    ).then((_) => _loadData());
  }

  void _onPayFull(BuildContext context, double totalRemaining) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
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
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final cubit = context.read<MyDebtDetailsCubit>();

        return BlocProvider.value(
          value: cubit,
          child: MyPartialPaymentDialog(
            personName: widget.person.name,
            totalRemaining: item.remainingAmount,
            debtId: item.id,
            firstDate: item.timestamp,
          ),
        );
      },
    ).then((_) => _loadData());
  }

  void _onPayItemFull(BuildContext context, MyDebtItemEntity item) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
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
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<MyDebtDetailsCubit>(),
        child: MyAddDebtDialog(personName: widget.person.name),
      ),
    ).then((_) {
      if (context.mounted) {
        _loadData();
        final uid = AppStrings.userToken;
        if (uid.isNotEmpty) {
          context.read<MyDebtsCubit>().loadPersons(uid);
          sl<MyDebtsSummaryCubit>().refreshSummary(uid);
        }
      }
    });
  }

  void _onDeleteItem(BuildContext context, MyDebtItemEntity item) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),

          child: AlertDialog(
            title: Text(AppStrings.confirmDeletion.tr()),
            content: Text(AppStrings.deleteDebtItemConfirmation.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppStrings.cancel.tr(),
                  style: TextStyles.customStyle(
                    color: AppColors.disabledColor,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  final uid = AppStrings.userToken;
                  if (uid.isNotEmpty && item.id != null) {
                    context
                        .read<MyDebtDetailsCubit>()
                        .deleteItem(uid, item.id!, widget.person.name)
                        .then((_) {
                          if (context.mounted) {
                            context.read<MyDebtsCubit>().loadPersons(uid);
                            sl<MyDebtsSummaryCubit>().refreshSummary(uid);
                          }
                        });
                  }
                },
                child: Text(
                  AppStrings.delete.tr(),
                  style: TextStyles.customStyle(
                    color: AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyDebtDetailsCubit, MyDebtDetailsState>(
      listener: (context, state) {
        if (state.status == MyDebtDetailsStatus.loaded &&
            context.read<MyDebtDetailsCubit>().lastPaymentAmount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text(AppStrings.paymentSuccess.tr()),
            ),
          );

          MyDebtsNotificationDialog.show(
            context: context,
            personName: widget.person.name,
            amountPaid: context.read<MyDebtDetailsCubit>().lastPaymentAmount,
            remainingBalance: context
                .read<MyDebtDetailsCubit>()
                .lastPaymentRemaining,
            totalDebt: widget.person.totalDebtAmount,
            note: context.read<MyDebtDetailsCubit>().lastPaymentNote,
          );
          setState(() {
            context.read<MyDebtDetailsCubit>().lastPaymentAmount = 0;
            context.read<MyDebtDetailsCubit>().lastPaymentRemaining = 0;
            context.read<MyDebtDetailsCubit>().lastPaymentNote = "";
          });
          context.read<MyDebtsCubit>().loadPersons(AppStrings.userToken);
          sl<MyDebtsSummaryCubit>().refreshSummary(AppStrings.userToken);
          context.read<MyDebtDetailsCubit>().clearFlags();
        } else if (state.status == MyDebtDetailsStatus.error &&
            state.message != null) {
          if (state.message!.contains(AppStrings.insufficientBalance) ||
              state.message!.contains('insufficient_balance')) {
            VaultBalanceHelper.showInsufficientBalanceDialog(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1500),
                content: Text(state.message!.tr()),
                backgroundColor: AppColors.error,
              ),
            );
          }
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: Icon(Icons.add, color: AppColors.whiteColor),
            ),
            appBar:
                context.read<ConnectivityCubit>().state
                    is ConnectivityDisconnected
                ? AppBar(
                    title: Text(
                      widget.person.name,
                      style: TextStyles.customStyle(
                        color: AppColors.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    centerTitle: true,
                    elevation: 0,
                    backgroundColor: AppColors.transparent,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textColor,
                        size: 20.r,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                : null,

            body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
              builder: (context, connectivityState) {
                final isDesktop = ResponsiveLayout.isDesktop(context);

                if (connectivityState is ConnectivityDisconnected) {
                  return NoInternetView(
                    onRetry: () =>
                        context.read<ConnectivityCubit>().checkConnectivity(),
                  );
                }
                return CustomScrollView(
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
                          fontSize: 18,
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
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 800 : double.infinity,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
                            child: Column(
                              children: [
                                MyDebtSummaryRow(
                                  totalOwed: state.totalOwed,
                                  remainingAmount: state.remainingAmount,
                                ),
                                SizedBox(height: 20.h),
                                MyNotificationPreferenceToggle(
                                  person: widget.person,
                                ),
                                SizedBox(height: 20.h),
                                if (state.remainingAmount > 0)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              (state.items.isEmpty ||
                                                  state.items.any(
                                                    (i) => i.isPending,
                                                  ) ||
                                                  state.status ==
                                                      MyDebtDetailsStatus
                                                          .loading)
                                              ? null
                                              : () => _onPayPartial(
                                                  context,
                                                  state.remainingAmount,
                                                ),
                                          icon:
                                              state.status ==
                                                  MyDebtDetailsStatus.loading
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
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              (state.items.isEmpty ||
                                                  state.items.any(
                                                    (i) => i.isPending,
                                                  ) ||
                                                  state.status ==
                                                      MyDebtDetailsStatus
                                                          .loading)
                                              ? null
                                              : () => _onPayFull(
                                                  context,
                                                  state.remainingAmount,
                                                ),
                                          icon:
                                              state.status ==
                                                  MyDebtDetailsStatus.loading
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
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
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
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 800 : double.infinity,
                          ),
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
                                    '${state.items.length} ${AppStrings.transactionCount.tr()}',
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
                    SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                    if (state.status == MyDebtDetailsStatus.loading &&
                        state.items.isEmpty)
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
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  const TransactionCardSkeleton(),
                              childCount: 4,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  const TransactionCardSkeleton(),
                              childCount: 3,
                            ),
                          ),
                        )
                    else if (isDesktop)
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
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = state.items[index];
                            return MyDebtItemCard(
                              item: item,
                              index: index + 1,
                              onPayPartial: (i) =>
                                  _onPayItemPartial(context, i),
                              onPayFull: (i) => _onPayItemFull(context, i),
                              onDelete: (i) => _onDeleteItem(context, i),
                              onRefresh: _loadData,
                              isFullPaying:
                                  state.status == MyDebtDetailsStatus.loading,
                            );
                          }, childCount: state.items.length),
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
                              onPayPartial: (i) =>
                                  _onPayItemPartial(context, i),
                              onPayFull: (i) => _onPayItemFull(context, i),
                              onDelete: (i) => _onDeleteItem(context, i),
                              onRefresh: _loadData,
                              isFullPaying:
                                  state.status == MyDebtDetailsStatus.loading,
                            ),
                          );
                        }, childCount: state.items.length),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

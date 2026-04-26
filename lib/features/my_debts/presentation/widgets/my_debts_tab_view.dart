import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_card.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debts_summary_card.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/skeletons/my_debt_skeleton.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_search_field.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class MyDebtsTabView extends StatefulWidget {
  const MyDebtsTabView({super.key});

  @override
  State<MyDebtsTabView> createState() => _MyDebtsTabViewState();
}

class _MyDebtsTabViewState extends State<MyDebtsTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  @override
  void initState() {
    super.initState();
    // Load debts when tab is initialized (will skip loading state if already cached in Cubit)
    Future.microtask(() {
      if (mounted) {
        context.read<MyDebtsCubit>().loadMyDebts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton.extended(
          heroTag: 'add_my_debt_fab',
          backgroundColor: AppColors.primaryColor,
          onPressed: () {
            sl<NavigatorService>().pushNamed(AppRoutes.addMyDebt).then((_) {
              if (context.mounted) {
                // Background refresh after adding
                context.read<MyDebtsCubit>().loadMyDebts();
              }
            });
          },
          label: Text(
            AppStrings.addNewDebt.tr(),
            style: TextStyles.customStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          icon: Icon(Icons.add, color: AppColors.white),
        ),
      ),
      body: BlocListener<MyDebtsCubit, MyDebtsState>(
        listener: (context, state) {
          if (state.status == MyDebtsStatus.loaded &&
              state.message == 'delete_success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 500),
                content: Text(AppStrings.deleteMyDebtSuccess.tr()),
              ),
            );
          }
          if (state.status == MyDebtsStatus.error && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 500),
                content: Text(state.message!.tr()),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<MyDebtsCubit, MyDebtsState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () => context.read<MyDebtsCubit>().loadMyDebts(forceRefresh: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: MyDebtsSummaryCard()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomSearchField(
                        controller: _searchController,
                        hintText: AppStrings.searchByNameOrPhone.tr(),
                        onChanged: (val) {
                          context.read<MyDebtsCubit>().searchDebts(val);
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  if (state.status == MyDebtsStatus.loading &&
                      state.debts.isEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const MyDebtCardSkeleton(),
                        childCount: 5,
                      ),
                    )
                  else if (state.groupedDebts.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          AppStrings.noData.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.subTitleColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((
                          context,
                          index,
                        ) {
                          if (index == state.groupedDebts.length) {
                            return const SizedBox(height: 80);
                          }
                          final detail = state.groupedDebts[index];
                          return MyDebtCard(
                            detail: detail,
                            onLongPress: detail.totalDebt == 0
                                ? () => _onDeleteDebt(context, detail)
                                : null,
                          );
                        }, childCount: state.groupedDebts.length + 1),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _onDeleteDebt(BuildContext context, MyDebtDetail detail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                AppStrings.confirmDeleteMyDebtTitle.tr(),
                style: TextStyles.customStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppStrings.confirmDeleteMyDebtMessage.tr(),
          style: TextStyles.customStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.subTitleColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.disabledColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final debtIds = detail.items
                  .where((item) => item.remainingDebt == 0)
                  .map((item) => item.entity.id)
                  .toList();
              if (debtIds.isNotEmpty) {
                context.read<MyDebtsCubit>().deleteMultipleDebts(debtIds);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              AppStrings.delete.tr(),
              style: TextStyles.customStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

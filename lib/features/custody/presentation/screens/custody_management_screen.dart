import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/currency_helper.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/utils/vault_balance_helper.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/custody/domain/entities/custody_entity.dart';
import 'package:tahsel/features/custody/presentation/cubit/custody_cubit.dart';
import 'package:tahsel/features/custody/presentation/cubit/custody_state.dart';
import 'package:tahsel/features/custody/presentation/widgets/add_custody_expense_dialog.dart';
import 'package:tahsel/features/custody/presentation/widgets/custody_card_skeleton.dart';
import 'package:tahsel/features/custody/presentation/widgets/custody_expenses_sheet.dart';
import 'package:tahsel/features/custody/presentation/widgets/new_custody_dialog.dart';
import 'package:tahsel/features/custody/presentation/widgets/settle_custody_dialog.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/shared/widgets/custom_app_bar/custom_app_bar.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_search_field.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';

import '../utils/custody_statement_pdf_exporter.dart';

class CustodyManagementScreen extends StatefulWidget {
  const CustodyManagementScreen({super.key});

  @override
  State<CustodyManagementScreen> createState() =>
      _CustodyManagementScreenState();
}

class _CustodyManagementScreenState extends State<CustodyManagementScreen> {
  late final CustodyCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: Settled

  @override
  void initState() {
    super.initState();
    _cubit = sl<CustodyCubit>();
    _cubit.loadCustodies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  // ── Employee Role & Action Permission Checks ──
  bool get canExport => CustodyStatementPdfExporter.hasExportPermission();

  bool get canCreateCustody =>
      PermissionService.instance.isOwner ||
      PermissionService.instance.hasPermission(AppPermissions.vaultAccess) ||
      PermissionService.instance.hasPermission(AppPermissions.vaultWithdraw);

  bool get canSettleCustody =>
      PermissionService.instance.isOwner ||
      PermissionService.instance.hasPermission(AppPermissions.vaultAccess) ||
      PermissionService.instance.hasPermission(AppPermissions.vaultDeposit);

  bool get canDeleteCustody =>
      PermissionService.instance.isOwner ||
      PermissionService.instance.hasPermission(AppPermissions.expensesDelete);

  bool canEditNotes(CustodyEntity custody) =>
      PermissionService.instance.isOwner ||
      PermissionService.instance.hasPermission(AppPermissions.expensesAdd) ||
      (custody.recipientEmployeeId != null &&
          custody.recipientEmployeeId == AppStrings.employeeAuthUid);

  bool canAddExpense(CustodyEntity custody) =>
      PermissionService.instance.isOwner ||
      PermissionService.instance.hasPermission(AppPermissions.expensesAdd) ||
      (custody.recipientEmployeeId != null &&
          custody.recipientEmployeeId == AppStrings.employeeAuthUid);

  Future<void> _printCustody(CustodyEntity custody) async {
    if (!canExport) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.noPermissionForAction.tr())),
      );
      return;
    }
    final isArabic = AppStrings.currentLang == 'ar';
    try {
      await CustodyStatementPdfExporter.printCustodyStatement(
        context,
        custody: custody,
        isArabic: isArabic,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareCustody(CustodyEntity custody) async {
    if (!canExport) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.noPermissionForAction.tr())),
      );
      return;
    }
    final isArabic = AppStrings.currentLang == 'ar';
    try {
      await CustodyStatementPdfExporter.exportAndShare(
        custody: custody,
        isArabic: isArabic,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEditNotesDialog(CustodyEntity custody) {
    if (!canEditNotes(custody)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.noPermissionForAction.tr())),
      );
      return;
    }

    final controller = TextEditingController(text: custody.notes ?? '');
    final isDesktop = ResponsiveLayout.isDesktop(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16.w,
          vertical: isDesktop ? 24 : 24.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 18 : 18.r),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 22 : 18.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.primaryColor,
                      size: isDesktop ? 24 : 24.r,
                    ),
                    SizedBox(width: isDesktop ? 8 : 8.w),
                    Expanded(
                      child: Text(
                        AppStrings.editCustodyNotes.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 16 : 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.sandText,
                        size: isDesktop ? 20 : 20.r,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 14 : 14.h),
                CustomTextFormField(
                  controller: controller,
                  maxLines: 3,
                  labelText: AppStrings.custodyNotes.tr(),
                  hintText: AppStrings.custodyNotesHint.tr(),
                ),
                SizedBox(height: isDesktop ? 18 : 18.h),
                ElevatedButton(
                  onPressed: () async {
                    final notes = controller.text.trim();
                    Navigator.pop(ctx);
                    await _cubit.updateCustodyNotes(
                      custodyId: custody.id,
                      notes: notes,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 12 : 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 10 : 10.r,
                      ),
                    ),
                  ),
                  child: Text(
                    AppStrings.save.tr(),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 14 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteCustodyDialog(CustodyEntity custody) {
    if (!canDeleteCustody) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.noPermissionForAction.tr())),
      );
      return;
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (custody.spentAmount > 0 || custody.expenses.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 18 : 18.r),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.cannotDeleteCustodyTitle.tr(),
                style: TextStyles.customStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            AppStrings.cannotDeleteCustodySpentMsg.tr(),
            style: TextStyles.customStyle(
              fontSize: 13.5,
              color: AppColors.blackLight,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: Text(
                AppStrings.ok.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 18 : 18.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 8 : 8.r),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
                size: isDesktop ? 22 : 22.r,
              ),
            ),
            SizedBox(width: isDesktop ? 10 : 10.w),
            Expanded(
              child: Text(
                AppStrings.deleteCustodyConfirmTitle.tr(),
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 16 : 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${custody.recipientName} (${CurrencyHelper.formatCurrency(custody.initialAmount)})',
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 14 : 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: isDesktop ? 8 : 8.h),
            Text(
              AppStrings.deleteCustodyConfirmMsg.tr(),
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 13 : 12.5,
                color: AppColors.sandText,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 13.5 : 13,
                color: AppColors.blackLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _cubit.deleteCustody(custody.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isDesktop ? 8 : 8.r),
              ),
            ),
            child: Text(
              AppStrings.deleteCustody.tr(),
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 13.5 : 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CustodyEntity> _filterList(List<CustodyEntity> all) {
    var list = all;
    if (_selectedFilterIndex == 1) {
      list = list.where((c) => c.isActive).toList();
    } else if (_selectedFilterIndex == 2) {
      list = list.where((c) => c.isSettled).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        final matchesRecipient = c.recipientName.toLowerCase().contains(query);
        final matchesNotes = (c.notes ?? '').toLowerCase().contains(query);
        return matchesRecipient || matchesNotes;
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isPushed = !(ModalRoute.of(context)?.isFirst ?? true);
    final showBackButton = isPushed || !isDesktop;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        body: SafeArea(
          child: Column(
            children: [
              // Responsive Custom App Bar
              CustomAppBar(
                centerTitle: AppStrings.employeeCustodies.tr(),
                leadingIcon: showBackButton
                    ? Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textColor,
                        size: 20,
                      )
                    : null,
                onLeadingTap: showBackButton
                    ? () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          try {
                            context.read<MainLayoutCubit>().changeBottomNav(5);
                          } catch (_) {}
                        }
                      }
                    : null,
                actions: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 12.w,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 10 : 8.w,
                            vertical: isDesktop ? 5 : 4.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.vipGoldStart,
                                AppColors.vipGoldEnd,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 20 : 20.r,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.vipGoldStart.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 14,
                                color: Colors.black87,
                              ),
                              SizedBox(width: isDesktop ? 4 : 3.w),
                              Text(
                                'VIP',
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 11.5 : 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Content Area
              Expanded(
                child: BlocConsumer<CustodyCubit, CustodyState>(
                  bloc: _cubit,
                  listener: (context, state) {
                    if (state is CustodyActionSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.primaryColor,
                        ),
                      );
                    } else if (state is CustodyFailure) {
                      if (state.message.contains(
                            AppStrings.insufficientBalance,
                          ) ||
                          state.message.contains('insufficient_balance')) {
                        VaultBalanceHelper.showInsufficientBalanceDialog(
                          context,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    // Shimmer Skeleton Loading instead of CircularProgressIndicator
                    if (state is CustodyLoading && _cubit.custodies.isEmpty) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 960 : double.infinity,
                          ),
                          child: const CustodyListSkeleton(),
                        ),
                      );
                    }

                    final allCustodies = _cubit.custodies;
                    final activeCustodies = allCustodies
                        .where((c) => c.isActive)
                        .toList();
                    final totalGiven = activeCustodies.fold(
                      0.0,
                      (sum, c) => sum + c.initialAmount,
                    );
                    final totalSpent = activeCustodies.fold(
                      0.0,
                      (sum, c) => sum + c.spentAmount,
                    );
                    final totalRemaining = activeCustodies.fold(
                      0.0,
                      (sum, c) => sum + c.remainingAmount,
                    );

                    final filteredCustodies = _filterList(allCustodies);

                    return RefreshIndicator(
                      onRefresh: () => _cubit.loadCustodies(),
                      color: AppColors.primaryColor,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 960 : double.infinity,
                          ),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              isDesktop ? 24 : 16.w,
                              isDesktop ? 16 : 16.h,
                              isDesktop ? 24 : 16.w,
                              isDesktop ? 80 : 80.h, // Clearance for FAB
                            ),
                            children: [
                              // Top Financial Summary Cards
                              _buildSummarySection(
                                isDesktop: isDesktop,
                                activeCount: activeCustodies.length,
                                totalGiven: totalGiven,
                                totalSpent: totalSpent,
                                totalRemaining: totalRemaining,
                              ),
                              SizedBox(height: isDesktop ? 14 : 12.h),

                              // Simple Guidance Banner
                              _buildCustodyGuidanceBanner(isDesktop),
                              SizedBox(height: isDesktop ? 16 : 14.h),

                              // Search & Filter Tabs Bar
                              _buildSearchAndFilters(isDesktop),
                              SizedBox(height: isDesktop ? 16 : 16.h),

                              // List or Empty State
                              if (filteredCustodies.isEmpty)
                                _buildEmptyState(isDesktop)
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredCustodies.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: isDesktop ? 12 : 12.h),
                                  itemBuilder: (context, index) {
                                    return _buildCustodyCard(
                                      filteredCustodies[index],
                                      isDesktop,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Role guarded FloatingActionButton
        floatingActionButton: canCreateCustody
            ? FloatingActionButton.extended(
                onPressed: () => NewCustodyDialog.show(context, _cubit),
                backgroundColor: AppColors.primaryColor,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  AppStrings.newCustody.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 14.5 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCustodyGuidanceBanner(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 12.r),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primaryColor,
            size: isDesktop ? 22 : 20.r,
          ),
          SizedBox(width: isDesktop ? 10 : 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.custodyGuidanceTitle.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 13 : 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: isDesktop ? 4 : 3.h),
                Text(
                  AppStrings.custodyGuidanceBody.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 12 : 11.5,
                    color: AppColors.blackLight,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection({
    required bool isDesktop,
    required int activeCount,
    required double totalGiven,
    required double totalSpent,
    required double totalRemaining,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: AppColors.primaryColor,
                size: isDesktop ? 20 : 20.r,
              ),
              SizedBox(width: isDesktop ? 8 : 8.w),
              Text(
                AppStrings.activeCustodiesSummary.tr(),
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 14.5 : 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 10 : 10.w,
                  vertical: isDesktop ? 4 : 4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
                ),
                child: Text(
                  AppStrings.activeCustodiesCount.tr(
                    namedArgs: {'count': activeCount.toString()},
                  ),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 12 : 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 14 : 14.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  isDesktop: isDesktop,
                  label: AppStrings.totalCustodyGiven.tr(),
                  value: CurrencyHelper.formatCurrency(totalGiven),
                  color: AppColors.black,
                  icon: Icons.payments_outlined,
                ),
              ),
              SizedBox(width: isDesktop ? 10 : 10.w),
              Expanded(
                child: _buildMetricTile(
                  isDesktop: isDesktop,
                  label: AppStrings.totalCustodySpent.tr(),
                  value: CurrencyHelper.formatCurrency(totalSpent),
                  color: AppColors.orange,
                  icon: Icons.arrow_outward_rounded,
                ),
              ),
              SizedBox(width: isDesktop ? 10 : 10.w),
              Expanded(
                child: _buildMetricTile(
                  isDesktop: isDesktop,
                  label: AppStrings.totalCustodyRemaining.tr(),
                  value: CurrencyHelper.formatCurrency(totalRemaining),
                  color: totalRemaining < 0
                      ? AppColors.error
                      : AppColors.primaryColor,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required bool isDesktop,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: isDesktop ? 15 : 14.r, color: color),
              SizedBox(width: isDesktop ? 5 : 4.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 11.5 : 11,
                    color: AppColors.sandText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 6 : 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 15 : 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDesktop) {
    final filterChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip(0, AppStrings.all.tr(), isDesktop),
          SizedBox(width: isDesktop ? 8 : 8.w),
          _buildFilterChip(1, AppStrings.custodyActive.tr(), isDesktop),
          SizedBox(width: isDesktop ? 8 : 8.w),
          _buildFilterChip(2, AppStrings.custodySettled.tr(), isDesktop),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: CustomSearchField(
              hintText: AppStrings.searchCustodyHint.tr(),
              controller: _searchController,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 16),
          filterChips,
        ],
      );
    }

    return Column(
      children: [
        CustomSearchField(
          hintText: AppStrings.searchCustodyHint.tr(),
          controller: _searchController,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 12.h),
        filterChips,
      ],
    );
  }

  Widget _buildFilterChip(int index, String label, bool isDesktop) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 16.w,
          vertical: isDesktop ? 7 : 7.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.lightGreyColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 12.5 : 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.blackLight,
          ),
        ),
      ),
    );
  }

  Widget _buildCustodyCard(CustodyEntity custody, bool isDesktop) {
    final progress = custody.initialAmount > 0
        ? (custody.spentAmount / custody.initialAmount).clamp(0.0, 1.0)
        : 0.0;
    final isDeficit = custody.isDeficit;
    final allowEditNotes = canEditNotes(custody);
    final allowDelete =
        canDeleteCustody &&
        custody.isActive &&
        custody.spentAmount == 0 &&
        custody.expenses.isEmpty;
    final allowAddExp = canAddExpense(custody);
    final allowSettle = canSettleCustody;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 14.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        border: Border.all(
          color: custody.isActive
              ? AppColors.primaryColor.withValues(alpha: 0.2)
              : AppColors.lightGreyColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Recipient Name + Badges + Popup Menu
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      custody.recipientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 15.5 : 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      '${DateFormatter.formatDate(custody.createdAt)} • ${custody.recipientType == 'owner' ? AppStrings.recipientTypeOwner.tr() : (custody.recipientType == 'employee' ? AppStrings.recipientTypeEmployee.tr() : AppStrings.recipientTypeOther.tr())}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 11.5 : 11,
                        color: AppColors.sandText,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 10 : 10.w,
                  vertical: isDesktop ? 4 : 4.h,
                ),
                decoration: BoxDecoration(
                  color: custody.isActive
                      ? Colors.green.withValues(alpha: 0.12)
                      : AppColors.disabledColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    custody.isActive
                        ? AppStrings.custodyActive.tr()
                        : AppStrings.custodySettled.tr(),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 11 : 10.5,
                      fontWeight: FontWeight.bold,
                      color: custody.isActive
                          ? Colors.green
                          : AppColors.sandText,
                    ),
                  ),
                ),
              ),

              // Role Guarded Actions Popup Menu
              if (canExport || allowEditNotes || allowDelete)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.sandText,
                    size: isDesktop ? 20 : 20.r,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                  ),
                  onSelected: (val) {
                    if (val == 'print') {
                      _printCustody(custody);
                    } else if (val == 'share') {
                      _shareCustody(custody);
                    } else if (val == 'edit_notes') {
                      _showEditNotesDialog(custody);
                    } else if (val == 'delete') {
                      _showDeleteCustodyDialog(custody);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (canExport) ...[
                      PopupMenuItem(
                        value: 'print',
                        child: Row(
                          children: [
                            Icon(
                              Icons.print_rounded,
                              size: isDesktop ? 18 : 18.r,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: isDesktop ? 8 : 8.w),
                            Text(
                              AppStrings.printCustodyStatement.tr(),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 13 : 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(
                              Icons.share_rounded,
                              size: isDesktop ? 18 : 18.r,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: isDesktop ? 8 : 8.w),
                            Text(
                              AppStrings.shareCustodyStatement.tr(),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 13 : 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (allowEditNotes || allowDelete)
                        const PopupMenuDivider(),
                    ],
                    if (allowEditNotes)
                      PopupMenuItem(
                        value: 'edit_notes',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: isDesktop ? 18 : 18.r,
                              color: AppColors.blackLight,
                            ),
                            SizedBox(width: isDesktop ? 8 : 8.w),
                            Text(
                              AppStrings.editCustodyNotes.tr(),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 13 : 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (allowDelete)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: isDesktop ? 18 : 18.r,
                              color: AppColors.error,
                            ),
                            SizedBox(width: isDesktop ? 8 : 8.w),
                            Text(
                              AppStrings.deleteCustody.tr(),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 13 : 12.5,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),

          if (custody.notes != null && custody.notes!.isNotEmpty) ...[
            SizedBox(height: isDesktop ? 8 : 8.h),
            Text(
              custody.notes!,
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 12 : 11.5,
                color: AppColors.blackLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: isDesktop ? 12 : 12.h),

          // Budget Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(isDesktop ? 4 : 4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: isDesktop ? 6 : 6.h,
              backgroundColor: AppColors.lightGreyColor.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDeficit
                    ? AppColors.error
                    : (progress > 0.8
                          ? AppColors.orange
                          : AppColors.primaryColor),
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),

          // Three Metrics Columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCardMetric(
                  AppStrings.originalCustodyAmount.tr(),
                  CurrencyHelper.formatCurrency(custody.initialAmount),
                  AppColors.black,
                  isDesktop: isDesktop,
                ),
              ),
              Expanded(
                child: _buildCardMetric(
                  AppStrings.spentFromCustody.tr(),
                  CurrencyHelper.formatCurrency(custody.spentAmount),
                  AppColors.orange,
                  isDesktop: isDesktop,
                ),
              ),
              Expanded(
                child: _buildCardMetric(
                  custody.isSettled
                      ? (isDeficit
                          ? AppStrings.custodyReimbursedToEmployee.tr()
                          : AppStrings.custodyReturnedToVault.tr())
                      : (isDeficit
                          ? AppStrings.dueToEmployee.tr()
                          : AppStrings.remainingInCustody.tr()),
                  CurrencyHelper.formatCurrency(
                    custody.isSettled
                        ? (isDeficit
                            ? custody.remainingAmount.abs()
                            : (custody.actualSettledAmount ?? custody.remainingAmount))
                        : custody.remainingAmount.abs(),
                  ),
                  isDeficit ? AppColors.error : AppColors.primaryColor,
                  isHighlight: true,
                  isDesktop: isDesktop,
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Action Buttons (Responsive Wrap)
          Wrap(
            spacing: isDesktop ? 8 : 8.w,
            runSpacing: isDesktop ? 8 : 8.h,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Details Button
              OutlinedButton.icon(
                onPressed: () =>
                    CustodyExpensesSheet.show(context, custody, cubit: _cubit),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blackLight,
                  side: BorderSide(color: AppColors.lightGreyColor),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 10.w,
                    vertical: isDesktop ? 8 : 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                  ),
                ),
                icon: Icon(
                  Icons.receipt_long_outlined,
                  size: isDesktop ? 16 : 16.r,
                ),
                label: Text(
                  AppStrings.custodyExpensesCount.tr(
                    namedArgs: {'count': custody.expenses.length.toString()},
                  ),
                  style: TextStyles.customStyle(fontSize: isDesktop ? 12 : 11),
                ),
              ),

              if (custody.isActive) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // + Record Expense Button (Guarded)
                    if (allowAddExp) ...[
                      ElevatedButton.icon(
                        onPressed: () => AddCustodyExpenseDialog.show(
                          context,
                          custody: custody,
                          cubit: _cubit,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: AppColors.primaryColor,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 12 : 10.w,
                            vertical: isDesktop ? 8 : 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 10 : 10.r,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.add_rounded,
                          size: isDesktop ? 16 : 16.r,
                        ),
                        label: Text(
                          AppStrings.addCustodyExpenseBtn.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12.5 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: isDesktop ? 8 : 8.w),
                    ],

                    // Settle Custody Button (Guarded)
                    if (allowSettle)
                      ElevatedButton.icon(
                        onPressed: () => SettleCustodyDialog.show(
                          context,
                          custody: custody,
                          cubit: _cubit,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 14 : 12.w,
                            vertical: isDesktop ? 8 : 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 10 : 10.r,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.price_check_rounded,
                          size: isDesktop ? 16 : 16.r,
                        ),
                        label: Text(
                          AppStrings.settleCustody.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12.5 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ] else ...[
                // Settled Badge / Info
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 10 : 10.w,
                    vertical: isDesktop ? 6 : 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreyColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(isDesktop ? 8 : 8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: isDesktop ? 14 : 14.r,
                        color: Colors.green,
                      ),
                      SizedBox(width: isDesktop ? 4 : 4.w),
                      Text(
                        '${AppStrings.custodySettled.tr()} ${custody.settledAt != null ? DateFormatter.formatDate(custody.settledAt!) : ''}',
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 11.5 : 11,
                          color: AppColors.sandText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardMetric(
    String label,
    String value,
    Color color, {
    bool isHighlight = false,
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 11.5 : 11,
            color: AppColors.sandText,
          ),
        ),
        SizedBox(height: isDesktop ? 2 : 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: TextStyles.customStyle(
              fontSize: isHighlight
                  ? (isDesktop ? 15.5 : 15)
                  : (isDesktop ? 13.5 : 13),
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isDesktop ? 48 : 48.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 20.r),
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: isDesktop ? 48 : 48.r,
                color: AppColors.grey,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 16.h),
            Text(
              AppStrings.noCustodiesYet.tr(),
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 16.5 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: isDesktop ? 6 : 6.h),
            Text(
              AppStrings.noCustodiesDesc.tr(),
              textAlign: TextAlign.center,
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 12.5 : 12,
                color: AppColors.sandText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

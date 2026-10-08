import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/currency_helper.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/custody/domain/entities/custody_entity.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

import '../../domain/entities/custody_expense_item.dart';
import '../cubit/custody_cubit.dart';
import '../utils/custody_category_helper.dart';
import '../utils/custody_statement_pdf_exporter.dart';

class CustodyExpensesSheet extends StatelessWidget {
  final CustodyEntity custody;
  final CustodyCubit? cubit;

  const CustodyExpensesSheet({super.key, required this.custody, this.cubit});

  static void show(
    BuildContext context,
    CustodyEntity custody, {
    CustodyCubit? cubit,
  }) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    final isDesktop = ResponsiveLayout.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustodyExpensesSheet(custody: custody, cubit: cubit),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CustodyExpensesSheet(custody: custody, cubit: cubit),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final expenses = custody.expenses;
    final canExport = CustodyStatementPdfExporter.hasExportPermission();
    // ignore: unused_local_variable
    final canDelete =
        PermissionService.instance.isOwner ||
        PermissionService.instance.hasPermission(AppPermissions.expensesDelete);

    return Container(
      constraints: BoxConstraints(
        maxHeight: isDesktop ? 680 : MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: isDesktop
            ? BorderRadius.circular(20)
            : BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Drag Handle (mobile only)
          if (!isDesktop) ...[
            SizedBox(height: 12.h),
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.lightGreyColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ],
          SizedBox(height: isDesktop ? 16 : 12.h),

          // Sheet Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 20.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.custodyExpenseDetails.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 18 : 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        '${custody.recipientName} • ${AppStrings.custodyOperationsCount.tr(namedArgs: {'count': expenses.length.toString()})}',
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 12.5 : 12,
                          color: AppColors.sandText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canExport) ...[
                  IconButton(
                    tooltip: AppStrings.printCustodyStatement.tr(),
                    onPressed: () {
                      if (context.read<ConnectivityCubit>().state
                          is ConnectivityDisconnected) {
                        showfailureToast(AppStrings.noInternetConnection.tr());
                        return;
                      }
                      CustodyStatementPdfExporter.printCustodyStatement(
                        context,
                        custody: custody,
                        isArabic: AppStrings.currentLang == 'ar',
                      );
                    },
                    icon: Icon(
                      Icons.print_rounded,
                      color: AppColors.primaryColor,
                      size: isDesktop ? 22 : 22.r,
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.shareCustodyStatement.tr(),
                    onPressed: () {
                      if (context.read<ConnectivityCubit>().state
                          is ConnectivityDisconnected) {
                        showfailureToast(AppStrings.noInternetConnection.tr());
                        return;
                      }
                      CustodyStatementPdfExporter.exportAndShare(
                        custody: custody,
                        isArabic: AppStrings.currentLang == 'ar',
                      );
                    },
                    icon: Icon(
                      Icons.share_rounded,
                      color: AppColors.primaryColor,
                      size: isDesktop ? 20 : 20.r,
                    ),
                  ),
                ],
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.sandText,
                    size: isDesktop ? 22 : 22.r,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Expenses List
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(isDesktop ? 32 : 24.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: isDesktop ? 48 : 48.r,
                            color: AppColors.disabledColor,
                          ),
                          SizedBox(height: isDesktop ? 12 : 12.h),
                          Text(
                            AppStrings.noCustodyExpensesYet.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 13.5 : 13,
                              color: AppColors.sandText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16.w,
                      vertical: isDesktop ? 10 : 8.h,
                    ),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: isDesktop ? 10 : 8.h),
                    itemBuilder: (context, index) {
                      final item = expenses[index];
                      return Container(
                        padding: EdgeInsets.all(isDesktop ? 14 : 12.r),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreyColor.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 12 : 12.r,
                          ),
                          border: Border.all(
                            color: AppColors.lightGreyColor.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isDesktop ? 8 : 8.r),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_outward_rounded,
                                color: AppColors.orange,
                                size: isDesktop ? 18 : 18.r,
                              ),
                            ),
                            SizedBox(width: isDesktop ? 12 : 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.displayTitle,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 14 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  SizedBox(height: isDesktop ? 3 : 2.h),
                                  Text(
                                    (item.description.trim().isNotEmpty &&
                                            item.description.trim() != item.displayCategory &&
                                            CustodyCategoryHelper.tryMapCategoryKeyToLocalized(item.description.trim()) == null &&
                                            !item.isPurchaseItem)
                                        ? '${item.displayCategory} • ${DateFormatter.formatDateTime(item.date)}'
                                        : DateFormatter.formatDateTime(item.date),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 11.5 : 11,
                                      color: AppColors.sandText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isDesktop ? 8 : 8.w),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '- ${CurrencyHelper.formatCurrency(item.amount)}',
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 14 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                            if (canDelete && custody.isActive) ...[
                              SizedBox(width: isDesktop ? 6 : 6.w),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: isDesktop ? 18 : 18.r,
                                  color: AppColors.error.withValues(alpha: 0.8),
                                ),
                                tooltip: AppStrings.delete.tr(),
                                onPressed: () =>
                                    _deleteExpenseItem(context, item),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Summary Bar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 20.w,
              vertical: isDesktop ? 16 : 14.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.spentFromCustody.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 11.5 : 11,
                          color: AppColors.sandText,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          CurrencyHelper.formatCurrency(custody.spentAmount),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 15.5 : 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppStrings.remainingInCustody.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 11.5 : 11,
                          color: AppColors.sandText,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          CurrencyHelper.formatCurrency(
                            custody.remainingAmount,
                          ),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 16.5 : 16,
                            fontWeight: FontWeight.w800,
                            color: custody.isDeficit
                                ? AppColors.error
                                : AppColors.primaryColor,
                          ),
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
    );
  }

  // ignore: unused_element
  Future<void> _deleteExpenseItem(
    BuildContext context,
    CustodyExpenseItem item,
  ) async {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    if (custody.isSettled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.cannotDeleteSettledCustodyExpense.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final bool isPurchase = item.isPurchaseItem;

    if (isPurchase) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                AppStrings.inventoryPurchases.tr(),
                style: TextStyles.customStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            AppStrings.custodyItemLinkedToPurchaseNotice.tr(),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(
              AppStrings.confirmDelete.tr(),
              style: TextStyles.customStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          AppStrings.confirmDeleteCustodyExpenseMsg.tr(
            namedArgs: {'amount': CurrencyHelper.formatCurrency(item.amount)},
          ),
          style: TextStyles.customStyle(
            fontSize: 13.5,
            color: AppColors.blackLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(color: AppColors.sandText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              AppStrings.delete.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        if (cubit != null) {
          final success = await cubit!.deleteCustodyExpenseItem(
            custodyId: custody.id,
            expenseItem: item,
          );
          if (success && context.mounted) {
            Navigator.pop(context); // Close sheet to reflect updated card
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.operationSuccess.tr()),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

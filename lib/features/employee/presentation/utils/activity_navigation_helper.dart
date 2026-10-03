import 'package:flutter/material.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/injection_container.dart' as di;
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/employee/domain/entities/employee_activity_entity.dart';
import 'package:tahsel/features/invoice/data/datasources/invoice_remote_data_source.dart';
import 'package:tahsel/routes/app_routes.dart';

class ActivityNavigationHelper {
  ActivityNavigationHelper._();

  /// Determines whether the activity has a concrete, guaranteed direct navigation target.
  /// If this returns false, the UI will HIDE the navigation button so that users never
  /// experience dead-ends or 'no direct link' error messages.
  static bool hasLinkedEntity(EmployeeActivityEntity activity) {
    final extra = activity.extraData ?? {};
    final cat = activity.actionCategory;
    final type = activity.actionType.toLowerCase();

    // 1. Invoice target: only if invoiceId is non-empty
    if (extra['invoiceId']?.toString().trim().isNotEmpty == true) {
      return true;
    }

    // 2. Customer Debt target: debtId
    if (extra['debtId']?.toString().trim().isNotEmpty == true) {
      return true;
    }

    // 3. Customer statement target: customerId
    if (extra['customerId']?.toString().trim().isNotEmpty == true) {
      return true;
    }

    // 4. My Debt target: myDebtId or personId
    if (extra['myDebtId']?.toString().trim().isNotEmpty == true ||
        extra['personId']?.toString().trim().isNotEmpty == true) {
      return true;
    }

    // 5. Inventory item target: productId
    if (extra['productId']?.toString().trim().isNotEmpty == true) {
      return true;
    }

    // 6. Inventory supplier target: supplierId
    if (extra['supplierId']?.toString().trim().isNotEmpty == true) {
      return true;
    }

    // 7. Inventory category target: categoryId
    if (extra['categoryId']?.toString().trim().isNotEmpty == true) {
      return true;
    }

    // 8. General inventory actions: if category is inventory
    if (cat == 'inventory') {
      return true;
    }

    // 9. Vault actions: if category is vault
    if (cat == 'vault') {
      return true;
    }

    // 10. Team management actions: if category is employees
    if (cat == 'employees') {
      return true;
    }

    // 11. Shipping reconciliation actions
    if (type.contains('reconciliation') ||
        extra['reconciliationId']?.toString().trim().isNotEmpty == true) {
      return true;
    }

    return false;
  }

  static String getLinkedEntityLabel(EmployeeActivityEntity activity) {
    final extra = activity.extraData ?? {};
    final cat = activity.actionCategory;
    final type = activity.actionType.toLowerCase();

    if (extra['invoiceId']?.toString().trim().isNotEmpty == true) {
      return AppStrings.openOriginalInvoice.tr();
    }
    if (extra['debtId']?.toString().trim().isNotEmpty == true) {
      return AppStrings.viewDebtDetails.tr();
    }
    if (extra['customerId']?.toString().trim().isNotEmpty == true) {
      return AppStrings.viewCustomerStatement.tr();
    }
    if (extra['myDebtId']?.toString().trim().isNotEmpty == true ||
        extra['personId']?.toString().trim().isNotEmpty == true) {
      return AppStrings.viewDebtItemDetails.tr();
    }
    if (extra['productId']?.toString().trim().isNotEmpty == true) {
      return AppStrings.viewInventoryDetails.tr();
    }
    if (extra['supplierId']?.toString().trim().isNotEmpty == true) {
      return AppStrings.viewSuppliersList.tr();
    }
    if (extra['categoryId']?.toString().trim().isNotEmpty == true) {
      return AppStrings.viewInventoryCategories.tr();
    }
    if (cat == 'inventory') {
      return AppStrings.goToInventoryScreen.tr();
    }
    if (cat == 'vault') {
      return AppStrings.goToVaultScreen.tr();
    }
    if (cat == 'employees') {
      return AppStrings.manageTeamAndStaff.tr();
    }
    if (type.contains('reconciliation') ||
        extra['reconciliationId']?.toString().trim().isNotEmpty == true) {
      return AppStrings.viewShippingReconciliation.tr();
    }

    return AppStrings.goToLinkedSection.tr();
  }

  static IconData getLinkedEntityIcon(EmployeeActivityEntity activity) {
    final extra = activity.extraData ?? {};
    final cat = activity.actionCategory;
    final type = activity.actionType.toLowerCase();

    if (extra['invoiceId']?.toString().trim().isNotEmpty == true) {
      return Icons.receipt_long_rounded;
    }
    if (extra['debtId']?.toString().trim().isNotEmpty == true) {
      return Icons.account_balance_wallet_outlined;
    }
    if (extra['customerId']?.toString().trim().isNotEmpty == true) {
      return Icons.person_outline_rounded;
    }
    if (extra['myDebtId']?.toString().trim().isNotEmpty == true ||
        extra['personId']?.toString().trim().isNotEmpty == true) {
      return Icons.assignment_outlined;
    }
    if (extra['productId']?.toString().trim().isNotEmpty == true) {
      return Icons.inventory_2_outlined;
    }
    if (extra['supplierId']?.toString().trim().isNotEmpty == true) {
      return Icons.local_shipping_outlined;
    }
    if (extra['categoryId']?.toString().trim().isNotEmpty == true) {
      return Icons.category_outlined;
    }
    if (cat == 'inventory') {
      return Icons.warehouse_outlined;
    }
    if (cat == 'vault') {
      return Icons.savings_outlined;
    }
    if (cat == 'employees') {
      return Icons.group_work_outlined;
    }
    if (type.contains('reconciliation') ||
        extra['reconciliationId']?.toString().trim().isNotEmpty == true) {
      return Icons.local_shipping_outlined;
    }

    return Icons.open_in_new_rounded;
  }

  static Future<void> navigateToLinkedEntity(
    BuildContext context,
    EmployeeActivityEntity activity,
  ) async {
    final extra = activity.extraData ?? {};
    final cat = activity.actionCategory;
    final type = activity.actionType.toLowerCase();

    // 1. Invoice Deep Link
    final invoiceId = extra['invoiceId']?.toString().trim();
    if (invoiceId != null && invoiceId.isNotEmpty) {
      await _openInvoice(context, invoiceId);
      return;
    }

    // 2. Debt Deep Link
    final debtId = extra['debtId']?.toString().trim();
    if (debtId != null && debtId.isNotEmpty) {
      if (!PermissionService.instance.hasPermission(AppPermissions.customersView)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      Navigator.pushNamed(context, AppRoutes.debtDetails, arguments: debtId);
      return;
    }

    // 3. Customer Deep Link
    final customerId = extra['customerId']?.toString().trim();
    if (customerId != null && customerId.isNotEmpty) {
      if (!PermissionService.instance.hasPermission(AppPermissions.customersView)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      final customerName = extra['customerName']?.toString().trim();
      if (customerName != null &&
          customerName.isNotEmpty &&
          PermissionService.instance.hasPermission(AppPermissions.customersViewReports)) {
        Navigator.pushNamed(
          context,
          AppRoutes.customerReportDetails,
          arguments: {
            'uid': AppStrings.userToken,
            'customerName': customerName,
          },
        );
      } else {
        Navigator.pushNamed(
          context,
          AppRoutes.customersList,
          arguments: AppStrings.userToken,
        );
      }
      return;
    }

    // 4. My Debt Deep Link
    final myDebtId = (extra['myDebtId'] ?? extra['personId'])?.toString().trim();
    if (myDebtId != null && myDebtId.isNotEmpty) {
      if (!PermissionService.instance.hasPermission(AppPermissions.myDebtsView)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      Navigator.pushNamed(
        context,
        AppRoutes.myDebtDetailsReport,
        arguments: myDebtId,
      );
      return;
    }

    // 5. Product Deep Link
    final productId = extra['productId']?.toString().trim();
    if (productId != null && productId.isNotEmpty) {
      if (!PermissionService.instance.hasPermission(AppPermissions.inventoryView) &&
          !PermissionService.instance.hasPermission(AppPermissions.inventoryManageProducts)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      Navigator.pushNamed(context, AppRoutes.inventoryProducts);
      return;
    }

    // 6. Supplier Deep Link
    final supplierId = extra['supplierId']?.toString().trim();
    if (supplierId != null && supplierId.isNotEmpty) {
      if (!PermissionService.instance.hasPermission(AppPermissions.inventoryManageSuppliers)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      Navigator.pushNamed(context, AppRoutes.inventorySuppliers);
      return;
    }

    // 7. Category Deep Link
    final categoryId = extra['categoryId']?.toString().trim();
    if (categoryId != null && categoryId.isNotEmpty) {
      if (!PermissionService.instance.hasPermission(AppPermissions.inventoryManageCategories) &&
          !PermissionService.instance.hasPermission(AppPermissions.inventoryView)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      Navigator.pushNamed(context, AppRoutes.inventoryCategories);
      return;
    }

    // 8. General Inventory
    if (cat == 'inventory') {
      if (!PermissionService.instance.hasPermission(AppPermissions.inventoryView)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      Navigator.pushNamed(context, AppRoutes.inventoryProducts);
      return;
    }

    // 9. Vault Deep Link
    if (cat == 'vault') {
      if (!PermissionService.instance.hasPermission(AppPermissions.vaultAccess)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      Navigator.pushNamed(context, AppRoutes.vault);
      return;
    }

    // 10. Team Management Deep Link
    if (cat == 'employees') {
      if (!PermissionService.instance.isOwner &&
          !PermissionService.instance.hasPermission(AppPermissions.hrEmployeesManage)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      Navigator.pushNamed(context, AppRoutes.teamManagement);
      return;
    }

    // 11. Shipping Reconciliation Deep Link
    if (type.contains('reconciliation') ||
        extra['reconciliationId']?.toString().trim().isNotEmpty == true) {
      if (!PermissionService.instance.hasPermission(AppPermissions.shippingReconciliationView)) {
        _showNoPermissionSnackBar(context);
        return;
      }
      Navigator.pushNamed(context, AppRoutes.shippingReconciliation);
      return;
    }
  }

  static Future<void> _openInvoice(BuildContext context, String invoiceId) async {
    if (!PermissionService.instance.hasPermission(AppPermissions.invoicesView)) {
      _showNoPermissionSnackBar(context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryColor),
              const SizedBox(height: 12),
              Text(
                AppStrings.loadingInvoice.tr(),
                style: TextStyles.customStyle(fontSize: 13, color: AppColors.black),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final remoteSource = di.sl<InvoiceRemoteDataSource>();
      final invoice = await remoteSource.getInvoiceById(
        AppStrings.userToken,
        invoiceId,
      );

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
      }

      if (invoice != null && context.mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.invoiceDetail,
          arguments: invoice,
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.invoiceNotFoundOrDeleted.tr(),
              style: TextStyles.customStyle(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.errorLoadingInvoice.tr()}: $e',
              style: TextStyles.customStyle(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  static void _showNoPermissionSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.noPermissionForSection.tr(),
          style: TextStyles.customStyle(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

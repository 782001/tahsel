import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/widgets/permission_guard.dart';
import 'package:tahsel/features/customer/domain/entities/customer_entity.dart';
import 'package:tahsel/features/customer/domain/usecases/get_customer_operations_usecase.dart';
import 'package:tahsel/features/customer/presentation/utils/customer_statement_pdf_exporter.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';
import '../cubit/customer_reports/customer_reports_cubit.dart';
import 'add_customer_dialog.dart';

class CustomerListCard extends StatelessWidget {
  final dynamic customer;
  final String uid;

  const CustomerListCard({
    super.key,
    required this.customer,
    required this.uid,
  });

  void _showStatementOptions(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _CustomerStatementOptionsWidget(customer: customer, uid: uid),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _CustomerStatementOptionsWidget(customer: customer, uid: uid),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Card(
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.blackLight.withAlpha(20), width: 1),
      ),
      color: AppColors.debtCardSurface,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.customerReportDetails,
            arguments: {
              'uid': uid,
              'customerName': customer.name,
              'customer': customer,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        color: AppColors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 14,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${customer.totalTransactions} ${AppStrings.operations.tr()}',
                                style: TextStyles.customStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (customer.phoneNumber != null &&
                            customer.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.blackLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.phoneNumber!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.customStyle(
                                color: AppColors.blackLight,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if ((customer.ledgerNumber != null &&
                            customer.ledgerNumber!.isNotEmpty) ||
                        (customer.taxNumber != null &&
                            customer.taxNumber!.isNotEmpty) ||
                        (customer.commercialRegistration != null &&
                            customer.commercialRegistration!.isNotEmpty)) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (customer.ledgerNumber != null &&
                              customer.ledgerNumber!.isNotEmpty)
                            _buildBadge(
                              icon: Icons.menu_book_outlined,
                              text:
                                  '${AppStrings.ledgerNumber.tr()}: ${customer.ledgerNumber}',
                            ),
                          if (customer.taxNumber != null &&
                              customer.taxNumber!.isNotEmpty)
                            _buildBadge(
                              icon: Icons.receipt_outlined,
                              text:
                                  '${AppStrings.taxNumber.tr()}: ${customer.taxNumber}',
                            ),
                          if (customer.commercialRegistration != null &&
                              customer.commercialRegistration!.isNotEmpty)
                            _buildBadge(
                              icon: Icons.badge_outlined,
                              text:
                                  '${AppStrings.commercialRegistration.tr()}: ${customer.commercialRegistration}',
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PermissionGuard(
                    permission: AppPermissions.customersViewReports,
                    child: IconButton(
                      icon: Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                        color: AppColors.primaryColor,
                      ),
                      tooltip: AppStrings.customerAccountStatement.tr(),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 20,
                      onPressed: () => _showStatementOptions(context),
                    ),
                  ),
                  const SizedBox(width: 2),
                  PermissionGuard(
                    permission: AppPermissions.customersEdit,
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.blackLight,
                      ),
                      tooltip: AppStrings.editCustomer.tr(),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 20,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => BlocProvider.value(
                            value: context.read<CustomerReportsCubit>(),
                            child: AddCustomerDialog(
                              uid: uid,
                              customer: customer,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.blackLight.withAlpha(100),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.blackLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.blackLight,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.customStyle(
                color: AppColors.blackLight,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StatementAction { print, share, whatsapp }

class _CustomerStatementOptionsWidget extends StatefulWidget {
  final dynamic customer;
  final String uid;

  const _CustomerStatementOptionsWidget({
    required this.customer,
    required this.uid,
  });

  @override
  State<_CustomerStatementOptionsWidget> createState() =>
      _CustomerStatementOptionsWidgetState();
}

class _CustomerStatementOptionsWidgetState
    extends State<_CustomerStatementOptionsWidget> {
  _StatementAction? _runningAction;

  Future<void> _executeAction(_StatementAction action) async {
    if (_runningAction != null) return;
    setState(() => _runningAction = action);

    try {
      final useCase = sl<GetCustomerOperationsUseCase>();
      final result = await useCase(
        uid: widget.uid,
        customerName: widget.customer.name,
        limit: 0,
      );

      await result.fold(
        (failure) async {
          showfailureToast(failure.message);
        },
        (paginated) async {
          final operations = paginated.$1;
          final totalSpent = paginated.$3;
          final totalPaid = paginated.$4;
          final remaining = totalSpent - totalPaid;
          final isArabic = AppStrings.currentLang == 'ar';
          final cust = widget.customer is CustomerEntity
              ? widget.customer as CustomerEntity
              : paginated.$5;

          if (!mounted) return;

          switch (action) {
            case _StatementAction.print:
              await CustomerStatementPdfExporter.printStatement(
                context,
                customerName: widget.customer.name,
                customer: cust,
                operations: operations,
                openingBalance: 0.0,
                totalSpent: totalSpent,
                totalPaid: totalPaid,
                remaining: remaining,
                isArabic: isArabic,
                direct: false,
              );
              break;
            case _StatementAction.share:
              await CustomerStatementPdfExporter.exportAndShare(
                customerName: widget.customer.name,
                customer: cust,
                operations: operations,
                openingBalance: 0.0,
                totalSpent: totalSpent,
                totalPaid: totalPaid,
                remaining: remaining,
                isArabic: isArabic,
              );
              break;
            case _StatementAction.whatsapp:
              await CustomerStatementPdfExporter.shareViaWhatsApp(
                customerName: widget.customer.name,
                customer: cust,
                operations: operations,
                openingBalance: 0.0,
                totalSpent: totalSpent,
                totalPaid: totalPaid,
                remaining: remaining,
                isArabic: isArabic,
              );
              break;
          }
        },
      );
    } catch (e) {
      showfailureToast(e.toString());
    } finally {
      if (mounted) {
        setState(() => _runningAction = null);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = widget.customer.phoneNumber != null &&
        widget.customer.phoneNumber!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle on mobile
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.blackLight.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.customerStatementOptions.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.customer.name,
                      style: TextStyles.customStyle(
                        color: AppColors.blackLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: AppColors.blackLight),
                splashRadius: 20,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Action 1: View Detailed Statement
          _buildActionTile(
            icon: Icons.analytics_outlined,
            title: AppStrings.viewDetailedStatement.tr(),
            subtitle: AppStrings.viewDetailedStatementDesc.tr(),
            iconColor: AppColors.primaryColor,
            isLoading: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.customerReportDetails,
                arguments: {
                  'uid': widget.uid,
                  'customerName': widget.customer.name,
                  'customer': widget.customer,
                },
              );
            },
          ),

          // Action 2: Direct Print
          _buildActionTile(
            icon: Icons.print_outlined,
            title: AppStrings.directPrint.tr(),
            subtitle: AppStrings.directPrintDesc.tr(),
            iconColor: Colors.teal,
            isLoading: _runningAction == _StatementAction.print,
            onTap: () => _executeAction(_StatementAction.print),
          ),

          // Action 3: Share PDF
          _buildActionTile(
            icon: Icons.picture_as_pdf_outlined,
            title: AppStrings.sharePdf.tr(),
            subtitle: AppStrings.sharePdfDesc.tr(),
            iconColor: Colors.deepOrange,
            isLoading: _runningAction == _StatementAction.share,
            onTap: () => _executeAction(_StatementAction.share),
          ),

          // Action 4: Send to WhatsApp
          _buildActionTile(
            assetIcon: Assets.imagesWhatsapp,
            title: AppStrings.sendToCustomerWhatsapp.tr(),
            subtitle: AppStrings.sendToCustomerWhatsappDesc.tr(),
            iconColor: const Color(0xFF25D366),
            isLoading: _runningAction == _StatementAction.whatsapp,
            enabled: hasPhone,
            onTap: () {
              if (!hasPhone) {
                showfailureToast(AppStrings.noPhoneForCustomer.tr());
                return;
              }
              _executeAction(_StatementAction.whatsapp);
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    IconData? icon,
    String? assetIcon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool isLoading,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: (enabled ? iconColor : AppColors.blackLight).withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: assetIcon != null
            ? Image.asset(
                assetIcon,
                width: 22,
                height: 22,
              )
            : Icon(
                icon,
                color: enabled ? iconColor : AppColors.blackLight.withAlpha(100),
                size: 22,
              ),
      ),
      title: Text(
        title,
        style: TextStyles.customStyle(
          color: enabled ? AppColors.black : AppColors.blackLight.withAlpha(120),
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyles.customStyle(
          color: AppColors.blackLight.withAlpha(150),
          fontSize: 11.5,
        ),
      ),
      trailing: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor,
              ),
            )
          : Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.blackLight.withAlpha(100),
            ),
      onTap: isLoading ? null : onTap,
    );
  }

}


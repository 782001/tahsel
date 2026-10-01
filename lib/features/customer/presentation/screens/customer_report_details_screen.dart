import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/activity_logger_service.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/customer_data_masker.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/permission_guard.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/domain/entities/customer_entity.dart';
import 'package:tahsel/features/customer/presentation/utils/customer_statement_pdf_exporter.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_operation_tile.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_summary_card.dart';
import 'package:tahsel/features/customer/presentation/widgets/skeletons/customer_operation_skeleton.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

import '../../../../core/services/injection_container.dart';
import '../cubit/customer_details/customer_details_cubit.dart';
import '../cubit/customer_details/customer_details_state.dart';

class CustomerReportDetailsScreen extends StatelessWidget {
  final String uid;
  final String customerName;
  final CustomerEntity? customer;

  const CustomerReportDetailsScreen({
    super.key,
    required this.uid,
    required this.customerName,
    this.customer,
  });

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.hasPermission(
      AppPermissions.customersViewReports,
    )) {
      return Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          backgroundColor: AppColors.scafoldBackGround,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: AppColors.disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noPermissionForAction.tr(),
                style: TextStyles.customStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          sl<CustomerDetailsCubit>()
            ..fetchOperations(uid, customerName, customer: customer),
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          backgroundColor: AppColors.scafoldBackGround,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            customerName,
            style: TextStyles.customStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _CustomerDetailsBody(
          uid: uid,
          customerName: customerName,
          customer: customer,
        ),
      ),
    );
  }
}

class _CustomerDetailsBody extends StatefulWidget {
  final String uid;
  final String customerName;
  final CustomerEntity? customer;

  const _CustomerDetailsBody({
    required this.uid,
    required this.customerName,
    this.customer,
  });

  @override
  State<_CustomerDetailsBody> createState() => _CustomerDetailsBodyState();
}

class _CustomerDetailsBodyState extends State<_CustomerDetailsBody> {
  final ScrollController _scrollController = ScrollController();
  bool _isExporting = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getPeriodTitle(CustomerDetailsLoaded state) {
    switch (state.selectedFilter) {
      case 'thisMonth':
        return AppStrings.thisMonth.tr();
      case 'lastMonth':
        return AppStrings.lastMonth.tr();
      case 'custom':
        if (state.startDate != null && state.endDate != null) {
          final s = DateFormat('yyyy/MM/dd').format(state.startDate!);
          final e = DateFormat('yyyy/MM/dd').format(state.endDate!);
          return '${AppStrings.fromDate.tr()}: $s  ${AppStrings.toDate.tr()}: $e';
        }
        return AppStrings.customPeriod.tr();
      case 'all':
      default:
        return AppStrings.allTime.tr();
    }
  }

  Future<void> _handlePrint(CustomerDetailsLoaded state) async {
    final canPrintShare = PermissionService.instance.hasPermission(
      AppPermissions.customersPrintShare,
    );
    if (!canPrintShare) {
      showfailureToast(AppStrings.noPermissionForAction.tr());
      return;
    }
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final isArabic = AppStrings.currentLang == 'ar';
      await CustomerStatementPdfExporter.printStatement(
        context,
        customerName: widget.customerName,
        customer: state.customer ?? widget.customer,
        operations: state.operations,
        openingBalance: state.openingBalance,
        totalSpent: state.totalSpent,
        totalPaid: state.totalPaid,
        remaining: state.remaining,
        isArabic: isArabic,
        periodTitle: _getPeriodTitle(state),
      );

      if (sl.isRegistered<ActivityLoggerService>()) {
        sl<ActivityLoggerService>().logStandalone(
          ownerUid: widget.uid,
          actionCategory: 'reports',
          actionType: 'print_customer_statement',
          actionTitle: 'طباعة كشف حساب: ${widget.customerName}',
          details:
              'طباعة كشف حساب تفصيلي للعميل ${widget.customerName} (${_getPeriodTitle(state)})',
          extraData: {
            'customerName': widget.customerName,
            'period': state.selectedFilter,
            'operationsCount': state.operations.length,
            'remaining': state.remaining,
          },
        );
      }
    } catch (e) {
      showfailureToast(e.toString());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleSharePdf(CustomerDetailsLoaded state) async {
    final canPrintShare = PermissionService.instance.hasPermission(
      AppPermissions.customersPrintShare,
    );
    if (!canPrintShare) {
      showfailureToast(AppStrings.noPermissionForAction.tr());
      return;
    }
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final isArabic = AppStrings.currentLang == 'ar';
      await CustomerStatementPdfExporter.exportAndShare(
        customerName: widget.customerName,
        customer: state.customer ?? widget.customer,
        operations: state.operations,
        openingBalance: state.openingBalance,
        totalSpent: state.totalSpent,
        totalPaid: state.totalPaid,
        remaining: state.remaining,
        isArabic: isArabic,
        periodTitle: _getPeriodTitle(state),
      );

      if (sl.isRegistered<ActivityLoggerService>()) {
        sl<ActivityLoggerService>().logStandalone(
          ownerUid: widget.uid,
          actionCategory: 'reports',
          actionType: 'export_customer_statement_pdf',
          actionTitle: 'تصدير كشف حساب PDF: ${widget.customerName}',
          details:
              'تصدير ومشاركة كشف حساب تفصيلي PDF للعميل ${widget.customerName} (${_getPeriodTitle(state)})',
          extraData: {
            'customerName': widget.customerName,
            'period': state.selectedFilter,
            'operationsCount': state.operations.length,
            'remaining': state.remaining,
          },
        );
      }
    } catch (e) {
      showfailureToast(e.toString());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleWhatsApp(CustomerDetailsLoaded state) async {
    final customer = state.customer ?? widget.customer;
    final canViewPhone = CustomerDataMasker.canViewCustomerPhone;
    final canSendWhatsapp = PermissionService.instance.hasPermission(
      AppPermissions.customersSendWhatsapp,
    );
    final canPrintShare = PermissionService.instance.hasPermission(
      AppPermissions.customersPrintShare,
    );

    if (!canViewPhone || !canSendWhatsapp || !canPrintShare) {
      showfailureToast(AppStrings.noPermissionForAction.tr());
      return;
    }

    final hasPhone = customer?.phoneNumber != null &&
        customer!.phoneNumber!.trim().isNotEmpty;
    if (!hasPhone) {
      showfailureToast(AppStrings.noPhoneForCustomer.tr());
      return;
    }

    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final isArabic = AppStrings.currentLang == 'ar';
      await CustomerStatementPdfExporter.shareViaWhatsApp(
        customerName: widget.customerName,
        customer: customer,
        operations: state.operations,
        openingBalance: state.openingBalance,
        totalSpent: state.totalSpent,
        totalPaid: state.totalPaid,
        remaining: state.remaining,
        isArabic: isArabic,
        periodTitle: _getPeriodTitle(state),
      );

      if (sl.isRegistered<ActivityLoggerService>()) {
        sl<ActivityLoggerService>().logStandalone(
          ownerUid: widget.uid,
          actionCategory: 'debts',
          actionType: 'send_customer_statement_whatsapp',
          actionTitle: 'إرسال كشف حساب واتساب: ${widget.customerName}',
          details:
              'إرسال كشف حساب ومطالبة مالية عبر واتساب للعميل ${widget.customerName} (${_getPeriodTitle(state)})',
          amount: state.remaining > 0 ? state.remaining : null,
          extraData: {
            'customerName': widget.customerName,
            'phoneNumber': customer.phoneNumber,
            'period': state.selectedFilter,
            'remaining': state.remaining,
          },
        );
      }
    } catch (e) {
      showfailureToast(e.toString());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _selectCustomDateRange(CustomerDetailsLoaded state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      context.read<CustomerDetailsCubit>().filterByPeriod(
        'custom',
        customStart: picked.start,
        customEnd: picked.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<CustomerDetailsCubit, CustomerDetailsState>(
      builder: (context, state) {
        if (state is CustomerDetailsLoading) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 900 : double.infinity,
              ),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CustomerSummarySkeleton(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: isDesktop
                        ? SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 120,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  const CustomerOperationTileSkeleton(),
                              childCount: 6,
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  const CustomerOperationTileSkeleton(),
                              childCount: 6,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is CustomerDetailsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyles.customStyle(
                      color: AppColors.black,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CustomerDetailsCubit>().fetchOperations(
                        widget.uid,
                        widget.customerName,
                        customer: widget.customer,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: Text(AppStrings.tryAgain.tr()),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is CustomerDetailsLoaded) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 950 : double.infinity,
              ),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Action Toolbar (Print, Share, WhatsApp)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: _buildActionToolbar(state, isDesktop),
                    ),
                  ),

                  // Date Filter Chips Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: _buildFilterChips(state),
                    ),
                  ),

                  // Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomerSummaryCard(
                        openingBalance: state.openingBalance,
                        totalSpent: state.totalSpent,
                        totalPaid: state.totalPaid,
                        remaining: state.remaining,
                      ),
                    ),
                  ),

                  // Operations List Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.accountStatement.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${state.operations.length} ${AppStrings.operations.tr()}',
                            style: TextStyles.customStyle(
                              color: AppColors.blackLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Operations / Transactions
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: isDesktop
                        ? SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 120,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= state.operations.length) {
                                  return const CustomerOperationTileSkeleton();
                                }
                                final op = state.operations[index];
                                return CustomerOperationTile(operation: op);
                              },
                              childCount:
                                  state.operations.length +
                                  (state.isFetchingMore ? 1 : 0),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= state.operations.length) {
                                  return const CustomerOperationTileSkeleton();
                                }
                                final op = state.operations[index];
                                return CustomerOperationTile(operation: op);
                              },
                              childCount:
                                  state.operations.length +
                                  (state.isFetchingMore ? 1 : 0),
                            ),
                          ),
                  ),

                  // Empty State
                  if (state.operations.isEmpty && !state.isFetchingMore)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 56,
                              color: AppColors.blackLight.withAlpha(120),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.noData.tr(),
                              style: TextStyles.customStyle(
                                color: AppColors.blackLight,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActionToolbar(CustomerDetailsLoaded state, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.blackLight.withAlpha(20),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getPeriodTitle(state),
              style: TextStyles.customStyle(
                color: AppColors.primaryColor,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isExporting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
            )
          else ...[
            _buildActionButton(
              icon: Icons.print_outlined,
              label: isDesktop ? AppStrings.printStatement.tr() : null,
              tooltip: AppStrings.printStatement.tr(),
              color: AppColors.primaryColor,
              onPressed: () => _handlePrint(state),
            ),
            const SizedBox(width: 6),
            _buildActionButton(
              icon: Icons.picture_as_pdf_outlined,
              label: isDesktop ? AppStrings.sharePdf.tr() : null,
              tooltip: AppStrings.sharePdf.tr(),
              color: Colors.deepOrange.shade600,
              onPressed: () => _handleSharePdf(state),
            ),
            const SizedBox(width: 6),
            _buildActionButton(
              assetIcon: Assets.imagesWhatsapp,
              label: isDesktop ? AppStrings.shareWhatsApp.tr() : null,
              tooltip: AppStrings.shareWhatsApp.tr(),
              color: const Color(0xFF25D366),
              onPressed: () => _handleWhatsApp(state),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    String? assetIcon,
    String? label,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
    String? permission,
  }) {
    final Widget leadingWidget = assetIcon != null
        ? Image.asset(
            assetIcon,
            width: label != null ? 18 : 22,
            height: label != null ? 18 : 22,
          )
        : Icon(
            icon,
            size: label != null ? 16 : 20,
            color: label != null ? Colors.white : color,
          );

    final Widget button = label != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: leadingWidget,
            label: Text(
              label,
              style: TextStyles.customStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          )
        : IconButton(
            icon: leadingWidget,
            tooltip: tooltip,
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
            onPressed: onPressed,
          );

    if (permission != null) {
      return PermissionGuard(permission: permission, child: button);
    }

    return button;
  }

  Widget _buildFilterChips(CustomerDetailsLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: AppStrings.allTime.tr(),
            isSelected: state.selectedFilter == 'all',
            onTap: () =>
                context.read<CustomerDetailsCubit>().filterByPeriod('all'),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: AppStrings.thisMonth.tr(),
            isSelected: state.selectedFilter == 'thisMonth',
            onTap: () => context.read<CustomerDetailsCubit>().filterByPeriod(
              'thisMonth',
            ),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: AppStrings.lastMonth.tr(),
            isSelected: state.selectedFilter == 'lastMonth',
            onTap: () => context.read<CustomerDetailsCubit>().filterByPeriod(
              'lastMonth',
            ),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: AppStrings.customPeriod.tr(),
            isSelected: state.selectedFilter == 'custom',
            icon: Icons.calendar_month_outlined,
            onTap: () => _selectCustomDateRange(state),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.blackLight.withAlpha(30),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.blackLight,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyles.customStyle(
                color: isSelected ? Colors.white : AppColors.black,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

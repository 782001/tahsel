import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../../domain/entities/inventory_supplier_entity.dart';
import '../cubits/inventory_suppliers_cubit.dart';
import '../widgets/add_edit_supplier_dialog.dart';
import '../widgets/inventory_empty_state.dart';
import 'supplier_details_screen.dart';
import 'package:tahsel/core/utils/date_formatter.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InventorySuppliersCubit>().fetchSuppliers();
  }

  void _openAddEditSupplierDialog([InventorySupplierEntity? supplier]) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditSupplierDialog(
        supplier: supplier,
        onSave: (savedSupplier) {
          context
              .read<InventorySuppliersCubit>()
              .saveSupplier(savedSupplier)
              .then((success) {
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.supplierSavedSuccess.tr()),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              });
        },
      ),
    );
  }

  void _confirmDeleteSupplier(
    BuildContext context,
    InventorySupplierEntity sup,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          AppStrings.confirmDelete.tr(),
          style: TextStyles.customStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blackReal,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.delete.tr()} "${sup.name}"؟',
              style: TextStyles.customStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.blackReal,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppStrings.deleteSupplierWarning.tr(),
              style: TextStyles.customStyle(
                fontSize: 13,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                color: AppColors.sandText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deleteRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<InventorySuppliersCubit>().deleteSupplier(sup.id);
            },
            child: Text(
              AppStrings.delete.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        backgroundColor: AppColors.scafoldBackGround,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          AppStrings.inventorySuppliers.tr(),
          style: TextStyles.customStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        onPressed: () => _openAddEditSupplierDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          AppStrings.addSupplier.tr(),
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 850 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
              child:
                  BlocBuilder<InventorySuppliersCubit, InventorySuppliersState>(
                    builder: (context, state) {
                      if (state is InventorySuppliersLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                            strokeWidth: 4,
                          ),
                        );
                      }
                      if (state is InventorySuppliersLoaded) {
                        final suppliers = state.suppliers;

                        if (suppliers.isEmpty) {
                          return InventoryEmptyState(
                            icon: Icons.local_shipping_outlined,
                            title: AppStrings.noSuppliersFound.tr(),
                            description: AppStrings.emptySuppliersDesc.tr(),
                            actionLabel: AppStrings.addSupplier.tr(),
                            onAction: () => _openAddEditSupplierDialog(),
                          );
                        }

                        return RefreshIndicator(
                          color: AppColors.primaryColor,
                          onRefresh: () async {
                            await context
                                .read<InventorySuppliersCubit>()
                                .fetchSuppliers();
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: suppliers.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: isDesktop ? 12 : 12.h),
                            itemBuilder: (context, index) {
                              final sup = suppliers[index];
                              return _buildSupplierCard(context, sup, isDesktop);
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(
    BuildContext context,
    InventorySupplierEntity sup,
    bool isDesktop,
  ) {
    final initial = sup.name.trim().isNotEmpty
        ? sup.name.trim().substring(0, 1).toUpperCase()
        : 'S';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => sl<InventorySuppliersCubit>(),
                child: SupplierDetailsScreen(supplier: sup),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
            border: Border.all(
              color: AppColors.dividerColor.withValues(alpha: 0.7),
            ),
            boxShadow: const [AppColors.shadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Names + Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isDesktop ? 44 : 44.r,
                    height: isDesktop ? 44 : 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.inventorySupplierTeal.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: TextStyles.customStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inventorySupplierTeal,
                      ),
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sup.name,
                          style: TextStyles.customStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackReal,
                          ),
                        ),
                        if (sup.companyName != null &&
                            sup.companyName!.trim().isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.business_rounded,
                                size: 13.r,
                                color: AppColors.blackLight,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  sup.companyName!.trim(),
                                  style: TextStyles.customStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.blackLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.edit_rounded,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        onPressed: () => _openAddEditSupplierDialog(sup),
                      ),
                      SizedBox(width: 14.w),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.deleteRed,
                          size: 20,
                        ),
                        onPressed: () => _confirmDeleteSupplier(context, sup),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 12 : 10.h),

              // Badges / Info Chips Wrap
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  // Phone Chip
                  _buildInfoChip(
                    icon: Icons.phone_rounded,
                    label: sup.phone.isNotEmpty
                        ? sup.phone
                        : AppStrings.noPhone.tr(),
                    color: AppColors.inventorySupplierTeal,
                  ),
                  // Address Chip
                  if (sup.address.trim().isNotEmpty)
                    _buildInfoChip(
                      icon: Icons.location_on_rounded,
                      label: sup.address.trim(),
                      color: AppColors.blackLight,
                    ),
                  // Tax Number Chip
                  if (sup.taxNumber != null &&
                      sup.taxNumber!.trim().isNotEmpty)
                    _buildInfoChip(
                      icon: Icons.receipt_long_rounded,
                      label:
                          '${AppStrings.taxNumber.tr()}: ${sup.taxNumber!.trim()}',
                      color: AppColors.warning,
                    ),
                  // Email Chip
                  if (sup.email != null && sup.email!.trim().isNotEmpty)
                    _buildInfoChip(
                      icon: Icons.email_outlined,
                      label: sup.email!.trim(),
                      color: AppColors.primaryColor,
                    ),
                ],
              ),

              // Notes section (if exists)
              if (sup.notes != null && sup.notes!.trim().isNotEmpty) ...[
                SizedBox(height: isDesktop ? 10 : 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.scafoldBackGround,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 14.r,
                        color: AppColors.blackLight,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          sup.notes!.trim(),
                          style: TextStyles.customStyle(
                            fontSize: 11,
                            color: AppColors.blackLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Card Footer: Added Date + View Details Link
              SizedBox(height: isDesktop ? 10 : 8.h),
              Divider(
                height: 1,
                color: AppColors.dividerColor.withValues(alpha: 0.4),
              ),
              SizedBox(height: isDesktop ? 8 : 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12.r,
                        color: AppColors.sandText,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${AppStrings.addedOn.tr()}: ${DateFormatter.formatNumericDate(sup.createdAt)}',
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: AppColors.sandText,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        AppStrings.viewSupplierDetails.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11.r,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyles.customStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

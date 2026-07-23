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

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: suppliers.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: isDesktop ? 12 : 12.h),
                          itemBuilder: (context, index) {
                            final sup = suppliers[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) =>
                                            sl<InventorySuppliersCubit>(),
                                        child: SupplierDetailsScreen(
                                          supplier: sup,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 14 : 14.r,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isDesktop ? 16 : 16.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                      isDesktop ? 14 : 14.r,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors
                                            .inventorySupplierTeal
                                            .withValues(alpha: 0.12),
                                        radius: isDesktop ? 22 : 22.r,
                                        child: Icon(
                                          Icons.local_shipping_rounded,
                                          color:
                                              AppColors.inventorySupplierTeal,
                                        ),
                                      ),
                                      SizedBox(width: isDesktop ? 16 : 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sup.name,
                                              style: TextStyles.customStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 4 : 4.h,
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  size: 14,
                                                  color: AppColors.sandText,
                                                ),
                                                SizedBox(
                                                  width: isDesktop ? 4 : 4.w,
                                                ),
                                                Text(
                                                  sup.phone.isNotEmpty
                                                      ? sup.phone
                                                      : AppStrings.noPhone.tr(),
                                                  style: TextStyles.customStyle(
                                                    fontSize: 13,
                                                    color: AppColors.sandText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit_rounded,
                                          color: AppColors.primaryColor,
                                        ),
                                        onPressed: () =>
                                            _openAddEditSupplierDialog(sup),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.deleteRed,
                                        ),
                                        onPressed: () => _confirmDeleteSupplier(
                                          context,
                                          sup,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: AppColors.sandText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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
}

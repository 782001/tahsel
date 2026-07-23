import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../../domain/entities/inventory_supplier_entity.dart';
import '../cubits/inventory_suppliers_cubit.dart';
import '../widgets/inventory_tab_selector.dart';

class SupplierDetailsScreen extends StatefulWidget {
  final InventorySupplierEntity supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<InventorySuppliersCubit>().fetchSupplierDetails(
      widget.supplier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final s = widget.supplier;

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
        title: Text(
          AppStrings.supplierDetails.tr(),
          style: TextStyles.customStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            child: Column(
              children: [
                // Supplier Info Header Card
                Container(
                  margin: EdgeInsets.all(isDesktop ? 16 : 16.w),
                  padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.inventorySupplierTeal
                            .withValues(alpha: 0.15),
                        radius: isDesktop ? 26 : 26.r,
                        child: Icon(
                          Icons.person_rounded,
                          size: 28,
                          color: AppColors.inventorySupplierTeal,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 16 : 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: TextStyles.customStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackReal,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 6 : 6.h),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Phone Pill Chip with tap-to-copy
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: s.phone.isNotEmpty
                                        ? () {
                                            Clipboard.setData(
                                              ClipboardData(text: s.phone),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  AppStrings
                                                      .phoneCopiedToClipboard
                                                      .tr(),
                                                ),
                                                backgroundColor:
                                                    AppColors.success,
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(6.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isDesktop ? 8 : 8.w,
                                        vertical: isDesktop ? 4 : 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.inventorySupplierTeal
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.inventorySupplierTeal
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.phone_rounded,
                                            size: 13,
                                            color:
                                                AppColors.inventorySupplierTeal,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            s.phone.isNotEmpty
                                                ? s.phone
                                                : AppStrings.noPhone.tr(),
                                            style: TextStyles.customStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors
                                                  .inventorySupplierTeal,
                                            ),
                                          ),
                                          if (s.phone.isNotEmpty) ...[
                                            SizedBox(width: 6.w),
                                            Icon(
                                              Icons.content_copy_rounded,
                                              size: 12,
                                              color: AppColors
                                                  .inventorySupplierTeal,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Address Pill Chip
                                if (s.address.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isDesktop ? 8 : 8.w,
                                      vertical: isDesktop ? 4 : 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.scafoldBackGround,
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: AppColors.dividerColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 13,
                                          color: AppColors.sandText,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          s.address,
                                          style: TextStyles.customStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.sandText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Email Pill Chip
                                if (s.email != null && s.email!.isNotEmpty)
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(text: s.email!),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppStrings.emailCopiedToClipboard
                                                  .tr(),
                                            ),
                                            backgroundColor: AppColors.success,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6.r),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isDesktop ? 8 : 8.w,
                                          vertical: isDesktop ? 4 : 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primaryColor
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.email_rounded,
                                              size: 13,
                                              color: AppColors.primaryColor,
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              s.email!,
                                              style: TextStyles.customStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                            SizedBox(width: 6.w),
                                            Icon(
                                              Icons.content_copy_rounded,
                                              size: 12,
                                              color: AppColors.primaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Selector — DebtsTabSelector style
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 16.w,
                  ),
                  child: InventoryTabSelector(
                    tabs: [
                      AppStrings.purchaseHistory.tr(),
                      AppStrings.stockSupplied.tr(),
                    ],
                    selectedIndex: _selectedTabIndex,
                    onTabChanged: (index) =>
                        setState(() => _selectedTabIndex = index),
                  ),
                ),
                SizedBox(height: isDesktop ? 8 : 8.h),

                // Tab Views
                Expanded(
                  child: BlocBuilder<InventorySuppliersCubit, InventorySuppliersState>(
                    builder: (context, state) {
                      if (state is InventorySuppliersLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                            strokeWidth: 4,
                          ),
                        );
                      }
                      if (state is SupplierDetailsLoaded) {
                        final purchases = state.purchases;
                        final products = state.suppliedProducts;

                        // Show view based on selected tab
                        if (_selectedTabIndex == 0) {
                          // Purchase History Tab
                          if (purchases.isEmpty) {
                            return Center(
                              child: Text(
                                AppStrings.noPurchasesFound.tr(),
                                style: TextStyles.customStyle(
                                  color: AppColors.disabledColor,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
                            itemCount: purchases.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: isDesktop ? 12 : 12.h),
                            itemBuilder: (context, index) {
                              final pur = purchases[index];
                              final dateStr = DateFormat(
                                'yyyy/MM/dd - hh:mm a',
                              ).format(pur.createdAt);
                              return Container(
                                padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    isDesktop ? 12 : 12.r,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${AppStrings.purchaseInvoiceNum.tr()} #${pur.id.substring(pur.id.length > 8 ? pur.id.length - 8 : 0)}',
                                          style: TextStyles.customStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.blackReal,
                                          ),
                                        ),
                                        Text(
                                          '${pur.totalAmount.toStringAsFixed(2)} ${AppStrings.egp.tr()}',
                                          style: TextStyles.customStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isDesktop ? 4 : 4.h),
                                    Text(
                                      dateStr,
                                      style: TextStyles.customStyle(
                                        fontSize: 12,
                                        color: AppColors.sandText,
                                      ),
                                    ),
                                    const Divider(),
                                    Column(
                                      children: pur.items
                                          .map(
                                            (item) => Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: isDesktop ? 2 : 2.h,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    item.productName,
                                                    style:
                                                        TextStyles.customStyle(
                                                          fontSize: 13,
                                                          color: AppColors
                                                              .blackReal,
                                                        ),
                                                  ),
                                                  Text(
                                                    '${item.quantity.toStringAsFixed(0)} × ${item.purchasePrice.toStringAsFixed(2)} ${AppStrings.egp.tr()}',
                                                    style:
                                                        TextStyles.customStyle(
                                                          fontSize: 13,
                                                          color: AppColors
                                                              .sandText,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else {
                          // Supplied Stock Tab
                          if (products.isEmpty) {
                            return Center(
                              child: Text(
                                AppStrings.noProductsFound.tr(),
                                style: TextStyles.customStyle(
                                  color: AppColors.disabledColor,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
                            itemCount: products.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: isDesktop ? 12 : 12.h),
                            itemBuilder: (context, index) {
                              final prod = products[index];
                              return Container(
                                padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    isDesktop ? 12 : 12.r,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.name,
                                          style: TextStyles.customStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.blackReal,
                                          ),
                                        ),
                                        SizedBox(height: isDesktop ? 2 : 2.h),
                                        Text(
                                          '${AppStrings.purchasePrice.tr()}: ${prod.purchasePrice.toSmartAmount()} ${AppStrings.egp.tr()}',
                                          style: TextStyles.customStyle(
                                            fontSize: 12,
                                            color: AppColors.sandText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${AppStrings.quantity.tr()}: ${prod.currentQuantity.toSmartAmount()} ${prod.unit}',
                                      style: TextStyles.customStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

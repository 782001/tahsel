import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import '../../domain/entities/inventory_supplier_entity.dart';
import '../cubits/inventory_suppliers_cubit.dart';

class SupplierDetailsScreen extends StatefulWidget {
  final InventorySupplierEntity supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<InventorySuppliersCubit>().fetchSupplierDetails(widget.supplier);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryColor),
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
            constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
            child: Column(
              children: [
                // Supplier Info Header Card
                Container(
                  margin: EdgeInsets.all(16.w),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF00796B).withValues(alpha: 0.15),
                        radius: 26.r,
                        child: const Icon(Icons.person_rounded, size: 28, color: Color(0xFF00796B)),
                      ),
                      SizedBox(width: 16.w),
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
                            SizedBox(height: 4.h),
                            Text(
                              'هاتف: ${s.phone}  |  العنوان: ${s.address}',
                              style: TextStyles.customStyle(fontSize: 13, color: AppColors.sandText),
                            ),
                            if (s.email != null && s.email!.isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Text(
                                'إيميل: ${s.email}',
                                style: TextStyles.customStyle(fontSize: 12, color: AppColors.sandText),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs Header
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: AppColors.sandText,
                  indicatorColor: AppColors.primaryColor,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: AppStrings.purchaseHistory.tr()),
                    Tab(text: AppStrings.stockSupplied.tr()),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: BlocBuilder<InventorySuppliersCubit, InventorySuppliersState>(
                    builder: (context, state) {
                      if (state is InventorySuppliersLoading) {
                        return Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
                      }
                      if (state is SupplierDetailsLoaded) {
                        final purchases = state.purchases;
                        final products = state.suppliedProducts;

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            // Purchase History Tab
                            purchases.isEmpty
                                ? Center(
                                    child: Text(
                                      AppStrings.noPurchasesFound.tr(),
                                      style: TextStyles.customStyle(color: AppColors.sandText),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(16.w),
                                    itemCount: purchases.length,
                                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                                    itemBuilder: (context, index) {
                                      final pur = purchases[index];
                                      final dateStr = DateFormat('yyyy/MM/dd - hh:mm a').format(pur.createdAt);
                                      return Container(
                                        padding: EdgeInsets.all(14.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(color: AppColors.dividerColor),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'فاتورة شراء #${pur.id.substring(pur.id.length > 8 ? pur.id.length - 8 : 0)}',
                                                  style: TextStyles.customStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.blackReal,
                                                  ),
                                                ),
                                                Text(
                                                  '${pur.totalAmount.toStringAsFixed(2)} ج.م',
                                                  style: TextStyles.customStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              dateStr,
                                              style: TextStyles.customStyle(fontSize: 12, color: AppColors.sandText),
                                            ),
                                            const Divider(),
                                            Column(
                                              children: pur.items
                                                  .map((item) => Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 2.h),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              item.productName,
                                                              style: TextStyles.customStyle(fontSize: 13, color: AppColors.blackReal),
                                                            ),
                                                            Text(
                                                              '${item.quantity.toStringAsFixed(0)} × ${item.purchasePrice.toStringAsFixed(2)} ج.م',
                                                              style: TextStyles.customStyle(fontSize: 13, color: AppColors.sandText),
                                                            ),
                                                          ],
                                                        ),
                                                      ))
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                            // Supplied Stock Tab
                            products.isEmpty
                                ? Center(
                                    child: Text(
                                      AppStrings.noProductsFound.tr(),
                                      style: TextStyles.customStyle(color: AppColors.sandText),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(16.w),
                                    itemCount: products.length,
                                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                                    itemBuilder: (context, index) {
                                      final prod = products[index];
                                      return Container(
                                        padding: EdgeInsets.all(14.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(color: AppColors.dividerColor),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  prod.name,
                                                  style: TextStyles.customStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.blackReal,
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  'سعر الشراء: ${prod.purchasePrice.toStringAsFixed(2)} ج.م',
                                                  style: TextStyles.customStyle(fontSize: 12, color: AppColors.sandText),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'الكمية: ${prod.currentQuantity.toStringAsFixed(0)} ${prod.unit}',
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
                                  ),
                          ],
                        );
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import '../cubits/inventory_products_cubit.dart';
import '../cubits/inventory_purchases_cubit.dart';
import '../cubits/inventory_suppliers_cubit.dart';
import 'create_purchase_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryPurchasesCubit>().fetchPurchases();
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.inventoryPurchases.tr(),
          style: TextStyles.customStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: context.read<InventoryPurchasesCubit>()),
                  BlocProvider(create: (_) => sl<InventorySuppliersCubit>()..fetchSuppliers()),
                  BlocProvider(create: (_) => sl<InventoryProductsCubit>()..fetchProducts()),
                ],
                child: const CreatePurchaseScreen(),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: Text(
          AppStrings.newPurchase.tr(),
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
            constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
              child: BlocBuilder<InventoryPurchasesCubit, InventoryPurchasesState>(
                builder: (context, state) {
                  if (state is InventoryPurchasesLoading) {
                    return Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
                  }
                  if (state is InventoryPurchasesLoaded) {
                    final purchases = state.purchases;

                    if (purchases.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.sandText),
                            SizedBox(height: 12.h),
                            Text(
                              AppStrings.noPurchasesFound.tr(),
                              style: TextStyles.customStyle(fontSize: 16, color: AppColors.sandText),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: purchases.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final pur = purchases[index];
                        final dateStr = DateFormat('yyyy/MM/dd - hh:mm a').format(pur.createdAt);

                        return Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppColors.dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFF6B11B0).withValues(alpha: 0.12),
                                        radius: 20.r,
                                        child: const Icon(Icons.receipt_rounded, color: Color(0xFF6B11B0), size: 20),
                                      ),
                                      SizedBox(width: 12.w),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'مورد: ${pur.supplierName}',
                                            style: TextStyles.customStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.blackReal,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            dateStr,
                                            style: TextStyles.customStyle(fontSize: 12, color: AppColors.sandText),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${pur.totalAmount.toStringAsFixed(2)} ج.م',
                                    style: TextStyles.customStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              const Divider(),
                              Column(
                                children: pur.items
                                    .map((item) => Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4.h),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: TextStyles.customStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.blackReal,
                                                ),
                                              ),
                                              Text(
                                                '${item.quantity.toStringAsFixed(0)} وحدة × ${item.purchasePrice.toStringAsFixed(2)} = ${item.subtotal.toStringAsFixed(2)} ج.م',
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

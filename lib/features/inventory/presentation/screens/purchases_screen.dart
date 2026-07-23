import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../cubits/inventory_products_cubit.dart';
import '../cubits/inventory_purchases_cubit.dart';
import '../cubits/inventory_suppliers_cubit.dart';
import '../widgets/inventory_empty_state.dart';
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

  void _navigateToCreatePurchase() {
    final purchasesCubit = context.read<InventoryPurchasesCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: purchasesCubit),
            BlocProvider(
              create: (_) => sl<InventorySuppliersCubit>()..fetchSuppliers(),
            ),
            BlocProvider(
              create: (_) => sl<InventoryProductsCubit>()..fetchProducts(),
            ),
          ],
          child: const CreatePurchaseScreen(),
        ),
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
        onPressed: _navigateToCreatePurchase,
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
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
              child: BlocBuilder<InventoryPurchasesCubit, InventoryPurchasesState>(
                builder: (context, state) {
                  if (state is InventoryPurchasesLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                        strokeWidth: 4,
                      ),
                    );
                  }
                  if (state is InventoryPurchasesLoaded) {
                    final purchases = state.purchases;

                    if (purchases.isEmpty) {
                      return InventoryEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: AppStrings.noPurchasesFound.tr(),
                        description: AppStrings.emptyPurchasesDesc.tr(),
                        actionLabel: AppStrings.newPurchase.tr(),
                        onAction: () => _navigateToCreatePurchase(),
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: purchases.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: isDesktop ? 12 : 12.h),
                      itemBuilder: (context, index) {
                        final pur = purchases[index];
                        final dateStr = DateFormat(
                          'yyyy/MM/dd - hh:mm a',
                        ).format(pur.createdAt);

                        return Container(
                          padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 14 : 14.r,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors
                                              .inventoryPurchasePurple
                                              .withValues(alpha: 0.12),
                                          radius: isDesktop ? 20 : 20.r,
                                          child: Icon(
                                            Icons.receipt_rounded,
                                            color: AppColors
                                                .inventoryPurchasePurple,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: isDesktop ? 12 : 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${AppStrings.supplier.tr()}: ${pur.supplierName}',
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyles.customStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.blackReal,
                                                ),
                                              ),
                                              SizedBox(
                                                height: isDesktop ? 2 : 2.h,
                                              ),
                                              Text(
                                                dateStr,
                                                style: TextStyles.customStyle(
                                                  fontSize: 12,
                                                  color: AppColors.sandText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isDesktop ? 8 : 8.w),
                                  Text(
                                    '${pur.totalAmount.toSmartAmount()} ${AppStrings.egp.tr()}',
                                    style: TextStyles.customStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isDesktop ? 10 : 10.h),
                              const Divider(),
                              Column(
                                children: pur.items
                                    .map(
                                      (item) => Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isDesktop ? 10 : 10.w,
                                          vertical: isDesktop ? 6 : 6.h,
                                        ),
                                        margin: EdgeInsets.symmetric(
                                          vertical: isDesktop ? 3 : 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.scafoldBackGround
                                              .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          border: Border.all(
                                            color: AppColors.dividerColor
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: isDesktop ? 6 : 6.w,
                                              height: isDesktop ? 6 : 6.h,
                                              decoration: BoxDecoration(
                                                color: AppColors
                                                    .inventoryPurchasePurple,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(
                                              width: isDesktop ? 8 : 8.w,
                                            ),
                                            Expanded(
                                              child: Text(
                                                item.productName,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyles.customStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.blackReal,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: isDesktop ? 8 : 8.w,
                                            ),
                                            Text(
                                              '${item.quantity.toSmartAmount()} ${AppStrings.unit.tr()} × ${item.purchasePrice.toSmartAmount()}',
                                              style: TextStyles.customStyle(
                                                fontSize: 12,
                                                color: AppColors.sandText,
                                              ),
                                            ),
                                            SizedBox(
                                              width: isDesktop ? 8 : 8.w,
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isDesktop ? 6 : 6.w,
                                                vertical: isDesktop ? 2 : 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.success
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                '${item.subtotal.toSmartAmount()} ${AppStrings.egp.tr()}',
                                                style: TextStyles.customStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
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

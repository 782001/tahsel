import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../../domain/entities/stock_movement_entity.dart';
import '../cubits/inventory_stock_movements_cubit.dart';
import '../widgets/inventory_empty_state.dart';

class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryStockMovementsCubit>().fetchStockMovements();
  }

  Color _getMovementColor(StockMovementType type) {
    switch (type) {
      case StockMovementType.purchase:
        return AppColors.movementPurchase;
      case StockMovementType.invoiceSale:
        return AppColors.movementInvoiceSale;
      case StockMovementType.invoiceReturn:
        return AppColors.movementInvoiceReturn;
      case StockMovementType.manualAdjustment:
        return AppColors.movementManualAdjustment;
      case StockMovementType.purchaseReturn:
        return AppColors.movementPurchaseReturn;
    }
  }

  String _getMovementTitle(StockMovementType type) {
    switch (type) {
      case StockMovementType.purchase:
        return AppStrings.movementPurchase.tr();
      case StockMovementType.invoiceSale:
        return AppStrings.movementInvoiceSale.tr();
      case StockMovementType.invoiceReturn:
        return AppStrings.movementInvoiceReturn.tr();
      case StockMovementType.manualAdjustment:
        return AppStrings.movementManualAdjustment.tr();
      case StockMovementType.purchaseReturn:
        return AppStrings.movementPurchaseReturn.tr();
    }
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
          AppStrings.inventoryStockMovements.tr(),
          style: TextStyles.customStyle(
            fontSize: 22,
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
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
              child:
                  BlocBuilder<
                    InventoryStockMovementsCubit,
                    InventoryStockMovementsState
                  >(
                    builder: (context, state) {
                      if (state is InventoryStockMovementsLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                            strokeWidth: 4,
                          ),
                        );
                      }
                      if (state is InventoryStockMovementsLoaded) {
                        final movements = state.movements;

                        if (movements.isEmpty) {
                          return InventoryEmptyState(
                            icon: Icons.history_toggle_off_rounded,
                            title: AppStrings.noMovementsFound.tr(),
                            description: AppStrings.emptyStockMovementsDesc
                                .tr(),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: movements.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: isDesktop ? 12 : 12.h),
                          itemBuilder: (context, index) {
                            final m = movements[index];
                            final isPositive = m.quantity > 0;
                            final color = _getMovementColor(m.type);

                            return Container(
                              padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 14 : 14.r,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color.withValues(
                                      alpha: 0.12,
                                    ),
                                    radius: isDesktop ? 22 : 22.r,
                                    child: Icon(
                                      isPositive
                                          ? Icons.add_circle_outline
                                          : Icons.remove_circle_outline,
                                      color: color,
                                    ),
                                  ),
                                  SizedBox(width: isDesktop ? 14 : 14.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                m.productName,
                                                style: TextStyles.customStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.blackReal,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${isPositive ? '+' : ''}${m.quantity}',
                                              style: TextStyles.customStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isDesktop ? 4 : 4.h),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isDesktop ? 6 : 6.w,
                                                vertical: isDesktop ? 2 : 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                _getMovementTitle(m.type),
                                                style: TextStyles.customStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isDesktop ? 6 : 6.w,
                                                vertical: isDesktop ? 2 : 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.scafoldBackGround,
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                                border: Border.all(
                                                  color: AppColors.dividerColor,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${AppStrings.from.tr()} ${m.previousQuantity.toSmartAmount()}',
                                                    style:
                                                        TextStyles.customStyle(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .sandText,
                                                        ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 4.w,
                                                        ),
                                                    child: Icon(
                                                      AppStrings.currentLang ==
                                                              "ar"
                                                          ? Icons.west_rounded
                                                          : Icons.east_rounded,
                                                      size: 11,
                                                      color: AppColors.sandText,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${AppStrings.to.tr()} ${m.newQuantity.toSmartAmount()}',
                                                    style:
                                                        TextStyles.customStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .blackReal,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isDesktop ? 4 : 4.h),
                                        Text(
                                          DateFormat(
                                            'yyyy/MM/dd - hh:mm a',
                                          ).format(m.createdAt),
                                          style: TextStyles.customStyle(
                                            fontSize: 11,
                                            color: AppColors.sandText,
                                          ),
                                        ),
                                      ],
                                    ),
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

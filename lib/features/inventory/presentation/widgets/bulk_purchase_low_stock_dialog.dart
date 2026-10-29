import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_product_entity.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_purchase_entity.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_supplier_entity.dart';
import 'package:tahsel/features/inventory/presentation/cubits/inventory_products_cubit.dart';
import 'package:tahsel/features/inventory/presentation/cubits/inventory_purchases_cubit.dart';
import 'package:tahsel/features/inventory/presentation/cubits/inventory_suppliers_cubit.dart';
import 'package:tahsel/features/inventory/presentation/screens/create_purchase_screen.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

class _BulkPurchaseItemState {
  final InventoryProductEntity product;
  bool isSelected;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  _BulkPurchaseItemState({
    required this.product,
    required this.isSelected,
    required this.qtyController,
    required this.priceController,
  });

  double get quantity => double.tryParse(qtyController.text.trim()) ?? 0.0;
  double get price => double.tryParse(priceController.text.trim()) ?? 0.0;
  double get total => quantity * price;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}

class BulkPurchaseLowStockDialog extends StatefulWidget {
  final List<InventoryProductEntity> lowStockProducts;
  final List<InventorySupplierEntity>? suppliers;
  final VoidCallback onSuccess;

  const BulkPurchaseLowStockDialog({
    super.key,
    required this.lowStockProducts,
    this.suppliers,
    required this.onSuccess,
  });

  @override
  State<BulkPurchaseLowStockDialog> createState() =>
      _BulkPurchaseLowStockDialogState();
}

class _BulkPurchaseLowStockDialogState
    extends State<BulkPurchaseLowStockDialog> {
  final List<_BulkPurchaseItemState> _items = [];

  @override
  void initState() {
    super.initState();

    for (final p in widget.lowStockProducts) {
      final double neededQty = (p.minQuantity > p.currentQuantity)
          ? (p.minQuantity - p.currentQuantity)
          : (p.minQuantity > 0 ? p.minQuantity : 1.0);

      _items.add(
        _BulkPurchaseItemState(
          product: p,
          isSelected: true,
          qtyController: TextEditingController(
            text: (neededQty > 0 ? neededQty : 1.0).toSmartAmount(),
          ),
          priceController: TextEditingController(
            text: p.purchasePrice > 0 ? p.purchasePrice.toSmartAmount() : '0',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    double sum = 0.0;
    for (final item in _items) {
      if (item.isSelected) {
        sum += item.total;
      }
    }
    return sum;
  }

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  bool get _canSubmit {
    if (_items.isEmpty) return false;
    final selected = _items.where((i) => i.isSelected).toList();
    if (selected.isEmpty) return false;
    for (final item in selected) {
      if (item.quantity <= 0 || item.price < 0) return false;
    }
    return true;
  }

  void _adjustQty(_BulkPurchaseItemState item, double delta) {
    final current = item.quantity;
    final next = (current + delta).clamp(1.0, 999999.0);
    setState(() {
      item.qtyController.text = next.toSmartAmount();
    });
  }

  void _handleOpenInPurchaseScreen() {
    // 1. Permission condition
    if (!PermissionService.instance.hasPermission(
      AppPermissions.inventoryPurchases,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noPermissionForAction.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    // 2. Selection condition
    final selectedItems = _items.where((i) => i.isSelected).toList();
    if (selectedItems.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.pleaseAddAtLeastOneItem.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 3. Item-level validation conditions
    for (final item in selectedItems) {
      if (item.quantity <= 0 ||
          item.quantity.isNaN ||
          item.quantity.isInfinite) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${item.product.name}: ${AppStrings.validationQtyPositive.tr()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (item.price < 0 || item.price.isNaN || item.price.isInfinite) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${item.product.name}: ${AppStrings.validationPriceNonNegative.tr()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final purchaseItems = selectedItems.map((item) {
      return InventoryPurchaseItemEntity(
        productId: item.product.id,
        productName: item.product.name,
        quantity: item.quantity,
        purchasePrice: item.price,
        totalPrice: item.total,
        unit: item.product.unit.isNotEmpty ? item.product.unit : null,
      );
    }).toList();

    final purchasesCubit = context.read<InventoryPurchasesCubit>();
    final productsCubit = context.read<InventoryProductsCubit>();
    final suppliersCubit = context.read<InventorySuppliersCubit>();

    InventorySupplierEntity? initialSupplier;
    if (widget.suppliers != null && widget.suppliers!.isNotEmpty) {
      for (final item in selectedItems) {
        if (item.product.supplierId.isNotEmpty) {
          initialSupplier = widget.suppliers!
              .where((s) => s.id == item.product.supplierId)
              .firstOrNull;
          if (initialSupplier != null) break;
        }
      }
    }

    Navigator.of(context).pop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: purchasesCubit),
            BlocProvider.value(value: productsCubit),
            BlocProvider.value(value: suppliersCubit),
          ],
          child: CreatePurchaseScreen(
            initialItems: purchaseItems,
            initialSupplier: initialSupplier,
          ),
        ),
      ),
    ).then((_) {
      productsCubit.fetchProducts();
      widget.onSuccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isAllSelected = _items.isNotEmpty && _selectedCount == _items.length;
    final canSubmit = _canSubmit;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16.w,
        vertical: isDesktop ? 30 : 20.h,
      ),
      child: Center(
        child: Container(
          width: isDesktop ? 620 : double.infinity,
          constraints: BoxConstraints(
            maxHeight: isDesktop
                ? 680
                : MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Pinned Header
              Container(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 20 : 16.w,
                  isDesktop ? 16 : 14.h,
                  isDesktop ? 16 : 12.w,
                  isDesktop ? 14 : 12.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scafoldBackGround,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  AppStrings.buyLowStockProducts.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: isDesktop ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blackReal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  '${_items.length}',
                                  style: TextStyles.customStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            AppStrings.bulkPurchaseSubtitle.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              color: AppColors.sandText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.8),

              // 2. Scrollable Content Body
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(isDesktop ? 20 : 14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary & Select All Bar
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor.withValues(alpha: 0.08),
                              AppColors.primaryColor.withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: _items.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        final target = !isAllSelected;
                                        for (final i in _items) {
                                          i.isSelected = target;
                                        }
                                      });
                                    },
                              borderRadius: BorderRadius.circular(6.r),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: isAllSelected,
                                      activeColor: AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4.r),
                                      ),
                                      onChanged: _items.isEmpty
                                          ? null
                                          : (val) {
                                              setState(() {
                                                final target = val ?? false;
                                                for (final i in _items) {
                                                  i.isSelected = target;
                                                }
                                              });
                                            },
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    isAllSelected
                                        ? AppStrings.deselectAll.tr()
                                        : '${AppStrings.selectAll.tr()} ($_selectedCount/${_items.length})',
                                    style: TextStyles.customStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.blackReal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${_totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Items List (as in line 804)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final itemState = _items[index];
                          final p = itemState.product;

                          return Container(
                            padding: EdgeInsets.all(isDesktop ? 12 : 10.w),
                            decoration: BoxDecoration(
                              color: itemState.isSelected
                                  ? AppColors.surface
                                  : AppColors.scafoldBackGround
                                      .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: itemState.isSelected
                                    ? AppColors.primaryColor
                                    : Colors.grey.withValues(alpha: 0.18),
                                width: itemState.isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item Header
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: itemState.isSelected,
                                        activeColor: AppColors.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4.r),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            itemState.isSelected = val ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: TextStyles.customStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: itemState.isSelected
                                                  ? AppColors.blackReal
                                                  : AppColors.blackLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 3.h),
                                          Wrap(
                                            spacing: 4.w,
                                            runSpacing: 2.h,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 5.w,
                                                  vertical: 1.5.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (p.currentQuantity <= 0
                                                          ? AppColors.error
                                                          : AppColors.warning)
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    4.r,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${AppStrings.currentQuantity.tr()}: ${p.currentQuantity.toSmartAmount()}',
                                                  style: TextStyles.customStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: p.currentQuantity <=
                                                            0
                                                        ? AppColors.error
                                                        : AppColors.warning,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 5.w,
                                                  vertical: 1.5.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.sandText
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    4.r,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${AppStrings.minQuantity.tr()}: ${p.minQuantity.toSmartAmount()} ${p.unit}'
                                                      .trim(),
                                                  style: TextStyles.customStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.sandText,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '${itemState.total.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                                      style: TextStyles.customStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: itemState.isSelected
                                            ? AppColors.primaryColor
                                            : AppColors.blackLight,
                                      ),
                                    ),
                                  ],
                                ),

                                if (itemState.isSelected) ...[
                                  SizedBox(height: 10.h),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      // Quantity with Stepper
                                      Expanded(
                                        flex: 6,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.neededQuantity.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.blackLight,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Container(
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: AppColors.scafoldBackGround,
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                border: Border.all(
                                                  color: Colors.grey
                                                      .withValues(alpha: 0.25),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  InkWell(
                                                    onTap: () => _adjustQty(
                                                        itemState, -1),
                                                    borderRadius:
                                                        BorderRadius.horizontal(
                                                      right:
                                                          Radius.circular(8.r),
                                                    ),
                                                    child: Container(
                                                      width: 32,
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons.remove_rounded,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: itemState
                                                          .qtyController,
                                                      keyboardType:
                                                          const TextInputType
                                                              .numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyles
                                                          .customStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors.blackReal,
                                                      ),
                                                      decoration:
                                                          const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        isDense: true,
                                                      ),
                                                      onChanged: (_) {
                                                        setState(() {});
                                                      },
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () => _adjustQty(
                                                        itemState, 1),
                                                    borderRadius:
                                                        BorderRadius.horizontal(
                                                      left:
                                                          Radius.circular(8.r),
                                                    ),
                                                    child: Container(
                                                      width: 32,
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons.add_rounded,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      // Purchase Price
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.purchasePrice.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.blackLight,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            SizedBox(
                                              height: 42,
                                              child: QuickAddTextField(
                                                controller: itemState
                                                    .priceController,
                                                isNumber: true,
                                                hint: AppStrings.purchasePrice
                                                    .tr(),
                                                onChanged: (_) {
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, thickness: 0.8),

              // 3. Pinned Bottom Action (Open in Purchase Screen)
              Container(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 20 : 14.w,
                  10.h,
                  isDesktop ? 20 : 14.w,
                  isDesktop ? 16 : 14.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16.r),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canSubmit
                              ? AppColors.primaryColor
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: canSubmit ? 2 : 0,
                        ),
                        onPressed:
                            canSubmit ? _handleOpenInPurchaseScreen : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_cart_checkout_rounded,
                              size: 20,
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                '${AppStrings.openInPurchaseScreen.tr()} (${_totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()})',
                                style: TextStyles.customStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          AppStrings.cancel.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 12.5,
                            color: AppColors.sandText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

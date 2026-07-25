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
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    context.read<InventoryPurchasesCubit>().fetchPurchases();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.blackReal,
            
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDateRange = null;
    });
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
        scrolledUnderElevation: 0,
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

                    // Apply Search Query & Date Filter
                    final query = _searchController.text.trim().toLowerCase();
                    final filteredPurchases = purchases.where((pur) {
                      final matchesQuery =
                          query.isEmpty ||
                          pur.id.toLowerCase().contains(query) ||
                          pur.supplierName.toLowerCase().contains(query) ||
                          pur.items.any(
                            (item) =>
                                item.productName.toLowerCase().contains(query),
                          );

                      bool matchesDateRange = true;
                      if (_selectedDateRange != null) {
                        final start = DateTime(
                          _selectedDateRange!.start.year,
                          _selectedDateRange!.start.month,
                          _selectedDateRange!.start.day,
                          0,
                          0,
                          0,
                        );
                        final end = DateTime(
                          _selectedDateRange!.end.year,
                          _selectedDateRange!.end.month,
                          _selectedDateRange!.end.day,
                          23,
                          59,
                          59,
                        );
                        matchesDateRange =
                            pur.createdAt.isAfter(
                              start.subtract(const Duration(seconds: 1)),
                            ) &&
                            pur.createdAt.isBefore(
                              end.add(const Duration(seconds: 1)),
                            );
                      }

                      return matchesQuery && matchesDateRange;
                    }).toList();

                    return Column(
                      children: [
                        // Search & Date Range Filter Header
                        Container(
                          margin: EdgeInsets.only(
                            bottom: isDesktop ? 16 : 14.h,
                          ),
                          child: Column(
                            children: [
                              // Search TextField
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.blackLight.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  cursorColor: AppColors.primaryColor,
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
                                    color: AppColors.blackReal,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: AppStrings.searchInvoiceHint.tr(),
                                    hintStyle: TextStyles.customStyle(
                                      fontSize: 13,
                                      color: AppColors.sandText,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: AppColors.primaryColor,
                                    ),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear_rounded,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _searchController.clear(),
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              // Date Filter Button Row
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _pickDateRange(context),
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 10.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedDateRange != null
                                              ? AppColors
                                                    .inventoryPurchasePurple
                                                    .withValues(alpha: 0.12)
                                              : AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                          border: Border.all(
                                            color: _selectedDateRange != null
                                                ? AppColors
                                                      .inventoryPurchasePurple
                                                : AppColors.dividerColor,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.date_range_rounded,
                                              size: 18,
                                              color: _selectedDateRange != null
                                                  ? AppColors
                                                        .inventoryPurchasePurple
                                                  : AppColors.primaryColor,
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                _selectedDateRange != null
                                                    ? '${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}'
                                                    : AppStrings
                                                          .selectDatePeriod
                                                          .tr(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyles.customStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      _selectedDateRange != null
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color:
                                                      _selectedDateRange != null
                                                      ? AppColors
                                                            .inventoryPurchasePurple
                                                      : AppColors.sandText,
                                                ),
                                              ),
                                            ),
                                            if (_selectedDateRange != null)
                                              GestureDetector(
                                                onTap: () => setState(
                                                  () =>
                                                      _selectedDateRange = null,
                                                ),
                                                child: Icon(
                                                  Icons.cancel_rounded,
                                                  size: 16,
                                                  color: AppColors
                                                      .inventoryPurchasePurple,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty ||
                                      _selectedDateRange != null) ...[
                                    SizedBox(width: 8.w),
                                    InkWell(
                                      onTap: _clearFilters,
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 10.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                          border: Border.all(
                                            color: AppColors.error.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.refresh_rounded,
                                              size: 16,
                                              color: AppColors.error,
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              AppStrings.clearFilter.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Filtered Invoices List
                        Expanded(
                          child: filteredPurchases.isEmpty
                              ? InventoryEmptyState(
                                  icon: Icons.search_off_rounded,
                                  title: AppStrings.noResults.tr(),
                                  description: AppStrings.noPurchasesFound.tr(),
                                  actionLabel: AppStrings.clearFilter.tr(),
                                  onAction: _clearFilters,
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredPurchases.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: isDesktop ? 12 : 12.h),
                                  itemBuilder: (context, index) {
                                    final pur = filteredPurchases[index];
                                    final dateStr = DateFormat(
                                      'yyyy/MM/dd - hh:mm a',
                                    ).format(pur.createdAt);

                                    return Container(
                                      padding: EdgeInsets.all(
                                        isDesktop ? 16 : 16.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(
                                          isDesktop ? 14 : 14.r,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      radius: isDesktop
                                                          ? 20
                                                          : 20.r,
                                                      child: Icon(
                                                        Icons.receipt_rounded,
                                                        color: AppColors
                                                            .inventoryPurchasePurple,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: isDesktop
                                                          ? 12
                                                          : 12.w,
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      6.w,
                                                                  vertical: 2.h,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: AppColors
                                                                  .inventoryPurchasePurple
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6.r,
                                                                  ),
                                                              border: Border.all(
                                                                color: AppColors
                                                                    .inventoryPurchasePurple
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              '#${pur.id.replaceAll('pur_', '')}',
                                                              style: TextStyles.customStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: AppColors
                                                                    .inventoryPurchasePurple,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: isDesktop
                                                                ? 6
                                                                : 6.h,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  '${AppStrings.supplier.tr()}: ${pur.supplierName}',
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: TextStyles.customStyle(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: AppColors
                                                                        .blackReal,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                            height: isDesktop
                                                                ? 4
                                                                : 4.h,
                                                          ),
                                                          Text(
                                                            dateStr,
                                                            style:
                                                                TextStyles.customStyle(
                                                                  fontSize: 12,
                                                                  color: AppColors
                                                                      .sandText,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                width: isDesktop ? 8 : 8.w,
                                              ),
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
                                          SizedBox(
                                            height: isDesktop ? 10 : 10.h,
                                          ),
                                          Divider(
                                            color: AppColors.disabledColor
                                                .withValues(alpha: 0.1),
                                          ),
                                          Column(
                                            children: pur.items
                                                .map(
                                                  (item) => Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: isDesktop
                                                              ? 10
                                                              : 10.w,
                                                          vertical: isDesktop
                                                              ? 6
                                                              : 6.h,
                                                        ),
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                          vertical: isDesktop
                                                              ? 3
                                                              : 3.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .scafoldBackGround
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: isDesktop
                                                              ? 6
                                                              : 6.w,
                                                          height: isDesktop
                                                              ? 6
                                                              : 6.h,
                                                          decoration: BoxDecoration(
                                                            color: AppColors
                                                                .inventoryPurchasePurple,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: isDesktop
                                                              ? 8
                                                              : 8.w,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            item.productName,
                                                            maxLines: 3,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyles.customStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .blackReal,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: isDesktop
                                                              ? 8
                                                              : 8.w,
                                                        ),
                                                        Text(
                                                          '${item.quantity.toSmartAmount()} ${AppStrings.unit.tr()} × ${item.purchasePrice.toSmartAmount()}',
                                                          style:
                                                              TextStyles.customStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .sandText,
                                                              ),
                                                        ),
                                                        SizedBox(
                                                          width: isDesktop
                                                              ? 8
                                                              : 8.w,
                                                        ),
                                                        Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    isDesktop
                                                                    ? 6
                                                                    : 6.w,
                                                                vertical:
                                                                    isDesktop
                                                                    ? 2
                                                                    : 2.h,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppColors
                                                                .success
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4.r,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            '${item.subtotal.toSmartAmount()} ${AppStrings.egp.tr()}',
                                                            style:
                                                                TextStyles.customStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: AppColors
                                                                      .success,
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
                                ),
                        ),
                      ],
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

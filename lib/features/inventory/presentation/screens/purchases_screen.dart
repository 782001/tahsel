import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/invoice_pdf_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_purchase_entity.dart';

import '../cubits/inventory_products_cubit.dart';
import '../cubits/inventory_purchases_cubit.dart';
import '../cubits/inventory_suppliers_cubit.dart';
import '../widgets/inventory_empty_state.dart';
import '../widgets/purchase_card_item.dart';
import '../widgets/purchase_card_skeleton.dart';
import '../widgets/purchase_search_bar.dart';
import 'create_purchase_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTimeRange? _selectedDateRange;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    context.read<InventoryPurchasesCubit>().fetchPurchases();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty || _selectedDateRange != null) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InventoryPurchasesCubit>().fetchMorePurchases();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _printPurchasePdf(InventoryPurchaseEntity pur) async {
    final isArabic = AppStrings.currentLang == 'ar';
    try {
      await InvoicePdfService.printPurchaseInvoice(
        context,
        pur,
        isArabic: isArabic,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sharePurchasePdf(InventoryPurchaseEntity pur) async {
    final isArabic = AppStrings.currentLang == 'ar';
    try {
      await InvoicePdfService.sharePurchaseInvoicePdf(pur, isArabic: isArabic);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.errorSharingInvoice.tr()}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _downloadPurchasePdf(InventoryPurchaseEntity pur) async {
    final isArabic = AppStrings.currentLang == 'ar';
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await InvoicePdfService.savePurchasePdfToStorage(
        purchase: pur,
        isArabic: isArabic,
      );
      if (file != null && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.invoiceSavedSuccessfully.tr()}\n${file.path}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${AppStrings.errorSavingInvoice.tr()}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _editPurchase(InventoryPurchaseEntity pur) {
    final purchasesCubit = context.read<InventoryPurchasesCubit>();
    final productsCubit = context.read<InventoryProductsCubit>();
    final suppliersCubit = context.read<InventorySuppliersCubit>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: purchasesCubit),
            BlocProvider.value(value: productsCubit),
            BlocProvider.value(value: suppliersCubit),
          ],
          child: CreatePurchaseScreen(initialPurchase: pur),
        ),
      ),
    );
    if (mounted) {
      purchasesCubit.fetchPurchases();
      productsCubit.fetchProducts();
    }
  }

  void _reorderPurchase(InventoryPurchaseEntity pur) {
    final purchasesCubit = context.read<InventoryPurchasesCubit>();
    final productsCubit = context.read<InventoryProductsCubit>();
    final suppliersCubit = context.read<InventorySuppliersCubit>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: purchasesCubit),
            BlocProvider.value(value: productsCubit),
            BlocProvider.value(value: suppliersCubit),
          ],
          child: CreatePurchaseScreen(initialPurchase: pur, isReorder: true),
        ),
      ),
    );
    if (mounted) {
      purchasesCubit.fetchPurchases();
      productsCubit.fetchProducts();
    }
  }

  void _navigateToCreatePurchase() {
    final purchasesCubit = context.read<InventoryPurchasesCubit>();
    final productsCubit = context.read<InventoryProductsCubit>();
    final suppliersCubit = context.read<InventorySuppliersCubit>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: purchasesCubit),
            BlocProvider.value(value: productsCubit),
            BlocProvider.value(value: suppliersCubit),
          ],
          child: const CreatePurchaseScreen(),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePurchase(InventoryPurchaseEntity pur) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          AppStrings.confirmDelete.tr(),
          style: TextStyles.customStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Text(
          AppStrings.confirmDeletePurchaseWarning.tr(),
          style: TextStyles.customStyle(
            fontSize: 14,
            color: AppColors.blackReal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(color: AppColors.blackLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppStrings.confirmDelete.tr(),
              style: TextStyles.customStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      final purchasesCubit = context.read<InventoryPurchasesCubit>();
      final productsCubit = context.read<InventoryProductsCubit>();
      final messenger = ScaffoldMessenger.of(context);

      try {
        final success = await purchasesCubit.deletePurchase(pur);
        if (success && mounted) {
          await productsCubit.fetchProducts();
          messenger.showSnackBar(
            SnackBar(
              content: Text(AppStrings.deletedSuccessfully.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
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
      body: Stack(
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1000 : double.infinity,
                ),
                child: RefreshIndicator(
                  color: AppColors.primaryColor,
                  onRefresh: () async {
                    _clearFilters();
                    await context
                        .read<InventoryPurchasesCubit>()
                        .fetchPurchases();
                  },
                  child: BlocBuilder<InventoryPurchasesCubit,
                      InventoryPurchasesState>(
                    builder: (context, state) {
                      // Apply Search & Date Filters
                      final query = _searchController.text.trim().toLowerCase();
                      final isFiltering =
                          query.isNotEmpty || _selectedDateRange != null;

                      List<InventoryPurchaseEntity> filteredPurchases = [];
                      if (state is InventoryPurchasesLoaded) {
                        final sourceList = isFiltering
                            ? state.allPurchases
                            : state.purchases;

                        filteredPurchases = sourceList.where((p) {
                          final matchesSearch = query.isEmpty ||
                              p.supplierName.toLowerCase().contains(query) ||
                              p.id.toLowerCase().contains(query) ||
                              p.items.any(
                                (i) =>
                                    i.productName.toLowerCase().contains(query),
                              );

                          final matchesDate = _selectedDateRange == null ||
                              (p.createdAt.isAfter(
                                    _selectedDateRange!.start.subtract(
                                      const Duration(days: 1),
                                    ),
                                  ) &&
                                  p.createdAt.isBefore(
                                    _selectedDateRange!.end.add(
                                      const Duration(days: 1),
                                    ),
                                  ));

                          return matchesSearch && matchesDate;
                        }).toList();
                      }

                      return CustomScrollView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          // ── Floating & Snapping App Bar with SearchBar ──────
                          SliverAppBar(
                            floating: true,
                            snap: true,
                            elevation: 0,
                            scrolledUnderElevation: 0,
                            backgroundColor: AppColors.scafoldBackGround,
                            automaticallyImplyLeading: false,
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
                            bottom: PreferredSize(
                              preferredSize: Size.fromHeight(60.h),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 16.w,
                                  vertical: isDesktop ? 8 : 6.h,
                                ),
                                child: PurchaseSearchBar(
                                  searchController: _searchController,
                                  selectedDateRange: _selectedDateRange,
                                  onSelectDateRange: () =>
                                      _pickDateRange(context),
                                  onClearFilters: _clearFilters,
                                ),
                              ),
                            ),
                          ),

                          // ── Body Content ──────────────────────────────────
                          if (state is InventoryPurchasesLoading)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 24 : 16.w,
                                vertical: 12.h,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (_, __) => const PurchaseCardSkeleton(),
                                  childCount: 6,
                                ),
                              ),
                            )
                          else if (state is InventoryPurchasesError)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: InventoryEmptyState(
                                icon: Icons.error_outline_rounded,
                                title: AppStrings.noResults.tr(),
                                description: state.message,
                                actionLabel: AppStrings.tryAgain.tr(),
                                onAction: () => context
                                    .read<InventoryPurchasesCubit>()
                                    .fetchPurchases(),
                              ),
                            )
                          else if (state is InventoryPurchasesLoaded &&
                              state.purchases.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: InventoryEmptyState(
                                icon: Icons.shopping_bag_outlined,
                                title: AppStrings.noPurchasesFound.tr(),
                                description: AppStrings.emptyPurchasesDesc.tr(),
                                actionLabel: AppStrings.newPurchase.tr(),
                                onAction: _navigateToCreatePurchase,
                              ),
                            )
                          else if (state is InventoryPurchasesLoaded &&
                              filteredPurchases.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: InventoryEmptyState(
                                icon: Icons.search_off_rounded,
                                title: AppStrings.noResults.tr(),
                                description: AppStrings.noPurchasesFound.tr(),
                                actionLabel: AppStrings.tryAgain.tr(),
                                onAction: _clearFilters,
                              ),
                            )
                          else if (state is InventoryPurchasesLoaded)
                            SliverPadding(
                              padding: EdgeInsets.only(
                                left: isDesktop ? 24 : 16.w,
                                right: isDesktop ? 24 : 16.w,
                                top: 12.h,
                                bottom: 80.h,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index == filteredPurchases.length) {
                                      return const PurchaseCardSkeleton();
                                    }
                                    final pur = filteredPurchases[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isDesktop ? 12 : 12.h,
                                      ),
                                      child: PurchaseCardItem(
                                        purchase: pur,
                                        onPrintPdf: () =>
                                            _printPurchasePdf(pur),
                                        onSharePdf: () =>
                                            _sharePurchasePdf(pur),
                                        onDownloadPdf: () =>
                                            _downloadPurchasePdf(pur),
                                        onReorder: () =>
                                            _reorderPurchase(pur),
                                        onEdit: () => _editPurchase(pur),
                                        onDelete: () =>
                                            _confirmDeletePurchase(pur),
                                      ),
                                    );
                                  },
                                  childCount: filteredPurchases.length +
                                      (!isFiltering &&
                                              state.isPaginationLoading
                                          ? 1
                                          : 0),
                                ),
                              ),
                            )
                          else
                            const SliverToBoxAdapter(
                              child: SizedBox.shrink(),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_isDeleting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 28 : 24.w,
                      vertical: isDesktop ? 22 : 18.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3.5,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          AppStrings.deletingPurchase.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

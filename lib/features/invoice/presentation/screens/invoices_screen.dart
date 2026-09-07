import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_state.dart';
import 'package:tahsel/features/invoice/presentation/widgets/empty_invoices_view.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_card.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_card_skeleton.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_search_bar.dart';
import 'package:tahsel/features/invoice/presentation/widgets/offline_empty_invoices_view.dart';
import 'package:tahsel/features/offline_sync/presentation/cubit/offline_sync_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/routes/app_routes.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<InvoiceCubit>().fetchInvoices(uid);
    }
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
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
    context.read<InvoiceCubit>().search('');
  }

  void _onScroll() {
    if (_searchController.text.trim().isNotEmpty ||
        _selectedDateRange != null) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<InvoiceCubit>().fetchMoreInvoices(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OfflineSyncCubit, OfflineSyncState>(
          listener: (context, state) {
            if (state is OfflineSyncSuccess) {
              context.read<InvoiceCubit>().fetchInvoices(AppStrings.userToken);
            }
          },
        ),
      ],
      child: SafeArea(
        child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
          builder: (context, connectivityState) {
            final isDisconnected =
                connectivityState is ConnectivityDisconnected;
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: () async {
                      _clearFilters();
                      await context.read<InvoiceCubit>().fetchInvoices(
                        AppStrings.userToken,
                        forceRefresh: true,
                      );
                    },
                    child: BlocBuilder<InvoiceCubit, InvoiceState>(
                      builder: (context, state) {
                        if (state is InvoiceFailure) {
                          AppLogger.printMessage(state.message);
                        }

                        final rawInvoices = state is InvoiceListLoaded
                            ? state.filtered
                            : <InvoiceEntity>[];

                        // Filter by Date Range if selected
                        final invoices = rawInvoices.where((inv) {
                          if (_selectedDateRange == null) return true;
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
                          return inv.createdAt.isAfter(
                                start.subtract(const Duration(seconds: 1)),
                              ) &&
                              inv.createdAt.isBefore(
                                end.add(const Duration(seconds: 1)),
                              );
                        }).toList();

                        final isFiltering =
                            _searchController.text.trim().isNotEmpty ||
                            _selectedDateRange != null;
                        final hasMore =
                            state is InvoiceListLoaded && state.hasMore;
                        final isPaginationLoading =
                            state is InvoiceListLoaded &&
                            state.isPaginationLoading;

                        return CustomScrollView(
                          controller: _scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            // ── Floating & Snapping App Bar + Search Bar ──────
                            SliverAppBar(
                              floating: true,
                              snap: true,
                              elevation: 0,
                              scrolledUnderElevation: 0,
                              backgroundColor: AppColors.scafoldBackGround,
                              automaticallyImplyLeading: false,
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.invoices.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppColors.primaryColor,
                                    size: 26,
                                  ),
                                ],
                              ),
                              bottom: PreferredSize(
                                preferredSize: Size.fromHeight(60.h),
                                child: InvoiceSearchBar(
                                  controller: _searchController,
                                  onChanged: (q) =>
                                      context.read<InvoiceCubit>().search(q),
                                  selectedDateRange: _selectedDateRange,
                                  onSelectDateRange: () =>
                                      _pickDateRange(context),
                                  onClearFilters: _clearFilters,
                                ),
                              ),
                            ),

                            // ── Body Slivers ───────────────────────────────────
                            if (state is InvoiceLoading)
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, __) => const InvoiceCardSkeleton(),
                                    childCount: 6,
                                  ),
                                ),
                              )
                            else if (state is InvoiceFailure)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Text(
                                    state.message,
                                    style: TextStyles.customStyle(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              )
                            else if (invoices.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: isDisconnected
                                      ? const OfflineEmptyInvoicesView()
                                      : (isFiltering
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.search_off_rounded,
                                                    size: 64.r,
                                                    color:
                                                        AppColors.disabledColor,
                                                  ),
                                                  SizedBox(height: 12.h),
                                                  Text(
                                                    AppStrings.noResults.tr(),
                                                    style:
                                                        TextStyles.customStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .blackLight,
                                                        ),
                                                  ),
                                                  SizedBox(height: 6.h),
                                                  Text(
                                                    AppStrings.noPurchasesFound
                                                        .tr(),
                                                    style:
                                                        TextStyles.customStyle(
                                                          fontSize: 13,
                                                          color: AppColors
                                                              .disabledColor,
                                                        ),
                                                  ),
                                                  SizedBox(height: 14.h),
                                                ],
                                              )
                                            : const EmptyInvoicesView()),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      if (index == invoices.length) {
                                        return const InvoiceCardSkeleton();
                                      }
                                      final isPending =
                                          state is InvoiceListLoaded &&
                                          state.pendingSyncIds.contains(
                                            invoices[index].id,
                                          );

                                      return InvoiceCard(
                                        invoice: invoices[index],
                                        isPendingSync: isPending,
                                        onTap: () => _openDetail(
                                          context,
                                          invoices[index],
                                        ),
                                      );
                                    },
                                    childCount:
                                        invoices.length +
                                        (!isFiltering &&
                                                (hasMore || isPaginationLoading)
                                            ? 1
                                            : 0),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // ── Create Buttons (Invoice & Quotation) ───────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  child: Row(
                    children: [
                      // Create Invoice Button
                      Expanded(
                        child: SizedBox(
                          height: 56.h,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleCreate(isQuotation: false),
                            icon: Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.whiteColor,
                              size: 20,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.createInvoice.tr(),
                                style: TextStyles.customStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Create Quotation Button
                      Expanded(
                        child: SizedBox(
                          height: 56.h,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleCreate(isQuotation: true),
                            icon: Icon(
                              Icons.request_quote_rounded,
                              color: AppColors.whiteColor,
                              size: 20,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.createQuotation.tr(),
                                style: TextStyles.customStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.movementInvoiceReturn,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleCreate({required bool isQuotation}) async {
    final cubit = context.read<InvoiceCubit>();
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.createInvoice,
      arguments: {'isQuotation': isQuotation},
    );

    if (!mounted) return;

    if (result is Map<String, dynamic> && result.containsKey('invoice')) {
      // ignore: use_build_context_synchronously
      await Navigator.of(
        context,
      ).pushNamed(AppRoutes.invoiceDetail, arguments: result);
    }

    // Refresh list after returning from create or detail screen
    if (!mounted) return;
    _clearFilters();
    cubit.fetchInvoices(AppStrings.userToken, forceRefresh: true);
  }

  void _openDetail(BuildContext context, InvoiceEntity invoice) async {
    final cubit = context.read<InvoiceCubit>();
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.invoiceDetail, arguments: invoice);
    if (!mounted) return;
    _clearFilters();
    // Force a fresh server read so updated/voided status is always visible.
    cubit.fetchInvoices(AppStrings.userToken, forceRefresh: true);
  }
}

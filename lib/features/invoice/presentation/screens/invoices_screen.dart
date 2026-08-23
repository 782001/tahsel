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
import 'package:tahsel/features/invoice/presentation/widgets/invoice_search_bar.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoices_app_bar.dart';
import 'package:tahsel/features/invoice/presentation/widgets/offline_empty_invoices_view.dart';
import 'package:tahsel/features/offline_sync/presentation/cubit/offline_sync_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';

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
      initialDateRange: _selectedDateRange ??
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
            return RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async {
                _clearFilters();
                await context.read<InvoiceCubit>().fetchInvoices(
                  AppStrings.userToken,
                  forceRefresh: true,
                );
              },
              child: Column(
                children: [
                  // ── App Bar ─────────────────────────────────────────────────
                  const InvoicesAppBar(),

                  // ── Unified Search & Date Filter Bar ────────────────────────
                  InvoiceSearchBar(
                    controller: _searchController,
                    onChanged: (q) => context.read<InvoiceCubit>().search(q),
                    selectedDateRange: _selectedDateRange,
                    onSelectDateRange: () => _pickDateRange(context),
                    onClearFilters: _clearFilters,
                  ),
                  SizedBox(height: 4.h),

                  // ── Body ────────────────────────────────────────────────────
                  Expanded(
                    child: BlocBuilder<InvoiceCubit, InvoiceState>(
                      builder: (context, state) {
                        if (state is InvoiceLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          );
                        }

                        if (state is InvoiceFailure) {
                          AppLogger.printMessage(state.message);
                          return Center(
                            child: Text(
                              state.message,
                              style: TextStyles.customStyle(
                                color: AppColors.error,
                              ),
                            ),
                          );
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

                        final hasMore =
                            state is InvoiceListLoaded && state.hasMore;
                        final isPaginationLoading =
                            state is InvoiceListLoaded &&
                            state.isPaginationLoading;

                        if (invoices.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: isDisconnected
                                    ? const OfflineEmptyInvoicesView()
                                    : const EmptyInvoicesView(),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          itemCount:
                              invoices.length +
                              (hasMore || isPaginationLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == invoices.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            }
                            final isPending =
                                state is InvoiceListLoaded &&
                                state.pendingSyncIds.contains(
                                  invoices[index].id,
                                );

                            return InvoiceCard(
                              invoice: invoices[index],
                              isPendingSync: isPending,
                              onTap: () =>
                                  _openDetail(context, invoices[index]),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Create Button ────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    child: QuickActionButton(
                      label: AppStrings.createInvoice.tr(),
                      icon: Icons.receipt_long_rounded,
                      onPressed: () async {
                        final cubit = context.read<InvoiceCubit>();
                        final result = await Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.createInvoice);

                        if (!mounted) return;

                        if (result is Map<String, dynamic> &&
                            result.containsKey('invoice')) {
                          // ignore: use_build_context_synchronously
                          await Navigator.of(context).pushNamed(
                            AppRoutes.invoiceDetail,
                            arguments: result,
                          );
                        }

                        // Refresh list after returning from create or detail screen
                        if (!mounted) return;
                        _clearFilters();
                        cubit.fetchInvoices(
                          AppStrings.userToken,
                          forceRefresh: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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

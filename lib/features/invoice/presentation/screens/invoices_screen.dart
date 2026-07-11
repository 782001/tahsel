import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_state.dart';
import 'package:tahsel/features/offline_sync/presentation/cubit/offline_sync_cubit.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<InvoiceCubit>().fetchInvoices(uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        child: RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () async {
            _searchController.clear();
            await context.read<InvoiceCubit>().fetchInvoices(
              AppStrings.userToken,
              forceRefresh: true,
            );
          },
          child: Column(
            children: [
              // ── App Bar ─────────────────────────────────────────────────
              _InvoicesAppBar(),

              // ── Search Bar ──────────────────────────────────────────────
              _SearchBar(
                controller: _searchController,
                onChanged: (q) => context.read<InvoiceCubit>().search(q),
              ),

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
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyles.customStyle(color: AppColors.error),
                        ),
                      );
                    }

                    final invoices = state is InvoiceListLoaded
                        ? state.filtered
                        : <InvoiceEntity>[];

                    final hasMore = state is InvoiceListLoaded && state.hasMore;
                    final isPaginationLoading =
                        state is InvoiceListLoaded && state.isPaginationLoading;

                    if (invoices.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: _EmptyInvoicesView(),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                                strokeWidth: 3,
                              ),
                            ),
                          );
                        }
                        return _InvoiceCard(
                          invoice: invoices[index],
                          onTap: () => _openDetail(context, invoices[index]),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Create Button ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: QuickActionButton(
                  label: AppStrings.createInvoice.tr(),
                  icon: Icons.receipt_long_rounded,
                  onPressed: () async {
                    final cubit = context.read<InvoiceCubit>();
                    await Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.createInvoice);
                    // Refresh list after returning from create screen
                    if (!mounted) return;
                    _searchController.clear();
                    cubit.fetchInvoices(AppStrings.userToken);
                  },
                ),
              ),
            ],
          ),
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
    _searchController.clear();
    // Force a fresh server read so updated/voided status is always visible.
    cubit.fetchInvoices(AppStrings.userToken, forceRefresh: true);
  }
}

// ── Search Bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: AppColors.primaryColor,
        style: TextStyles.customStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: AppStrings.searchInvoices.tr(),
          hintStyle: TextStyles.customStyle(
            color: AppColors.disabledColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primaryColor,
            size: 22,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.disabledColor,
                    size: 20,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── App Bar ─────────────────────────────────────────────────────────────────

class _InvoicesAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.invoices.tr(),
            style: TextStyles.customStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          Icon(
            Icons.receipt_long_rounded,
            color: AppColors.primaryColor,
            size: 28,
          ),
        ],
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyInvoicesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: AppColors.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.invoicesEmpty.tr(),
            style: TextStyles.customStyle(
              fontSize: 16,
              color: AppColors.blackLight,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.invoicesEmptyDesc.tr(),
            style: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Invoice Card ─────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.onTap});

  Color _statusColor() {
    switch (invoice.status) {
      case InvoiceStatus.paid:
        return AppColors.success;
      case InvoiceStatus.partial:
        return AppColors.warning;
      case InvoiceStatus.voided:
        return AppColors.error;
      case InvoiceStatus.pending:
        return AppColors.info;
    }
  }

  String _statusLabel() {
    switch (invoice.status) {
      case InvoiceStatus.paid:
        return AppStrings.invoiceStatusPaid.tr();
      case InvoiceStatus.partial:
        return AppStrings.invoiceStatusPartial.tr();
      case InvoiceStatus.voided:
        return AppStrings.invoiceStatusVoided.tr();
      case InvoiceStatus.pending:
        return AppStrings.invoiceStatusPending.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: const [AppColors.shadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName ??
                              AppStrings.walkingCustomer.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        if (invoice.ledgerNumber != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '# ${invoice.ledgerNumber}',
                            style: TextStyles.customStyle(
                              fontSize: 12,
                              color: AppColors.blackLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Amount Row ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AmountColumn(
                    label: AppStrings.totalDueLabel.tr(),
                    value: invoice.totalAmount,
                    color: AppColors.black,
                  ),
                  _AmountColumn(
                    label: AppStrings.paidAmount.tr(),
                    value: invoice.totalPaid,
                    color: AppColors.success,
                  ),
                  _AmountColumn(
                    label: AppStrings.remainingDebt.tr(),
                    value: invoice.remainingAmount,
                    color: invoice.remainingAmount > 0
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Date + Arrow ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(invoice.createdAt),
                    style: TextStyles.customStyle(
                      fontSize: 11,
                      color: AppColors.disabledColor,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.disabledColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AmountColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 11,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

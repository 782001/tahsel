import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_history_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_state.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_history_timeline.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceEntity invoice;
  final bool showPaymentImmediately;

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
    this.showPaymentImmediately = false,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late InvoiceEntity _invoice;

  /// Debt payment transactions fetched via [InvoiceCubit.loadInvoice].
  /// Non-null only when the invoice has a [linkedDebtId].
  List<PaymentEntity>? _debtTransactions;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    // Always fetch the latest invoice data from the server when the screen
    // opens so the payments list and status are never stale (e.g., after a
    // payment edit/delete in the Debt module).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InvoiceCubit>().loadInvoice(
          AppStrings.userToken,
          _invoice.id,
        );
        context.read<InvoiceHistoryCubit>().loadHistory(
          uid: AppStrings.userToken,
          invoiceId: _invoice.id,
        );
      }
    });
    if (widget.showPaymentImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showRecordPaymentSheet(context, false);
        }
      });
    }
  }

  void _showRecordPaymentSheet(BuildContext context, bool isDismissible) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<InvoiceCubit>(),
        child: _RecordPaymentSheet(invoice: _invoice, onSuccess: () {}),
      ),
    );
  }

  Color _statusColor(InvoiceStatus status) {
    switch (status) {
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

  String _statusLabel(InvoiceStatus status) {
    switch (status) {
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

  Future<void> _confirmVoid(BuildContext context) async {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) return;
    final cubit = context.read<InvoiceCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppStrings.invoiceVoidConfirmTitle.tr(),
          style: TextStyles.customStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: Text(
          AppStrings.invoiceVoidConfirmBody.tr(),
          style: TextStyles.customStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppStrings.invoiceVoid.tr(),
              style: TextStyles.customStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      cubit.voidInvoice(AppStrings.userToken, _invoice.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return BlocListener<InvoiceCubit, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceDetailLoaded) {
          setState(() {
            _invoice = state.invoice;
            _debtTransactions = state.debtTransactions;
          });
        } else if (state is InvoicePaymentSuccess) {
          final uid = AppStrings.userToken;
          context.read<InvoiceCubit>().loadInvoice(uid, _invoice.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.invoicePaymentSuccess.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is InvoiceUpdateSuccess) {
          // Reload the freshest data after an edit
          final uid = AppStrings.userToken;
          context.read<InvoiceCubit>().loadInvoice(uid, _invoice.id);
          // Reload history to reflect the new entries
          context.read<InvoiceHistoryCubit>().loadHistory(
            uid: uid,
            invoiceId: _invoice.id,
          );
        } else if (state is InvoiceVoidSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.invoiceVoidSuccess.tr()),
              backgroundColor: AppColors.warning,
            ),
          );
          // Reload to reflect voided status
          final uid = AppStrings.userToken;
          context.read<InvoiceCubit>().loadInvoice(uid, _invoice.id);
        } else if (state is InvoiceFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          final isDisconnected = connectivityState is ConnectivityDisconnected;
          return Scaffold(
            backgroundColor: AppColors.scafoldBackGround,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              title: Text(
                AppStrings.invoiceDetail.tr(),
                style: TextStyles.customStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primaryColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // Edit — only for non-voided invoices
                if (_invoice.status != InvoiceStatus.voided)
                  IconButton(
                    icon: Icon(
                      Icons.edit_square,
                      color: isDisconnected ? AppColors.disabledColor : AppColors.primaryColor,
                    ),
                    tooltip: AppStrings.invoiceEditTitle.tr(),
                    onPressed: () async {
                      if (isDisconnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.noInternetConnection.tr()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      final cubit = context.read<InvoiceCubit>();
                      final updated = await Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.editInvoice, arguments: _invoice);
                      if (updated == true && mounted) {
                        cubit.loadInvoice(AppStrings.userToken, _invoice.id);
                      }
                    },
                  ),
                // Void — only for pending/partial invoices
                if (_invoice.status == InvoiceStatus.pending ||
                    _invoice.status == InvoiceStatus.partial)
                  IconButton(
                    icon: Icon(
                      Icons.cancel_presentation,
                      color: isDisconnected ? AppColors.disabledColor : AppColors.error,
                    ),
                    tooltip: AppStrings.invoiceVoid.tr(),
                    onPressed: () {
                      if (isDisconnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.noInternetConnection.tr()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      _confirmVoid(context);
                    },
                  ),
              ],
            ),
            body: isDisconnected
                ? NoInternetView(
                    onRetry: () =>
                        context.read<ConnectivityCubit>().checkConnectivity(),
                  )
                : SafeArea(
                    child: BlocBuilder<InvoiceCubit, InvoiceState>(
            builder: (context, state) {
              final isLoading = state is InvoiceLoading;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1000 : double.infinity,
                  ),

                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 20.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Status Card ────────────────────────────────────
                            _StatusCard(
                              invoice: _invoice,
                              statusColor: _statusColor(_invoice.status),
                              statusLabel: _statusLabel(_invoice.status),
                            ),
                            const SizedBox(height: 20),

                            // ── Customer Info ──────────────────────────────────
                            if (_invoice.customerName != null ||
                                _invoice.customerPhone != null ||
                                _invoice.linkedDebtId != null) ...[
                              _SectionTitle(
                                title: AppStrings.invoiceCustomerSection.tr(),
                              ),
                              const SizedBox(height: 12),
                              _InfoCard(
                                children: [
                                  if (_invoice.customerName != null)
                                    _InfoRow(
                                      icon: Icons.person_rounded,
                                      label: _invoice.customerName!,
                                    ),
                                  if (_invoice.customerPhone != null)
                                    _InfoRow(
                                      icon: Icons.phone_rounded,
                                      label: _invoice.customerPhone!,
                                    ),
                                  if (_invoice.ledgerNumber != null)
                                    _InfoRow(
                                      icon: Icons.tag_rounded,
                                      label: '# ${_invoice.ledgerNumber}',
                                    ),
                                  if (_invoice.linkedDebtId != null)
                                    _InfoRow(
                                      icon: Icons.link_rounded,
                                      label:
                                          '${AppStrings.invoiceLinkedToDebt.tr()}: ${_invoice.linkedDebtId}',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // ── Items ──────────────────────────────────────────
                            _SectionTitle(
                              title: AppStrings.invoiceItemsSectionDetail.tr(),
                            ),
                            const SizedBox(height: 12),
                            _ItemsCard(items: _invoice.items),
                            const SizedBox(height: 20),

                            // ── Payment Summary ────────────────────────────────
                            _PaymentSummaryCard(invoice: _invoice),
                            const SizedBox(height: 20),
                            if (_invoice.status == InvoiceStatus.voided)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.info.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: AppColors.info,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "${AppStrings.invoiceVoidNotice.tr()}   ${_invoice.totalPaid.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                          style: TextStyles.customStyle(
                                            fontSize: 12,
                                            color: AppColors.info,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),
                            if (_invoice.status == InvoiceStatus.paid &&
                                _invoice.totalPaid > _invoice.totalAmount)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.info.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: AppColors.info,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "${AppStrings.invoicePaidNotice.tr()}   ${(_invoice.totalPaid - _invoice.totalAmount).toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                          style: TextStyles.customStyle(
                                            fontSize: 12,
                                            color: AppColors.info,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),

                            // ── Edit History Timeline ─────────────────────
                            _SectionTitle(
                              title: AppStrings.invoiceHistory.tr(),
                            ),
                            const SizedBox(height: 12),
                            const InvoiceHistoryTimeline(),
                            const SizedBox(height: 20),

                            // ── Payment History ────────────────────────────────
                            _SectionTitle(
                              title: AppStrings.invoicePaymentHistory.tr(),
                            ),
                            const SizedBox(height: 12),
                            // If linked to a debt, use debt transactions as the
                            // authoritative payment history; otherwise fallback
                            // to the invoice's own payments array.
                            if (_debtTransactions != null &&
                                _debtTransactions!.isNotEmpty)
                              _DebtPaymentHistoryList(
                                transactions: _debtTransactions!,
                              )
                            else
                              _PaymentHistoryList(payments: _invoice.payments),
                            const SizedBox(height: 20),

                            // ── Notes ──────────────────────────────────────────
                            if (_invoice.notes?.isNotEmpty == true) ...[
                              _SectionTitle(
                                title: AppStrings.invoiceNotesSection.tr(),
                              ),
                              const SizedBox(height: 8),
                              _InfoCard(
                                children: [
                                  _InfoRow(
                                    icon: Icons.notes_rounded,
                                    label: _invoice.notes!,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // ── Record Payment Button ──────────────────────────
                            if (_invoice.status != InvoiceStatus.paid &&
                                _invoice.status != InvoiceStatus.voided)
                              _RecordPaymentButton(
                                onTap: isLoading
                                    ? null
                                    : () => _showRecordPaymentSheet(
                                        context,
                                        true,
                                      ),
                              ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                      if (isLoading)
                        Container(
                          color: Colors.black.withValues(alpha: 0.3),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      },
    ),
    );
  }
}

// ── Sub widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyles.customStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyles.customStyle(
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final Color statusColor;
  final String statusLabel;

  const _StatusCard({
    required this.invoice,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.75)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.customerName ?? AppStrings.walkingCustomer.tr(),
                style: TextStyles.customStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${invoice.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
            style: TextStyles.customStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(invoice.createdAt),
            style: TextStyles.customStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _PaymentSummaryCard extends StatelessWidget {
  final InvoiceEntity invoice;
  const _PaymentSummaryCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryColumn(
            label: AppStrings.totalDueLabel.tr(),
            amount: invoice.totalAmount,
            color: AppColors.black,
          ),
          Container(width: 1, height: 40, color: AppColors.dividerColor),
          _SummaryColumn(
            label: AppStrings.invoiceTotalPaid.tr(),
            amount: invoice.totalPaid,
            color: AppColors.success,
          ),
          Container(width: 1, height: 40, color: AppColors.dividerColor),
          _SummaryColumn(
            label: AppStrings.invoiceRemainingAmount.tr(),
            amount: invoice.remainingAmount,
            color: invoice.remainingAmount > 0
                ? AppColors.error
                : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          amount.toSmartAmount(),
          style: TextStyles.customStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final List<InvoiceItem> items;
  const _ItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.dividerColor),
        itemBuilder: (context, i) {
          final item = items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.quantity.toSmartAmount()} × ${item.unitPrice.toSmartAmount()}',
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.blackLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.total.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
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
    );
  }
}

class _PaymentHistoryList extends StatelessWidget {
  final List<InvoicePayment> payments;
  const _PaymentHistoryList({required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Center(
          child: Text(
            AppStrings.invoiceNoPayments.tr(),
            style: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.disabledColor,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payments.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.dividerColor),
        itemBuilder: (context, i) {
          // Show newest payments first
          final payment = payments[payments.length - 1 - i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${payment.amount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      if (payment.note?.isNotEmpty == true)
                        Text(
                          payment.note!,
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            color: AppColors.blackLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(payment.paidAt),
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    color: AppColors.disabledColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

/// Shows payment history sourced directly from the linked Debt's payments
/// sub-collection — ensures the invoice detail always reflects the live data.
class _DebtPaymentHistoryList extends StatelessWidget {
  final List<PaymentEntity> transactions;
  const _DebtPaymentHistoryList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Filter to actual payment entries (exclude internal "debtAdded" marker)
    final payments =
        transactions
            .where(
              (t) =>
                  t.type != PaymentType.debtAdded &&
                  t.type != PaymentType.reversal,
            )
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );

    if (payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Center(
          child: Text(
            AppStrings.invoiceNoPayments.tr(),
            style: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.disabledColor,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payments.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.dividerColor),
        itemBuilder: (context, i) {
          final p = payments[i];
          final isSettlement = p.type == PaymentType.settlement;
          final color = p.type == PaymentType.adjustment
              ? AppColors.warning
              : AppColors.success;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSettlement
                        ? Icons.check_circle_rounded
                        : Icons.payments_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.amountPaid.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (p.activityName?.isNotEmpty == true)
                        Text(
                          p.activityName!,
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            color: AppColors.blackLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  p.createdAt != null ? _fmt(p.createdAt!) : '',
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    color: AppColors.disabledColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _RecordPaymentButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _RecordPaymentButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_card_rounded, color: Colors.white),
        label: Text(
          AppStrings.invoiceRecordPayment.tr(),
          style: TextStyles.customStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppColors.primaryColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ── Record Payment Bottom Sheet ─────────────────────────────────────────────

class _RecordPaymentSheet extends StatefulWidget {
  final InvoiceEntity invoice;
  final VoidCallback onSuccess;

  const _RecordPaymentSheet({required this.invoice, required this.onSuccess});

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // amount may be 0 — that means full-debt with no cash collected right now.
    if (amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invoicePaymentValidation.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (amount > widget.invoice.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invoicePaymentExceedsRemaining.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final uid = AppStrings.userToken;
    // Debt is created automatically inside recordPayment when remaining > 0.
    context.read<InvoiceCubit>().recordPayment(
      uid: uid,
      invoiceId: widget.invoice.id,
      invoice: widget.invoice,
      paidNow: amount,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );

    Navigator.of(context).pop();
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.invoice.remainingAmount;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            AppStrings.invoiceRecordPayment.tr(),
            style: TextStyles.customStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.invoiceRemainingAmount.tr()}: ${remaining.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
            style: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.blackLight,
            ),
          ),
          const SizedBox(height: 20),

          // Amount field
          _SheetField(
            controller: _amountController,
            label: AppStrings.invoicePaymentAmount.tr(),
            hint: '0.00',
            isNumber: true,
            suffix: AppStrings.currencyEgp.tr(),
          ),
          const SizedBox(height: 12),

          // Note field
          _SheetField(
            controller: _noteController,
            label: AppStrings.invoicePaymentNote.tr(),
            hint: AppStrings.invoicePaymentNoteHint.tr(),
          ),
          const SizedBox(height: 24),

          // Info banner: auto-debt notice when amount < remaining
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.invoiceAutoDebtNotice.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submit(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppStrings.confirm.tr(),
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isNumber;
  final String? suffix;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isNumber = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          cursorColor: AppColors.primaryColor,
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyles.customStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.customStyle(color: AppColors.disabledColor),
            suffixText: suffix,
            suffixStyle: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.blackLight,
            ),
            filled: true,
            fillColor: AppColors.veryLightGrey,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart' as di;
import 'package:tahsel/core/services/invoice_pdf_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/utils/summary_helper.dart';
import 'package:tahsel/core/utils/vault_balance_helper.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/cashbox/data/datasources/vault_remote_data_source.dart';
import 'package:tahsel/features/cashbox/domain/entities/vault_transaction_entity.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_history_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_state.dart';
import 'package:tahsel/features/invoice/presentation/widgets/debt_payment_history_list.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_history_timeline.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_info_card.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_info_row.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_items_card.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_payment_history_list.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_section_title.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_status_card.dart';
import 'package:tahsel/features/invoice/presentation/widgets/payment_summary_card.dart';
import 'package:tahsel/features/invoice/presentation/widgets/phone_input_sheet.dart';
import 'package:tahsel/features/invoice/presentation/widgets/record_payment_button.dart';
import 'package:tahsel/features/invoice/presentation/widgets/record_payment_sheet.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

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
        child: RecordPaymentSheet(invoice: _invoice, onSuccess: () {}),
      ),
    );
  }

  bool _isRefunding = false;

  Future<void> _handleRefundToCustomer() async {
    final connectivityState = context.read<ConnectivityCubit>().state;
    if (connectivityState is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }

    final amountToRefund = _invoice.totalPaid;
    if (amountToRefund <= 0) return;

    // Pre-check Vault balance
    if (AppStrings.isVaultEnabled()) {
      final vaultSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(AppStrings.userToken)
          .collection('vault')
          .doc('summary')
          .get();
      if (!mounted) return;
      final double currentVaultBalance =
          (vaultSnap.exists && vaultSnap.data() != null)
          ? ((vaultSnap.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0)
          : 0.0;
      if (currentVaultBalance < amountToRefund) {
        VaultBalanceHelper.showInsufficientBalanceDialog(context);
        return;
      }
    }

    if (!mounted) return;

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final double radius = isDesktop ? 20 : 20.r;
    final double titleFontSize = isDesktop ? 16 : 16.sp;
    final double smallFontSize = isDesktop ? 12 : 12.sp;
    final double iconSize = isDesktop ? 22 : 22.sp;
    final double paddingVal = isDesktop ? 20 : 20.w;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        backgroundColor: AppColors.surface,
        contentPadding: EdgeInsets.all(paddingVal),
        titlePadding: EdgeInsets.fromLTRB(
          paddingVal,
          paddingVal,
          paddingVal,
          0,
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          paddingVal,
          0,
          paddingVal,
          paddingVal,
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 8 : 8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.error,
                size: iconSize,
              ),
            ),
            SizedBox(width: isDesktop ? 12 : 12.w),
            Expanded(
              child: Text(
                AppStrings.refundConfirmationTitle.tr(),
                textAlign: TextAlign.center,
                style: TextStyles.customStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isDesktop ? 340 : 280,
            maxWidth: isDesktop ? 440 : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isDesktop ? 16 : 16.h),

              // Smart Financial Summary Breakdown Card
              Container(
                padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            AppStrings.customerNameLabel.tr(),
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              color: AppColors.subTitleColor,
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Flexible(
                          child: Text(
                            _invoice.customerName ??
                                AppStrings.unspecifiedCustomer.tr(),
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 8 : 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.amountDeductedFromVault.tr(),
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              color: AppColors.subTitleColor,
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 8.w,
                            vertical: isDesktop ? 4 : 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 8 : 8.r,
                            ),
                          ),
                          child: Text(
                            '- ${amountToRefund.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 16.w,
                  vertical: isDesktop ? 10 : 10.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                ),
              ),
              icon: Icon(
                Icons.output_rounded,
                size: isDesktop ? 18 : 18.sp,
                color: Colors.white,
              ),
              label: Text(
                textAlign: TextAlign.center,
                AppStrings.refundToCustomer.tr(),
                style: TextStyles.customStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                textAlign: TextAlign.center,
                AppStrings.cancel.tr(),
                style: TextStyles.customStyle(
                  fontSize: 14,
                  color: AppColors.subTitleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRefunding = true);

    try {
      final uid = AppStrings.userToken;

      // Vault Balance Check
      if (AppStrings.isVaultEnabled() && amountToRefund > 0) {
        final vaultSummaryRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('vault')
            .doc('summary');
        final vaultSnap = await vaultSummaryRef.get();
        final double currentVaultBalance =
            (vaultSnap.exists && vaultSnap.data() != null)
            ? ((vaultSnap.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        if (currentVaultBalance < amountToRefund) {
          if (mounted) {
            setState(() => _isRefunding = false);
            VaultBalanceHelper.showInsufficientBalanceDialog(context);
          }
          return;
        }
      }

      await VaultRemoteDataSourceImpl.syncVaultTransaction(
        uid: uid,
        transactionId: 'vault_tx_refund_${_invoice.id}',
        amount: amountToRefund,
        direction: VaultTransactionDirection.outFlow,
        source: VaultTransactionSource.customerDebt,
        type: 'invoice_refund',
        description:
            'إرجاع مبلغ فاتورة ملغاة: #${_invoice.id} للعميل: ${_invoice.customerName ?? ""}',
        relatedEntityId: _invoice.id,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users/$uid/invoices')
          .doc(_invoice.id)
          .set({'isRefundedToCustomer': true}, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isRefunding = false;
          _invoice = _invoice.copyWith(isRefundedToCustomer: true);
        });

        showSuccessToast(AppStrings.refundSuccess.tr());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefunding = false);
        if (e.toString().contains(AppStrings.insufficientBalance) ||
            e.toString().contains('insufficient_balance')) {
          VaultBalanceHelper.showInsufficientBalanceDialog(context);
        } else {
          showfailureToast(e.toString());
        }
      }
    }
  }

  Future<void> _handleRefundOverpaidSurplus() async {
    final connectivityState = context.read<ConnectivityCubit>().state;
    if (connectivityState is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }

    final surplus = _invoice.totalPaid - _invoice.totalAmount;
    if (surplus <= 0) return;

    // Pre-check Vault balance
    if (AppStrings.isVaultEnabled()) {
      final vaultSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(AppStrings.userToken)
          .collection('vault')
          .doc('summary')
          .get();
      if (!mounted) return;
      final double currentVaultBalance =
          (vaultSnap.exists && vaultSnap.data() != null)
          ? ((vaultSnap.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0)
          : 0.0;
      if (currentVaultBalance < surplus) {
        VaultBalanceHelper.showInsufficientBalanceDialog(context);
        return;
      }
    }

    if (!mounted) return;

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final double radius = isDesktop ? 20 : 20.r;
    final double titleFontSize = isDesktop ? 16 : 16.sp;
    final double smallFontSize = isDesktop ? 12 : 12.sp;
    final double iconSize = isDesktop ? 22 : 22.sp;
    final double paddingVal = isDesktop ? 20 : 20.w;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        backgroundColor: AppColors.surface,
        contentPadding: EdgeInsets.all(paddingVal),
        titlePadding: EdgeInsets.fromLTRB(
          paddingVal,
          paddingVal,
          paddingVal,
          0,
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          paddingVal,
          0,
          paddingVal,
          paddingVal,
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 8 : 8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.error,
                size: iconSize,
              ),
            ),
            SizedBox(width: isDesktop ? 12 : 12.w),
            Expanded(
              child: Text(
                AppStrings.confirmRefundOverpaid.tr(),
                style: TextStyles.customStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isDesktop ? 340 : 280,
            maxWidth: isDesktop ? 440 : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isDesktop ? 16 : 16.h),

              // Smart Financial Summary Breakdown Card
              Container(
                padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            AppStrings.customerNameLabel.tr(),
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              color: AppColors.subTitleColor,
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Flexible(
                          child: Text(
                            _invoice.customerName ??
                                AppStrings.unspecifiedCustomer.tr(),
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 8 : 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.amountDeductedFromVault.tr(),
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              color: AppColors.subTitleColor,
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 8.w,
                            vertical: isDesktop ? 4 : 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 8 : 8.r,
                            ),
                          ),
                          child: Text(
                            '- ${surplus.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 16.w,
                  vertical: isDesktop ? 10 : 10.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                ),
              ),
              icon: Icon(
                Icons.output_rounded,
                size: isDesktop ? 18 : 18.sp,
                color: Colors.white,
              ),
              label: Text(
                AppStrings.refundOverpaidToCustomer.tr(),
                style: TextStyles.customStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                AppStrings.cancel.tr(),
                style: TextStyles.customStyle(
                  fontSize: 14,
                  color: AppColors.subTitleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRefunding = true);

    try {
      final uid = AppStrings.userToken;

      // Vault Balance Check
      if (AppStrings.isVaultEnabled() && surplus > 0) {
        final vaultSummaryRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('vault')
            .doc('summary');
        final vaultSnap = await vaultSummaryRef.get();
        final double currentVaultBalance =
            (vaultSnap.exists && vaultSnap.data() != null)
            ? ((vaultSnap.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        if (currentVaultBalance < surplus) {
          if (mounted) {
            setState(() => _isRefunding = false);
            VaultBalanceHelper.showInsufficientBalanceDialog(context);
          }
          return;
        }
      }

      // 1. Record Vault Outflow
      await VaultRemoteDataSourceImpl.syncVaultTransaction(
        uid: uid,
        transactionId: 'vault_tx_refund_overpaid_${_invoice.id}',
        amount: surplus,
        direction: VaultTransactionDirection.outFlow,
        source: VaultTransactionSource.customerDebt,
        type: 'invoice_overpaid_refund',
        description:
            'إرجاع فائض مدفوعات فاتورة: #${_invoice.id} للعميل: ${_invoice.customerName ?? ""}',
        relatedEntityId: _invoice.id,
        createdAt: DateTime.now(),
      );

      final batch = FirebaseFirestore.instance.batch();

      // 2. Update Invoice document
      final invoiceRef = FirebaseFirestore.instance
          .collection('users/$uid/invoices')
          .doc(_invoice.id);
      batch.set(invoiceRef, {
        'syncedTotalPaid': _invoice.totalAmount,
        'isRefundedToCustomer': true,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Update Linked Debt if any
      final linkedDebtId = _invoice.linkedDebtId ?? 'debt_inv_${_invoice.id}';
      final debtRef = FirebaseFirestore.instance
          .collection('users/$uid/debts')
          .doc(linkedDebtId);
      final debtDoc = await debtRef.get();
      if (debtDoc.exists) {
        batch.update(debtRef, {
          'paidAmount': _invoice.totalAmount,
          'remainingAmount': 0.0,
          'isPaid': true,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });

        final paymentRef = debtRef.collection('payments').doc();
        batch.set(paymentRef, {
          'uid': uid,
          'debtId': linkedDebtId,
          'amountPaid': -surplus,
          'remainingAmount': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'settlement',
          'relatedTo': _invoice.customerName ?? '',
          'activityName': 'إرجاع فائض مدفوعات الفاتورة للعميل',
        });
      }

      // 4. Update Summary collections
      final allTimeSummaryRef = FirebaseFirestore.instance
          .collection('users/$uid/summaries')
          .doc(SummaryHelper.getAllTimeKey());
      batch.set(allTimeSummaryRef, {
        'totalCollected': FieldValue.increment(-surplus),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final monthlySummaryRef = FirebaseFirestore.instance
          .collection('users/$uid/summaries')
          .doc(SummaryHelper.getMonthlyKey(DateTime.now()));
      batch.set(monthlySummaryRef, {
        'totalCollected': FieldValue.increment(-surplus),
        'isHealed': false,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      if (mounted) {
        setState(() {
          _isRefunding = false;
          _invoice = _invoice.copyWith(
            syncedTotalPaid: _invoice.totalAmount,
            isRefundedToCustomer: true,
          );
        });

        showSuccessToast(AppStrings.refundCreditSuccess.tr());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefunding = false);
        if (e.toString().contains(AppStrings.insufficientBalance) ||
            e.toString().contains('insufficient_balance')) {
          VaultBalanceHelper.showInsufficientBalanceDialog(context);
        } else {
          showfailureToast(e.toString());
        }
      }
    }
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
      case InvoiceStatus.quotation:
        return AppColors.primaryColor;
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
      case InvoiceStatus.quotation:
        return AppStrings.invoiceStatusQuotation.tr();
    }
  }

  Future<void> _confirmVoid(BuildContext context) async {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      return;
    }
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
      cubit.voidInvoice(
        AppStrings.userToken,
        _invoice.id,
        invoice: _invoice,
      );
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
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.surface,
              elevation: 0,
              title: Text(
                _invoice.isQuotation
                    ? AppStrings.quotationDetails.tr()
                    : AppStrings.invoiceDetail.tr(),
                style: TextStyles.customStyle(
                  fontSize: 16,
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
                // Print Invoice / Quotation
                IconButton(
                  icon: Icon(
                    Icons.print_rounded,
                    color: AppColors.primaryColor,
                  ),
                  tooltip: _invoice.isQuotation
                      ? AppStrings.printQuotation.tr()
                      : AppStrings.printInvoice.tr(),
                  onPressed: () async {
                    try {
                      final isArabic = AppStrings.currentLang == 'ar';
                      await InvoicePdfService.printInvoice(
                        context,
                        _invoice,
                        isArabic: isArabic,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                // Share as PDF
                IconButton(
                  icon: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: isDisconnected
                        ? AppColors.disabledColor
                        : AppColors.primaryColor,
                  ),
                  tooltip: _invoice.isQuotation
                      ? AppStrings.shareQuotationPdf.tr()
                      : AppStrings.invoiceSharePdf.tr(),
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

                    String? phone = _invoice.customerPhone;
                    if (!kIsWeb && Platform.isAndroid) {
                      if (phone == null || phone.isEmpty) {
                        final result = await PhoneInputSheet.show(context);
                        if (result == null) return;
                        phone = result;

                        if (_invoice.customerName != null) {
                          try {
                            di.sl<CustomerCubit>().updateCustomerPhone(
                              AppStrings.userToken,
                              _invoice.customerName!,
                              phone,
                            );
                          } catch (e) {
                            AppLogger.printMessage(
                              'Failed to update customer phone: $e',
                            );
                          }
                        }

                        // Save the phone number to the invoice document
                        // ignore: use_build_context_synchronously
                        context.read<InvoiceCubit>().updateInvoice(
                          _invoice.copyWith(customerPhone: phone),
                          previous: _invoice,
                        );
                      }
                    }

                    try {
                      final isArabic = AppStrings.currentLang == 'ar';
                      await InvoicePdfService.generateAndShareInvoice(
                        _invoice,
                        isArabic: isArabic,
                        phoneNumber: phone,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        AppLogger.printMessage(
                          'Failed to generate and share invoice: $e',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                // Edit — only for non-voided invoices
                if (_invoice.status != InvoiceStatus.voided)
                  IconButton(
                    icon: Icon(
                      Icons.edit_square,
                      color: isDisconnected
                          ? AppColors.disabledColor
                          : AppColors.primaryColor,
                    ),
                    tooltip: _invoice.isQuotation
                        ? AppStrings.editQuotation.tr()
                        : AppStrings.invoiceEditTitle.tr(),
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
                // Void — only for pending/partial invoices (never quotations)
                if (!_invoice.isQuotation &&
                    (_invoice.status == InvoiceStatus.pending ||
                        _invoice.status == InvoiceStatus.partial))
                  IconButton(
                    icon: Icon(
                      Icons.cancel_presentation,
                      color: isDisconnected
                          ? AppColors.disabledColor
                          : AppColors.error,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Status Card ────────────────────────────────────
                                      InvoiceStatusCard(
                                        invoice: _invoice,
                                        statusColor: _statusColor(
                                          _invoice.status,
                                        ),
                                        statusLabel: _statusLabel(
                                          _invoice.status,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // ── Customer Info ──────────────────────────────────
                                      if (_invoice.customerName != null ||
                                          _invoice.customerPhone != null ||
                                          _invoice.linkedDebtId != null) ...[
                                        InvoiceSectionTitle(
                                          title: AppStrings
                                              .invoiceCustomerSection
                                              .tr(),
                                        ),
                                        const SizedBox(height: 12),
                                        InvoiceInfoCard(
                                          children: [
                                            if (_invoice.customerName != null)
                                              InvoiceInfoRow(
                                                icon: Icons.person_rounded,
                                                label: _invoice.customerName!,
                                              ),
                                            if (_invoice.customerPhone != null)
                                              InvoiceInfoRow(
                                                icon: Icons.phone_rounded,
                                                label: _invoice.customerPhone!,
                                              ),
                                            if (_invoice.ledgerNumber != null)
                                              InvoiceInfoRow(
                                                icon: Icons.tag_rounded,
                                                label:
                                                    '# ${_invoice.ledgerNumber}',
                                              ),
                                            if (_invoice.linkedDebtId != null)
                                              InvoiceInfoRow(
                                                icon: Icons.link_rounded,
                                                label:
                                                    '${AppStrings.invoiceLinkedToDebt.tr()}: ${_invoice.linkedDebtId}',
                                              ),
                                            if (_invoice.dueDate != null)
                                              InvoiceInfoRow(
                                                icon: Icons
                                                    .event_available_rounded,
                                                label:
                                                    '${AppStrings.paymentDueDate.tr()}: ${DateFormat('yyyy/MM/dd').format(_invoice.dueDate!)}',
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                      ],

                                      // ── Items ──────────────────────────────────────────
                                      InvoiceSectionTitle(
                                        title: AppStrings
                                            .invoiceItemsSectionDetail
                                            .tr(),
                                      ),
                                      const SizedBox(height: 12),
                                      InvoiceItemsCard(items: _invoice.items),
                                      const SizedBox(height: 20),

                                      // ── Overall Cash Discount Card ─────────────
                                      if (_invoice.totalDiscountAmount > 0) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.orange.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: AppColors.orange
                                                  .withValues(alpha: 0.3),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.orange
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.local_offer_rounded,
                                                      color: AppColors.orange,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    AppStrings
                                                        .overallDiscountAmount
                                                        .tr(),
                                                    style:
                                                        TextStyles.customStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              AppColors.black,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '-${_invoice.totalDiscountAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                                                style: TextStyles.customStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],

                                      // ── Payment Summary ────────────────────────────────
                                      if (!_invoice.isQuotation) ...[
                                        PaymentSummaryCard(invoice: _invoice),
                                        const SizedBox(height: 20),
                                      ],
                                      if (!_invoice.isQuotation &&
                                          _invoice.status ==
                                              InvoiceStatus.paid &&
                                          _invoice.totalPaid >
                                              _invoice.totalAmount)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              isDesktop ? 14 : 14.w,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.info.withValues(
                                                alpha: 0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    isDesktop ? 14 : 14.r,
                                                  ),
                                              border: Border.all(
                                                color: AppColors.info
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .info_outline_rounded,
                                                      size: isDesktop
                                                          ? 18
                                                          : 18.sp,
                                                      color: AppColors.info,
                                                    ),
                                                    SizedBox(
                                                      width: isDesktop
                                                          ? 8
                                                          : 8.w,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        "${AppStrings.invoicePaidNotice.tr()}   ${(_invoice.totalPaid - _invoice.totalAmount).toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                                        style:
                                                            TextStyles.customStyle(
                                                              fontSize: 12,
                                                              color: AppColors
                                                                  .info,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: isDesktop ? 10 : 10.h,
                                                ),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    onPressed: _isRefunding
                                                        ? null
                                                        : () =>
                                                              _handleRefundOverpaidSurplus(),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          AppColors.info,
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 0,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                isDesktop
                                                                ? 14
                                                                : 14.w,
                                                            vertical: isDesktop
                                                                ? 8
                                                                : 8.h,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              isDesktop
                                                                  ? 10
                                                                  : 10.r,
                                                            ),
                                                      ),
                                                    ),
                                                    icon: _isRefunding
                                                        ? SizedBox(
                                                            width: isDesktop
                                                                ? 16
                                                                : 16.sp,
                                                            height: isDesktop
                                                                ? 16
                                                                : 16.sp,
                                                            child:
                                                                const CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          )
                                                        : Icon(
                                                            Icons
                                                                .output_rounded,
                                                            size: isDesktop
                                                                ? 18
                                                                : 18.sp,
                                                            color: Colors.white,
                                                          ),
                                                    label: Text(
                                                      AppStrings
                                                          .refundOverpaidToCustomer
                                                          .tr(),
                                                      style:
                                                          TextStyles.customStyle(
                                                            fontSize: 12,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (!_invoice.isQuotation &&
                                          _invoice.status ==
                                              InvoiceStatus.voided &&
                                          _invoice.totalPaid > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.info.withValues(
                                                alpha: 0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.info
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .info_outline_rounded,
                                                      size: 18,
                                                      color: AppColors.info,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        AppStrings
                                                            .invoiceVoidNotice
                                                            .tr(),
                                                        style:
                                                            TextStyles.customStyle(
                                                              fontSize: 12,
                                                              color: AppColors
                                                                  .info,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (_invoice.totalPaid > 0) ...[
                                                  const SizedBox(height: 10),
                                                  _invoice.isRefundedToCustomer
                                                      ? Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 8,
                                                                horizontal: 12,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppColors
                                                                .success
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.r,
                                                                ),
                                                            border: Border.all(
                                                              color: AppColors
                                                                  .success
                                                                  .withValues(
                                                                    alpha: 0.4,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .check_circle_rounded,
                                                                color: AppColors
                                                                    .success,
                                                                size: isDesktop
                                                                    ? 18
                                                                    : 18.sp,
                                                              ),
                                                              SizedBox(
                                                                width: isDesktop
                                                                    ? 8
                                                                    : 8.w,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  AppStrings
                                                                      .refundAlreadyDone
                                                                      .tr(),
                                                                  style: TextStyles.customStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: AppColors
                                                                        .success,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: ElevatedButton.icon(
                                                            onPressed:
                                                                _isRefunding
                                                                ? null
                                                                : () =>
                                                                      _handleRefundToCustomer(),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  AppColors
                                                                      .error,
                                                              foregroundColor:
                                                                  Colors.white,
                                                              elevation: 2,
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        isDesktop
                                                                        ? 12
                                                                        : 12.h,
                                                                    horizontal:
                                                                        isDesktop
                                                                        ? 16
                                                                        : 16.w,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12.r,
                                                                    ),
                                                              ),
                                                            ),
                                                            icon: _isRefunding
                                                                ? SizedBox(
                                                                    width:
                                                                        isDesktop
                                                                        ? 18
                                                                        : 18.sp,
                                                                    height:
                                                                        isDesktop
                                                                        ? 18
                                                                        : 18.sp,
                                                                    child: const CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  )
                                                                : Icon(
                                                                    Icons
                                                                        .output_rounded,
                                                                    size:
                                                                        isDesktop
                                                                        ? 18
                                                                        : 18.sp,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                            label: Center(
                                                              child: Text(
                                                                AppStrings
                                                                    .refundToCustomer
                                                                    .tr(),
                                                                style: TextStyles.customStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 20),

                                      // ── Edit History Timeline ─────────────────────
                                      InvoiceSectionTitle(
                                        title: AppStrings.invoiceHistory.tr(),
                                      ),
                                      const SizedBox(height: 12),
                                      const InvoiceHistoryTimeline(),
                                      const SizedBox(height: 20),

                                      // ── Payment History ────────────────────────────────
                                      if (!_invoice.isQuotation) ...[
                                        InvoiceSectionTitle(
                                          title: AppStrings
                                              .invoicePaymentHistory
                                              .tr(),
                                        ),
                                        const SizedBox(height: 12),
                                        // If linked to a debt, use debt transactions as the
                                        // authoritative payment history; otherwise fallback
                                        // to the invoice's own payments array.
                                        if (_debtTransactions != null &&
                                            _debtTransactions!.isNotEmpty)
                                          DebtPaymentHistoryList(
                                            transactions: _debtTransactions!,
                                          )
                                        else
                                          InvoicePaymentHistoryList(
                                            payments: _invoice.payments,
                                          ),
                                        const SizedBox(height: 20),
                                      ],

                                      // ── Notes ──────────────────────────────────────────
                                      if (_invoice.notes?.isNotEmpty ==
                                          true) ...[
                                        InvoiceSectionTitle(
                                          title: AppStrings.invoiceNotesSection
                                              .tr(),
                                        ),
                                        const SizedBox(height: 8),
                                        InvoiceInfoCard(
                                          children: [
                                            InvoiceInfoRow(
                                              icon: Icons.notes_rounded,
                                              label: _invoice.notes!,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                      ],

                                      // ── Record Payment Button ──────────────────────────
                                      if (!_invoice.isQuotation &&
                                          _invoice.status !=
                                              InvoiceStatus.paid &&
                                          _invoice.status !=
                                              InvoiceStatus.voided)
                                        RecordPaymentButton(
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
                                        strokeWidth: 4,
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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart' as di;
import 'package:tahsel/core/services/invoice_pdf_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
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
              scrolledUnderElevation: 0,
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
                // Share as PDF
                IconButton(
                  icon: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.primaryColor,
                  ),
                  tooltip: AppStrings.invoiceSharePdf.tr(),
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
                      // showDialog(
                      //   // ignore: use_build_context_synchronously
                      //   context: context,
                      //   barrierDismissible: false,
                      //   builder: (context) =>  Center(
                      //     child: CircularProgressIndicator(color: AppColors.primaryColor,
                      //     strokeWidth: 4,
                      //     ),
                      //   ),
                      // );

                      final isArabic = AppStrings.currentLang == 'ar';
                      await InvoicePdfService.generateAndShareInvoice(
                        _invoice,
                        isArabic: isArabic,
                        phoneNumber: phone,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
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
                                      if (_invoice.discountAmount > 0) ...[
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
                                              color: AppColors.orange.withValues(
                                                alpha: 0.3,
                                              ),
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
                                                    style: TextStyles
                                                        .customStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .black,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '-${_invoice.discountAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
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
                                      PaymentSummaryCard(invoice: _invoice),
                                      const SizedBox(height: 20),
                                      if (_invoice.status ==
                                          InvoiceStatus.voided)
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
                                                    style:
                                                        TextStyles.customStyle(
                                                          fontSize: 12,
                                                          color: AppColors.info,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      if (_invoice.status ==
                                              InvoiceStatus.paid &&
                                          _invoice.totalPaid >
                                              _invoice.totalAmount)
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
                                                    style:
                                                        TextStyles.customStyle(
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
                                      InvoiceSectionTitle(
                                        title: AppStrings.invoiceHistory.tr(),
                                      ),
                                      const SizedBox(height: 12),
                                      const InvoiceHistoryTimeline(),
                                      const SizedBox(height: 20),

                                      // ── Payment History ────────────────────────────────
                                      InvoiceSectionTitle(
                                        title: AppStrings.invoicePaymentHistory
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
                                      if (_invoice.status !=
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

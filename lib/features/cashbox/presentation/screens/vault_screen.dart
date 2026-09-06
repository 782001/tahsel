import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/utils/vault_balance_helper.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/buttons/custom_button.dart';
import 'package:tahsel/shared/widgets/custom_app_bar/custom_app_bar.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

import '../../domain/entities/vault_transaction_entity.dart';
import '../cubit/vault_cubit.dart';
import '../cubit/vault_state.dart';
import '../utils/vault_pdf_exporter.dart';
import '../widgets/manual_deposit_dialog.dart';
import '../widgets/manual_withdrawal_dialog.dart';
import '../widgets/vault_balance_card.dart';
import '../widgets/vault_source_filter_chips.dart';
import '../widgets/vault_transaction_card.dart';

class VaultScreen extends StatefulWidget {
  final String uid;

  const VaultScreen({super.key, required this.uid});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    context.read<VaultCubit>().loadVaultData(widget.uid);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<VaultCubit>().loadMoreTransactions();
    }
  }

  void _showDepositDialog() {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ManualDepositDialog(
        onSubmit: (amount, note) {
          context.read<VaultCubit>().depositManual(amount: amount, note: note);
        },
      ),
    );
  }

  void _showWithdrawalDialog(double currentBalance) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ManualWithdrawalDialog(
        currentBalance: currentBalance,
        onSubmit: (amount, note) {
          context.read<VaultCubit>().withdrawManual(amount: amount, note: note);
        },
      ),
    );
  }

  Future<void> _printPdf() async {
    final state = context.read<VaultCubit>().state;
    if (state is! VaultLoaded) return;
    if (_isExporting) return;

    setState(() => _isExporting = true);
    try {
      final currentLang = context.read<LocaleCubit>().currentLangCode;
      final isArabic = currentLang == AppStrings.arabicCode;

      // Fetch all matching transactions for a complete statement export
      final allTransactions = await context
          .read<VaultCubit>()
          .getAllTransactionsForExport(sourceFilter: state.selectedSource);

      final transactionsToExport = allTransactions.isNotEmpty
          ? allTransactions
          : state.transactions;

      await VaultPdfExporter.printVaultStatement(
        // ignore: use_build_context_synchronously
        context,
        summary: state.summary,
        transactions: transactionsToExport,
        isArabic: isArabic,
        filterName: state.selectedSource != VaultTransactionSource.all
            ? state.selectedSource.name
            : null,
      );
    } catch (e) {
      if (mounted) {
        AppLogger.printMessage('Vault PDF print error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    final state = context.read<VaultCubit>().state;
    if (state is! VaultLoaded) return;
    if (_isExporting) return;

    setState(() => _isExporting = true);
    try {
      final currentLang = context.read<LocaleCubit>().currentLangCode;
      final isArabic = currentLang == AppStrings.arabicCode;

      // Fetch all matching transactions for a complete statement export
      final allTransactions = await context
          .read<VaultCubit>()
          .getAllTransactionsForExport(sourceFilter: state.selectedSource);

      final transactionsToExport = allTransactions.isNotEmpty
          ? allTransactions
          : state.transactions;

      await VaultPdfExporter.exportAndShare(
        summary: state.summary,
        transactions: transactionsToExport,
        isArabic: isArabic,
        filterName: state.selectedSource != VaultTransactionSource.all
            ? state.selectedSource.name
            : null,
      );
    } catch (e) {
      if (mounted) {
        AppLogger.printMessage('Vault PDF export error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تصدير التقرير: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: CustomAppBar(
        centerTitle: AppStrings.vaultTitle.tr(),
        leadingIcon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textColor,
          size: isDesktop ? 22 : 20,
        ),
        onLeadingTap: () => Navigator.of(context).pop(),
        actions: [
          if (_isExporting)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal:isDesktop ? 16 : 16.w),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            )
          else ...[
            IconButton(
              tooltip: AppStrings.printVaultReport.tr(),
              icon: Container(
                padding: EdgeInsets.all(isDesktop ? 8 : 6.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.print_rounded,
                  color: AppColors.primaryColor,
                  size: isDesktop ? 20 : 18.sp,
                ),
              ),
              onPressed: _printPdf,
            ),
            IconButton(
              tooltip: AppStrings.invoiceSharePdf.tr(),
              icon: Container(
                padding: EdgeInsets.all(isDesktop ? 8 : 6.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.primaryColor,
                  size: isDesktop ? 20 : 18.sp,
                ),
              ),
              onPressed: _exportPdf,
            ),
            SizedBox(width: 4.w),
          ],
        ],
      ),
      body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          if (connectivityState is ConnectivityDisconnected) {
            return NoInternetView(
              onRetry: () =>
                  context.read<ConnectivityCubit>().checkConnectivity(),
            );
          }
          return BlocConsumer<VaultCubit, VaultState>(
            listener: (context, state) {
              if (state is VaultActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message.tr()),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is VaultError) {
                if (state.message.contains(AppStrings.insufficientBalance) ||
                    state.message.contains('insufficient_balance')) {
                  VaultBalanceHelper.showInsufficientBalanceDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message.tr()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              if (state is VaultLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                    strokeWidth: 4,
                  ),
                );
              }

            if (state is VaultError && state is! VaultLoaded) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48.sp,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      state.message.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    CustomButton(
                      text: AppStrings.tryAgain.tr(),
                      width: 140.w,
                      height: 44.h,
                      onPressed: () =>
                          context.read<VaultCubit>().loadVaultData(widget.uid),
                    ),
                  ],
                ),
              );
            }

            if (state is VaultLoaded) {
              return RefreshIndicator(
                color: AppColors.primaryColor,
                onRefresh: () =>
                    context.read<VaultCubit>().loadVaultData(widget.uid),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 900 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VaultBalanceCard(
                            summary: state.summary,
                            onDeposit: _showDepositDialog,
                            onWithdraw: () => _showWithdrawalDialog(
                              state.summary.currentBalance,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 24 : 20.h),
                          Text(
                            AppStrings.transactionHistory.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.textColor,
                              fontSize: isDesktop ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 12 : 10.h),
                          VaultSourceFilterChips(
                            selectedSource: state.selectedSource,
                            onSourceSelected: (source) {
                              context.read<VaultCubit>().filterBySource(source);
                            },
                          ),
                          SizedBox(height: isDesktop ? 16 : 14.h),
                          if (state.isFiltering) ...[
                            SizedBox(height: isDesktop ? 120 : 120.h),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                ),
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryColor,
                                  strokeWidth: 4,
                                ),
                              ),
                            ),
                          ] else if (state.transactions.isEmpty) ...[
                            SizedBox(height: isDesktop ? 120 : 120.h),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    color: AppColors.subTitleColor,
                                    size: isDesktop ? 64 : 54.sp,
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    AppStrings.noTransactions.tr(),
                                    style: TextStyles.customStyle(
                                      color: AppColors.subTitleColor,
                                      fontSize: isDesktop ? 15 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  state.transactions.length +
                                  (state.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.transactions.length) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16.h),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryColor,
                                        strokeWidth: 4,
                                      ),
                                    ),
                                  );
                                }
                                final item = state.transactions[index];
                                return VaultTransactionCard(transaction: item);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    ),
  );
}
}

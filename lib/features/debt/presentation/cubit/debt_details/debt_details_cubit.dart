import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_details/debt_details_state.dart';

import '../../../domain/entities/payment_entity.dart';
import '../../../domain/usecases/delete_payment_usecase.dart';
import '../../../domain/usecases/get_debt_transactions_future_use_case.dart';
import '../../../domain/usecases/update_payment_usecase.dart';
import '../../../domain/usecases/get_debt_by_id_usecase.dart';
import '../../../domain/entities/debt_entity.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/total_debts/total_debts_cubit.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/invoice/domain/usecases/invoice_usecases.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';

class DebtDetailsCubit extends Cubit<DebtDetailsState> {
  final GetDebtTransactionsFutureUseCase getDebtTransactionsUseCase;
  final UpdatePaymentUseCase updatePaymentUseCase;
  final DeletePaymentUseCase deletePaymentUseCase;
  final GetDebtByIdUseCase getDebtByIdUseCase;
  final SyncInvoiceFromDebtUseCase syncInvoiceFromDebtUseCase;
  List<PaymentEntity> _cachedTransactions = [];

  DebtDetailsCubit({
    required this.getDebtTransactionsUseCase,
    required this.updatePaymentUseCase,
    required this.deletePaymentUseCase,
    required this.getDebtByIdUseCase,
    required this.syncInvoiceFromDebtUseCase,
  }) : super(DebtDetailsInitial());

  Future<void> loadTransactions(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedTransactions.isNotEmpty &&
        state is DebtDetailsLoaded) {
      return;
    }

    emit(DebtDetailsLoading());

    final result = await getDebtTransactionsUseCase(
      GetDebtTransactionsParams(
        uid: uid,
        debtId: debtId,
        forceRefresh: forceRefresh,
      ),
    );

    // Also fetch the debt itself to ensure we have the latest description/name
    DebtEntity? currentDebt;
    final user = AppStrings.userToken;
    if (user.isNotEmpty) {
      final debtResult = await getDebtByIdUseCase(
        user,
        debtId,
        forceRefresh: forceRefresh,
      );
      debtResult.fold((_) => null, (debt) => currentDebt = debt);
    }

    if (currentDebt == null && forceRefresh) {
      // If we are refreshing and the debt is gone, it was likely deleted
      emit(DebtDetailsNotFound());
      return;
    }

    await result.fold(
      (failure) async => emit(DebtDetailsError(failure.message)),
      (transactions) async {
        final sortedTransactions = await compute(
          _processTransactions,
          transactions,
        );

        double totalAmount = 0;
        double totalPaid = 0;

        for (var t in sortedTransactions) {
          if (t.type == PaymentType.debtAdded) {
            totalAmount += t.amountPaid;
          } else if (t.type == PaymentType.partial ||
              t.type == PaymentType.full ||
              t.type == PaymentType.settlement) {
            totalPaid += t.amountPaid;
          } else if (t.type == PaymentType.adjustment ||
              t.type == PaymentType.reversal) {
            // Keep for backward compatibility with old ledger data
            if (t.relatedTo == 'debt') {
              totalAmount += t.amountPaid;
            } else if (t.relatedTo == 'payment') {
              totalPaid += t.amountPaid;
            }
          }
        }

        _cachedTransactions = sortedTransactions;
        emit(
          DebtDetailsLoaded(
            transactions: sortedTransactions,
            totalAmount: totalAmount,
            totalPaid: totalPaid,
            remainingDebt: totalAmount - totalPaid,
            debt: currentDebt,
          ),
        );
      },
    );
  }

  Future<void> updatePayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required double newAmount,
    required String customerName,
    String? note,
  }) async {
    double minAmount = 0;
    double? maxAmount;
    bool isDebtAdded = false;
    if (state is DebtDetailsLoaded) {
      final loadedState = state as DebtDetailsLoaded;
      final target = loadedState.transactions.firstWhere(
        (t) => t.id == paymentId,
      );

      isDebtAdded = target.type == PaymentType.debtAdded;

      if (isDebtAdded) {
        minAmount = loadedState.totalPaid;
      } else {
        // Business Rule: No negative adjustments (newValue >= current)
        minAmount = target.amountPaid;
        maxAmount = loadedState.remainingDebt + target.amountPaid;
      }
    }

    emit(DebtDetailsLoading());
    final result = await updatePaymentUseCase(
      UpdatePaymentParams(
        uid: uid,
        debtId: debtId,
        paymentId: paymentId,
        newAmount: newAmount,
        minAmount: minAmount,
        maxAmount: maxAmount,
        isDebtAdded: isDebtAdded,
        note: note,
      ),
    );

    await result.fold(
      (failure) async => emit(DebtDetailsError(failure.message)),
      (_) async {
        // Trigger global refreshes
        sl<TotalDebtsCubit>().getTotalDebts(uid, forceRefresh: true);
        sl<DebtCubit>().getDebts(uid, forceRefresh: true);

        // ── Bidirectional Invoice Sync ──────────────────────────────────────
        // If this debt was created from an invoice (operationId = debt_inv_<id>),
        // propagate the new payment total back to the invoice document so the
        // invoice list and detail screens never show stale data.
        _syncLinkedInvoice(uid, debtId);

        // Reload current transactions to get fresh totals
        await loadTransactions(uid, debtId, forceRefresh: true);

        if (state is DebtDetailsLoaded) {
          final loadedState = state as DebtDetailsLoaded;
          emit(
            DebtDetailsUpdateSuccess(
              transactions: loadedState.transactions,
              totalAmount: loadedState.totalAmount,
              totalPaid: loadedState.totalPaid,
              remainingDebt: loadedState.remainingDebt,
              debt: loadedState.debt,
              customerName: customerName,
              amountPaid: newAmount, // Pass NEW amount for 'edit' template
              remainingBalance: loadedState.remainingDebt,
              note: note ?? '',
            ),
          );
        }
      },
    );
  }

  Future<void> deletePayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required String customerName,
    required double amountBeingDeleted,
  }) async {
    emit(DebtDetailsLoading());
    final result = await deletePaymentUseCase(
      DeletePaymentParams(uid: uid, debtId: debtId, paymentId: paymentId),
    );

    await result.fold(
      (failure) async => emit(DebtDetailsError(failure.message)),
      (_) async {
        // Trigger global refreshes
        sl<TotalDebtsCubit>().getTotalDebts(uid, forceRefresh: true);
        sl<DebtCubit>().getDebts(uid, forceRefresh: true);

        // ── Bidirectional Invoice Sync ──────────────────────────────────────
        _syncLinkedInvoice(uid, debtId);

        // Reload current transactions
        await loadTransactions(uid, debtId, forceRefresh: true);

        if (state is DebtDetailsLoaded) {
          final loadedState = state as DebtDetailsLoaded;
          emit(
            DebtDetailsDeleteSuccess(
              transactions: loadedState.transactions,
              totalAmount: loadedState.totalAmount,
              totalPaid: loadedState.totalPaid,
              remainingDebt: loadedState.remainingDebt,
              debt: loadedState.debt,
              customerName: customerName,
              amountPaid: amountBeingDeleted, // Absolute value for display
              remainingBalance: loadedState.remainingDebt,
              note: AppStrings.deleteSuccess,
            ),
          );
        }
      },
    );
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  /// Fires the invoice sync in the background (fire-and-forget).
  /// Also refreshes [InvoiceCubit] so the list screen updates immediately.
  void _syncLinkedInvoice(String uid, String debtId) {
    if (!debtId.startsWith('debt_inv_')) return;
    // Run async without blocking the UI
    syncInvoiceFromDebtUseCase(uid: uid, debtId: debtId).then((_) {
      // Refresh the InvoiceCubit so the list and detail screens update
      // without the user needing to reopen them.
      if (sl.isRegistered<InvoiceCubit>()) {
        sl<InvoiceCubit>().fetchInvoices(uid, forceRefresh: true);
      }
    });
  }

  static List<PaymentEntity> _processTransactions(
    List<PaymentEntity> transactions,
  ) {
    // Requirements: sorting (latest at TOP) and calculating remaining amounts (though we have them stored)
    // If we needed to calculate running totals, we'd do it here.
    final List<PaymentEntity> sortedList = List.from(transactions);
    sortedList.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return sortedList;
  }
}

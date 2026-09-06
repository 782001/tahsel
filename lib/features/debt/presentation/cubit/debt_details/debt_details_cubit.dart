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
import '../../../domain/repositories/debt_repository.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/total_debts/total_debts_cubit.dart';
import 'package:tahsel/core/utils/app_strings.dart';

class DebtDetailsCubit extends Cubit<DebtDetailsState> {
  final GetDebtTransactionsFutureUseCase getDebtTransactionsUseCase;
  final UpdatePaymentUseCase updatePaymentUseCase;
  final DeletePaymentUseCase deletePaymentUseCase;
  final GetDebtByIdUseCase getDebtByIdUseCase;
  List<PaymentEntity> _cachedTransactions = [];

  DebtDetailsCubit({
    required this.getDebtTransactionsUseCase,
    required this.updatePaymentUseCase,
    required this.deletePaymentUseCase,
    required this.getDebtByIdUseCase,
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
    if (isClosed) return;

    // Also fetch the debt itself to ensure we have the latest description/name
    DebtEntity? currentDebt;
    final user = AppStrings.userToken;
    if (user.isNotEmpty) {
      final debtResult = await getDebtByIdUseCase(
        user,
        debtId,
        forceRefresh: forceRefresh,
      );
      if (isClosed) return;
      debtResult.fold((_) => null, (debt) => currentDebt = debt);
    }

    if (currentDebt == null && forceRefresh) {
      // If we are refreshing and the debt is gone, it was likely deleted
      emit(DebtDetailsNotFound());
      return;
    }

    await result.fold(
      (failure) async {
        if (isClosed) return;
        emit(DebtDetailsError(failure.message));
      },
      (transactions) async {
        final sortedTransactions = await compute(
          _processTransactions,
          transactions,
        );
        if (isClosed) return;

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
      (failure) async {
        if (isClosed) return;
        emit(DebtDetailsError(failure.message));
      },
      (_) async {
        // Trigger global refreshes
        sl<TotalDebtsCubit>().getTotalDebts(uid, forceRefresh: true);
        sl<DebtCubit>().getDebts(uid, forceRefresh: true);

        // Reload current transactions to get fresh totals
        await loadTransactions(uid, debtId, forceRefresh: true);
        if (isClosed) return;

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
    if (isClosed) return;

    await result.fold(
      (failure) async {
        if (isClosed) return;
        emit(DebtDetailsError(failure.message));
      },
      (_) async {
        // Trigger global refreshes
        sl<TotalDebtsCubit>().getTotalDebts(uid, forceRefresh: true);
        sl<DebtCubit>().getDebts(uid, forceRefresh: true);

        // Reload current transactions
        await loadTransactions(uid, debtId, forceRefresh: true);
        if (isClosed) return;

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

  Future<bool> settleCustomerCredit({
    required String uid,
    required String debtId,
    required double creditAmount,
    String? note,
  }) async {
    final prevState = state;
    emit(DebtDetailsLoading());
    final repository = sl<DebtRepository>();
    final result = await repository.settleCustomerCredit(
      uid: uid,
      debtId: debtId,
      creditAmount: creditAmount,
      note: note,
    );
    if (isClosed) return false;

    return await result.fold(
      (failure) async {
        if (isClosed) return false;
        if (prevState is DebtDetailsLoaded) {
          emit(prevState);
        }
        emit(DebtDetailsError(failure.message));
        return false;
      },
      (_) async {
        // Trigger global refreshes
        sl<TotalDebtsCubit>().getTotalDebts(uid, forceRefresh: true);
        sl<DebtCubit>().getDebts(uid, forceRefresh: true);

        // Reload current transactions
        await loadTransactions(uid, debtId, forceRefresh: true);
        return true;
      },
    );
  }

  @override
  void emit(DebtDetailsState state) {
    if (!isClosed) {
      super.emit(state);
    }
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

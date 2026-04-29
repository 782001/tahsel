import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_details/debt_details_state.dart';

import '../../../domain/entities/payment_entity.dart';
import '../../../domain/usecases/get_debt_transactions_future_use_case.dart';

class DebtDetailsCubit extends Cubit<DebtDetailsState> {
  final GetDebtTransactionsFutureUseCase getDebtTransactionsUseCase;
  List<PaymentEntity> _cachedTransactions = [];

  DebtDetailsCubit({required this.getDebtTransactionsUseCase})
    : super(DebtDetailsInitial());

  Future<void> loadTransactions(
    String debtId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedTransactions.isNotEmpty &&
        state is DebtDetailsLoaded) {
      return;
    }

    emit(DebtDetailsLoading());

    final result = await getDebtTransactionsUseCase(debtId);

    result.fold((failure) => emit(DebtDetailsError(failure.message)), (
      transactions,
    ) async {
      final sortedTransactions = await compute(
        _processTransactions,
        transactions,
      );
      _cachedTransactions = sortedTransactions;
      emit(DebtDetailsLoaded(sortedTransactions));
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

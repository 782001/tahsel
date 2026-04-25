import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_details/debt_details_state.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../../domain/usecases/get_debt_transactions_use_case.dart';


class DebtDetailsCubit extends Cubit<DebtDetailsState> {
  final GetDebtTransactionsUseCase getDebtTransactionsUseCase;
  StreamSubscription? _subscription;

  DebtDetailsCubit({required this.getDebtTransactionsUseCase})
      : super(DebtDetailsInitial());

  void loadTransactions(String debtId) {
    emit(DebtDetailsLoading());
    _subscription?.cancel();
    _subscription = getDebtTransactionsUseCase(debtId).listen(
      (transactions) async {
        // Requirement 10: Use Isolate for processing large datasets
        // We'll use compute for sorting and any calculations if needed
        final sortedTransactions = await compute(_processTransactions, transactions);
        emit(DebtDetailsLoaded(sortedTransactions));
      },
      onError: (error) {
        emit(DebtDetailsError(error.toString()));
      },
    );
  }

  static List<PaymentEntity> _processTransactions(List<PaymentEntity> transactions) {
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

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

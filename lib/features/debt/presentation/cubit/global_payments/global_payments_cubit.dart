import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/payment_entity.dart';
import '../../../domain/usecases/get_customer_all_payments_paginated_usecase.dart';
import '../../../domain/usecases/get_customer_all_payments_usecase.dart';
import 'global_payments_state.dart';

class GlobalPaymentsCubit extends Cubit<GlobalPaymentsState> {
  final GetCustomerAllPaymentsUseCase getCustomerAllPaymentsUseCase;
  final GetCustomerAllPaymentsPaginatedUseCase
  getCustomerAllPaymentsPaginatedUseCase;

  GlobalPaymentsCubit({
    required this.getCustomerAllPaymentsUseCase,
    required this.getCustomerAllPaymentsPaginatedUseCase,
  }) : super(GlobalPaymentsInitial());

  List<PaymentEntity> _cachedTransactions = [];
  String? _lastUid;
  String? _lastCustomerName;

  Future<void> loadCustomerPayments({
    required String uid,
    required String customerName,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _lastUid == uid &&
        _lastCustomerName == customerName &&
        _cachedTransactions.isNotEmpty &&
        state is GlobalPaymentsLoaded &&
        !(state as GlobalPaymentsLoaded).hasMore) {
      return;
    }

    emit(GlobalPaymentsLoading());

    // For the initial load, we still use the paginated use case with no cursor
    final result = await getCustomerAllPaymentsPaginatedUseCase(
      uid: uid,
      customerName: customerName,
      limit: 15,
    );

    result.fold((failure) => emit(GlobalPaymentsError(failure.message)), (
      paginatedResult,
    ) async {
      final payments = paginatedResult.items;
      if (payments.isEmpty) {
        emit(const GlobalPaymentsLoaded(transactions: [], totalPaid: 0));
        return;
      }

      // Processing in Isolate (MANDATORY)
      final processedData = await compute(_processPayments, payments);

      _cachedTransactions = processedData.transactions;
      _lastUid = uid;
      _lastCustomerName = customerName;

      emit(
        GlobalPaymentsLoaded(
          transactions: processedData.transactions,
          totalPaid: processedData.totalPaid,
          lastDocument: paginatedResult.lastDocument,
          hasMore: paginatedResult.hasMore,
        ),
      );
    });
  }

  Future<void> loadMorePayments({
    required String uid,
    required String customerName,
  }) async {
    final currentState = state;
    if (currentState is! GlobalPaymentsLoaded ||
        !currentState.hasMore ||
        currentState.isPaginationLoading) {
      return;
    }

    emit(currentState.copyWith(isPaginationLoading: true));

    final result = await getCustomerAllPaymentsPaginatedUseCase(
      uid: uid,
      customerName: customerName,
      limit: 15,
      lastDocument: currentState.lastDocument,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isPaginationLoading: false)),
      (paginatedResult) async {
        final newPayments = paginatedResult.items;

        // Process only the NEW payments for total, then merge
        final processedData = await compute(_processPayments, newPayments);

        final updatedTransactions =
            List<PaymentEntity>.from(currentState.transactions)
              ..addAll(processedData.transactions);

        emit(
          GlobalPaymentsLoaded(
            transactions: updatedTransactions,
            totalPaid: currentState.totalPaid + processedData.totalPaid,
            lastDocument: paginatedResult.lastDocument,
            hasMore: paginatedResult.hasMore,
            isPaginationLoading: false,
          ),
        );
      },
    );
  }
}

/// Processing logic to be run in an Isolate
_ProcessedPayments _processPayments(List<PaymentEntity> payments) {
  // 1. Sorting by latest first
  final sorted = List<PaymentEntity>.from(payments)
    ..sort(
      (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
        a.createdAt ?? DateTime.now(),
      ),
    );

  // 2. Calculating total paid (for this batch)
  double total = 0;
  for (var p in payments) {
    if (p.type != PaymentType.debtAdded) {
      total += p.amountPaid;
    }
  }

  return _ProcessedPayments(transactions: sorted, totalPaid: total);
}

class _ProcessedPayments {
  final List<PaymentEntity> transactions;
  final double totalPaid;

  _ProcessedPayments({required this.transactions, required this.totalPaid});
}

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../../domain/usecases/get_customer_all_payments_usecase.dart';
import 'global_payments_state.dart';

class GlobalPaymentsCubit extends Cubit<GlobalPaymentsState> {
  final GetCustomerAllPaymentsUseCase getCustomerAllPaymentsUseCase;

  GlobalPaymentsCubit({required this.getCustomerAllPaymentsUseCase})
      : super(GlobalPaymentsInitial());

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
        state is GlobalPaymentsLoaded) {
      return;
    }

    emit(GlobalPaymentsLoading());

    final result = await getCustomerAllPaymentsUseCase(
      GetCustomerAllPaymentsParams(
        uid: uid,
        customerName: customerName,
      ),
    );

    result.fold(
      (failure) => emit(GlobalPaymentsError(failure.message)),
      (payments) async {
        if (payments.isEmpty) {
          emit(const GlobalPaymentsLoaded(transactions: [], totalPaid: 0));
          return;
        }

        // Processing in Isolate (MANDATORY)
        final processedData = await compute(_processPayments, payments);
        
        _cachedTransactions = processedData.transactions;
        _lastUid = uid;
        _lastCustomerName = customerName;

        emit(GlobalPaymentsLoaded(
          transactions: processedData.transactions,
          totalPaid: processedData.totalPaid,
        ));
      },
    );
  }
}

/// Processing logic to be run in an Isolate
_ProcessedPayments _processPayments(List<PaymentEntity> payments) {
  // 1. Sorting by latest first
  final sorted = List<PaymentEntity>.from(payments)
    ..sort((a, b) => (b.createdAt ?? DateTime.now())
        .compareTo(a.createdAt ?? DateTime.now()));

  // 2. Calculating total paid
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

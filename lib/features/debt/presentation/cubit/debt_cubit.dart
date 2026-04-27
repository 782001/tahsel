import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/debt_entity.dart';
import '../../domain/usecases/add_debt_usecase.dart';
import '../../domain/usecases/delete_customer_debt_usecase.dart';
import '../../domain/usecases/delete_debt_item_usecase.dart';
import '../../domain/usecases/get_debts_usecase.dart';
import '../../domain/usecases/mark_customer_as_paid_usecase.dart';
import '../../domain/usecases/mark_item_as_paid_usecase.dart';
import '../../domain/usecases/pay_debt_usecase.dart';
import '../../domain/usecases/pay_item_debt_usecase.dart';
import 'debt_state.dart';

class DebtCubit extends Cubit<DebtState> {
  final AddDebtUseCase addDebtUseCase;
  final GetDebtsUseCase getDebtsUseCase;
  final PayDebtUseCase payDebtUseCase;
  final MarkCustomerAsPaidUseCase markCustomerAsPaidUseCase;
  final PayItemDebtUseCase payItemDebtUseCase;
  final MarkItemAsPaidUseCase markItemAsPaidUseCase;
  final DeleteCustomerDebtUseCase deleteCustomerDebtUseCase;
  final DeleteDebtItemUseCase deleteDebtItemUseCase;

  DebtCubit({
    required this.addDebtUseCase,
    required this.getDebtsUseCase,
    required this.payDebtUseCase,
    required this.markCustomerAsPaidUseCase,
    required this.payItemDebtUseCase,
    required this.markItemAsPaidUseCase,
    required this.deleteCustomerDebtUseCase,
    required this.deleteDebtItemUseCase,
  }) : super(DebtInitial());

  Future<void> addDebt({
    required String uid,
    required double totalAmount,
    required double paidAmount,
    required String customerName,
    required String productOrSessionDetails,
    required String operationType,
    required String? ledgerNumber,
  }) async {
    emit(DebtLoading());

    final now = DateTime.now();
    final debt = await compute(_createCustomerDebtEntity, _AddCustomerDebtParams(
      uid: uid,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      customerName: customerName,
      productOrSessionDetails: productOrSessionDetails,
      operationType: operationType,
      ledgerNumber: ledgerNumber,
      now: now,
    ));

    final result = await addDebtUseCase(AddDebtParams(debt: debt));
    result.fold(
      (failure) => emit(DebtFailure(message: failure.message)),
      (debtId) {
        emit(DebtAddSuccess(debtId: debtId));
        getDebts(debt.uid);
      },
    );
  }

  Future<void> getDebts(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && state is DebtsFetchSuccess && (state as DebtsFetchSuccess).debts.isNotEmpty) {
      return;
    }
    emit(DebtLoading());
    final result = await getDebtsUseCase(GetDebtsParams(uid: uid));
    result.fold(
      (failure) => emit(DebtFailure(message: failure.message)),
      (debts) => emit(DebtsFetchSuccess(debts: debts)),
    );
  }

  Future<void> payDebt({
    required String uid,
    required String customerName,
    required double amount,
    required double totalRemainingBefore,
    String? note,
  }) async {
    emit(DebtLoading());
    final result = await payDebtUseCase(
      PayDebtParams(uid: uid, customerName: customerName, amount: amount),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (
      _,
    ) {
      emit(DebtPaymentSuccess(
        customerName: customerName,
        amountPaid: amount,
        remainingBalance: totalRemainingBefore - amount,
        note: note,
      ));
      getDebts(uid);
    });
  }

  Future<void> markAsPaid({
    required String uid,
    required String customerName,
    required double totalAmount,
    String? note,
  }) async {
    emit(DebtLoading());
    final result = await markCustomerAsPaidUseCase(
      MarkCustomerAsPaidParams(uid: uid, customerName: customerName),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (
      _,
    ) {
      emit(DebtPaymentSuccess(
        customerName: customerName,
        amountPaid: totalAmount,
        remainingBalance: 0,
        note: note,
      ));
      getDebts(uid);
    });
  }

  Future<void> payItemDebt({
    required DebtEntity debt,
    required double amount,
    required double totalRemainingBefore,
  }) async {
    emit(DebtLoading());
    final result = await payItemDebtUseCase(
      PayItemDebtParams(debt: debt, amountToPay: amount),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (
      _,
    ) {
      emit(DebtPaymentSuccess(
        customerName: debt.customerName!,
        amountPaid: amount,
        remainingBalance: totalRemainingBefore - amount,
        note: debt.productOrSessionDetails,
      ));
      getDebts(debt.uid);
    });
  }

  Future<void> markItemAsPaid({
    required DebtEntity debt,
    required double totalRemainingBefore,
  }) async {
    emit(DebtLoading());
    final result = await markItemAsPaidUseCase(debt);
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (
      _,
    ) {
      final amountPaid = debt.totalAmount - debt.paidAmount;
      emit(DebtPaymentSuccess(
        customerName: debt.customerName ?? '',
        amountPaid: amountPaid,
        remainingBalance: totalRemainingBefore - amountPaid,
        note: debt.productOrSessionDetails,
      ));
      getDebts(debt.uid);
    });
  }

  Future<void> deleteCustomerDebts(String uid, String customerName) async {
    emit(DebtLoading());
    final result = await deleteCustomerDebtUseCase(
      DeleteDebtParams(uid: uid, customerName: customerName),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (
      _,
    ) {
      emit(const DebtDeleteSuccess());
      getDebts(uid);
    });
  }

  Future<void> deleteDebtItem(String uid, String debtId) async {
    emit(DebtLoading());
    final result = await deleteDebtItemUseCase(
      DeleteDebtItemParams(uid: uid, debtId: debtId),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (
      _,
    ) {
      emit(const DebtDeleteSuccess());
      getDebts(uid);
    });
  }
}

class _AddCustomerDebtParams {
  final String uid;
  final double totalAmount;
  final double paidAmount;
  final String customerName;
  final String productOrSessionDetails;
  final String operationType;
  final String? ledgerNumber;
  final DateTime now;
  
  _AddCustomerDebtParams({
    required this.uid,
    required this.totalAmount,
    required this.paidAmount,
    required this.customerName,
    required this.productOrSessionDetails,
    required this.operationType,
    required this.ledgerNumber,
    required this.now,
  });
}

DebtEntity _createCustomerDebtEntity(_AddCustomerDebtParams params) {
  final remainingAmount = params.totalAmount - params.paidAmount;
  return DebtEntity(
    uid: params.uid,
    operationId: 'manual_debt_${params.now.millisecondsSinceEpoch}',
    totalAmount: params.totalAmount,
    paidAmount: params.paidAmount,
    remainingAmount: remainingAmount,
    customerName: params.customerName,
    productOrSessionDetails: params.productOrSessionDetails.isNotEmpty
        ? params.productOrSessionDetails
        : 'ديون جديدة', // Keeping it consistent with "New debt" logic (from AppStrings.newDebt.tr() if empty)
    operationType: params.operationType,
    timestamp: params.now,
    isPaid: remainingAmount <= 0,
    ledgerNumber: params.ledgerNumber,
  );
}

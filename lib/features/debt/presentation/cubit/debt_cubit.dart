import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/debt/domain/entities/debt_entity.dart';
import 'package:tahsel/features/debt/domain/usecases/add_debt_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/delete_customer_debt_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/delete_debt_item_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/get_debts_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/mark_customer_as_paid_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/mark_item_as_paid_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/pay_debt_usecase.dart';
import 'package:tahsel/features/debt/domain/usecases/pay_item_debt_usecase.dart';
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
    String? operationId,
  }) async {
    final sanitizedName = customerName.replaceAll('/', ' ').trim();
    emit(DebtLoading());

    final now = DateTime.now();
    final debt = await compute(
      _createCustomerDebtEntity,
      _AddCustomerDebtParams(
        uid: uid,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        customerName: sanitizedName,
        productOrSessionDetails: productOrSessionDetails,
        operationType: operationType,
        ledgerNumber: ledgerNumber,
        operationId: operationId,
        now: now,
      ),
    );

    final result = await addDebtUseCase(AddDebtParams(debt: debt));
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (
      debtId,
    ) {
      emit(DebtAddSuccess(debtId: debtId));
      getDebts(uid, forceRefresh: true);
    });
  }

  Future<void> getDebts(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        state is DebtsFetchSuccess &&
        (state as DebtsFetchSuccess).debts.isNotEmpty) {
      return;
    }
    emit(DebtLoading());
    final result = await getDebtsUseCase(
      GetDebtsParams(uid: uid, forceRefresh: forceRefresh),
    );
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
    final sanitizedName = customerName.replaceAll('/', ' ').trim();
    emit(DebtLoading());
    final result = await payDebtUseCase(
      PayDebtParams(uid: uid, customerName: sanitizedName, amount: amount),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (_) {
      emit(
        DebtPaymentSuccess(
          customerName: sanitizedName,
          amountPaid: amount,
          remainingBalance: totalRemainingBefore - amount,
          note: note,
        ),
      );
      getDebts(uid, forceRefresh: true);
    });
  }

  Future<void> markAsPaid({
    required String uid,
    required String customerName,
    required double totalAmount,
    String? note,
  }) async {
    final sanitizedName = customerName.replaceAll('/', ' ').trim();
    emit(DebtLoading());
    final result = await markCustomerAsPaidUseCase(
      MarkCustomerAsPaidParams(uid: uid, customerName: sanitizedName),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (_) {
      emit(
        DebtPaymentSuccess(
          customerName: sanitizedName,
          amountPaid: totalAmount,
          remainingBalance: 0,
          note: note,
        ),
      );
      getDebts(uid, forceRefresh: true);
    });
  }

  Future<void> payItem({
    required DebtEntity debt,
    required double amount,
    required double totalRemainingBefore,
    String? note,
  }) async {
    emit(DebtLoading());
    final result = await payItemDebtUseCase(
      PayItemDebtParams(debt: debt, amountToPay: amount),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (_) {
      emit(
        DebtPaymentSuccess(
          customerName: debt.customerName ?? '',
          amountPaid: amount,
          remainingBalance: totalRemainingBefore - amount,
          note: note,
        ),
      );
      getDebts(debt.uid, forceRefresh: true);
    });
  }

  Future<void> markItemAsPaid({
    required DebtEntity debt,
    required double totalRemainingBefore,
  }) async {
    emit(DebtLoading());
    final result = await markItemAsPaidUseCase(debt);
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (_) {
      final amountPaid = debt.totalAmount - debt.paidAmount;
      emit(
        DebtPaymentSuccess(
          customerName: debt.customerName ?? '',
          amountPaid: amountPaid,
          remainingBalance: totalRemainingBefore - amountPaid,
          note: debt.productOrSessionDetails,
        ),
      );
      getDebts(debt.uid, forceRefresh: true);
    });
  }

  Future<void> deleteCustomerDebts(String uid, String customerName) async {
    final sanitizedName = customerName.replaceAll('/', ' ').trim();
    emit(DebtLoading());
    final result = await deleteCustomerDebtUseCase(
      DeleteDebtParams(uid: uid, customerName: sanitizedName),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (_) {
      emit(const DebtDeleteSuccess());
      getDebts(uid, forceRefresh: true);
    });
  }

  Future<void> deleteDebtItem(String uid, String debtId) async {
    emit(DebtLoading());
    final result = await deleteDebtItemUseCase(
      DeleteDebtItemParams(uid: uid, debtId: debtId),
    );
    result.fold((failure) => emit(DebtFailure(message: failure.message)), (_) {
      emit(const DebtDeleteSuccess());
      getDebts(uid, forceRefresh: true);
    });
  }

  void clearData() {
    emit(DebtInitial());
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
  final String? operationId;
  final DateTime now;

  _AddCustomerDebtParams({
    required this.uid,
    required this.totalAmount,
    required this.paidAmount,
    required this.customerName,
    required this.productOrSessionDetails,
    required this.operationType,
    required this.ledgerNumber,
    this.operationId,
    required this.now,
  });
}

DebtEntity _createCustomerDebtEntity(_AddCustomerDebtParams params) {
  final remainingAmount = params.totalAmount - params.paidAmount;

  final timeKey = params.now.millisecondsSinceEpoch ~/ 1000;
  final fingerprint =
      '${params.uid}_debt_${params.totalAmount}_${params.customerName}_$timeKey';
  final deterministicId = 'debt_${fingerprint.hashCode.toString()}';

  return DebtEntity(
    uid: params.uid,
    operationId: params.operationId ?? deterministicId,
    totalAmount: params.totalAmount,
    paidAmount: params.paidAmount,
    remainingAmount: remainingAmount,
    customerName: params.customerName,
    productOrSessionDetails: params.productOrSessionDetails.isNotEmpty
        ? params.productOrSessionDetails
        : 'ديون جديدة',
    operationType: params.operationType,
    timestamp: params.now,
    isPaid: remainingAmount <= 0,
    ledgerNumber: params.ledgerNumber,
  );
}

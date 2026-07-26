import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/inventory/presentation/cubits/inventory_purchases_cubit.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_item_payments_paginated_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_item_payments_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/get_my_debt_by_id_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/delete_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/update_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_state.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_summary_cubit.dart';

class MyDebtDetailsReportCubit extends Cubit<MyDebtDetailsReportState> {
  final GetMyDebtItemPaymentsUseCase getMyDebtItemPaymentsUseCase;
  final GetMyDebtItemPaymentsPaginatedUseCase
  getMyDebtItemPaymentsPaginatedUseCase;
  final UpdateMyDebtPaymentUseCase updateMyDebtPaymentUseCase;
  final DeleteMyDebtPaymentUseCase deleteMyDebtPaymentUseCase;
  final GetMyDebtByIdUseCase getMyDebtByIdUseCase;

  MyDebtDetailsReportCubit({
    required this.getMyDebtItemPaymentsUseCase,
    required this.getMyDebtItemPaymentsPaginatedUseCase,
    required this.updateMyDebtPaymentUseCase,
    required this.deleteMyDebtPaymentUseCase,
    required this.getMyDebtByIdUseCase,
  }) : super(MyDebtDetailsReportLoading());

  Future<void> loadTransactions(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      emit(MyDebtDetailsReportLoading());
    }

    final result = await getMyDebtItemPaymentsPaginatedUseCase(
      GetMyDebtItemPaymentsPaginatedParams(
        uid: uid,
        debtId: debtId,
        limit: 15,
        forceRefresh: forceRefresh,
      ),
    );

    // Also fetch the debt itself
    MyDebtItemEntity? currentDebt;
    final debtResult = await getMyDebtByIdUseCase(
      uid,
      debtId,
      forceRefresh: forceRefresh,
    );
    debtResult.fold((_) => null, (debt) => currentDebt = debt);

    if (currentDebt == null && forceRefresh) {
      emit(MyDebtDetailsReportNotFound());
      return;
    }

    result.fold(
      (failure) => emit(MyDebtDetailsReportError(message: failure.message)),
      (paginated) {
        double calcTotalAmount = 0;
        double calcPaidAmount = 0;

        for (var t in paginated.items) {
          if (t.type == PaymentType.debtAdded) {
            calcTotalAmount += t.amountPaid;
          } else if (t.type == PaymentType.partial ||
              t.type == PaymentType.full ||
              t.type == PaymentType.settlement) {
            calcPaidAmount += t.amountPaid;
          } else if (t.type == PaymentType.adjustment ||
              t.type == PaymentType.reversal) {
            if (t.relatedTo == 'debt') {
              calcTotalAmount += t.amountPaid;
            } else if (t.relatedTo == 'payment') {
              calcPaidAmount += t.amountPaid;
            }
          }
        }

        final double finalTotalAmount =
            currentDebt?.totalAmount ?? calcTotalAmount;
        final double finalPaidAmount =
            currentDebt?.paidAmount ?? calcPaidAmount;
        final double finalRemainingAmount = currentDebt?.remainingAmount ??
            (finalTotalAmount - finalPaidAmount);

        emit(
          MyDebtDetailsReportLoaded(
            transactions: paginated.items,
            totalAmount: finalTotalAmount,
            paidAmount: finalPaidAmount,
            remainingAmount: finalRemainingAmount,
            debt: currentDebt,
            lastDocument: paginated.lastDocument,
            hasMore: paginated.hasMore,
            isPaginationLoading: false,
          ),
        );
      },
    );
  }

  Future<void> loadMoreTransactions(String uid, String debtId) async {
    if (state is! MyDebtDetailsReportLoaded) return;
    final loadedState = state as MyDebtDetailsReportLoaded;
    if (loadedState.isPaginationLoading || !loadedState.hasMore) return;

    emit(loadedState.copyWith(isPaginationLoading: true));

    final result = await getMyDebtItemPaymentsPaginatedUseCase(
      GetMyDebtItemPaymentsPaginatedParams(
        uid: uid,
        debtId: debtId,
        limit: 15,
        lastDocument: loadedState.lastDocument,
      ),
    );

    result.fold(
      (failure) => emit(loadedState.copyWith(isPaginationLoading: false)),
      (paginated) {
        final updatedTransactions = List<PaymentEntity>.from(
          loadedState.transactions,
        )..addAll(paginated.items);

        double totalAmount = 0;
        double paidAmount = 0;

        for (var t in updatedTransactions) {
          if (t.type == PaymentType.debtAdded) {
            totalAmount += t.amountPaid;
          } else if (t.type == PaymentType.partial ||
              t.type == PaymentType.full ||
              t.type == PaymentType.settlement) {
            paidAmount += t.amountPaid;
          } else if (t.type == PaymentType.adjustment ||
              t.type == PaymentType.reversal) {
            if (t.relatedTo == 'debt') {
              totalAmount += t.amountPaid;
            } else if (t.relatedTo == 'payment') {
              paidAmount += t.amountPaid;
            }
          }
        }

        emit(
          loadedState.copyWith(
            transactions: updatedTransactions,
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            remainingAmount: totalAmount - paidAmount,
            lastDocument: paginated.lastDocument,
            hasMore: paginated.hasMore,
            isPaginationLoading: false,
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
    required String personName,
    String? note,
  }) async {
    double minAmount = 0;
    double? maxAmount;
    bool isDebtAdded = false;
    if (state is MyDebtDetailsReportLoaded) {
      final loadedState = state as MyDebtDetailsReportLoaded;
      final target = loadedState.transactions.firstWhere(
        (t) => t.id == paymentId,
      );

      isDebtAdded = target.type == PaymentType.debtAdded;

      if (isDebtAdded) {
        minAmount = loadedState.paidAmount;
      } else {
        minAmount = target.amountPaid;
        maxAmount = loadedState.remainingAmount + target.amountPaid;
      }
    }

    emit(MyDebtDetailsReportLoading());
    final result = await updateMyDebtPaymentUseCase(
      UpdateMyDebtPaymentParams(
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
      (failure) async =>
          emit(MyDebtDetailsReportError(message: failure.message)),
      (_) async {
        // Trigger global refresh
        if (sl.isRegistered<MyDebtsCubit>()) {
          sl<MyDebtsCubit>().loadPersons(uid, forceRefresh: true);
        }
        if (sl.isRegistered<MyDebtsSummaryCubit>()) {
          sl<MyDebtsSummaryCubit>().refreshSummary(uid);
        }

        // Trigger details refresh
        if (sl.isRegistered<MyDebtDetailsCubit>()) {
          sl<MyDebtDetailsCubit>().loadDetails(uid, personName);
        }

        // Reload local transactions and debt info
        await loadTransactions(uid, debtId, forceRefresh: true);

        if (state is MyDebtDetailsReportLoaded) {
          final loadedState = state as MyDebtDetailsReportLoaded;
          emit(
            MyDebtDetailsUpdateSuccess(
              transactions: loadedState.transactions,
              totalAmount: loadedState.totalAmount,
              paidAmount: loadedState.paidAmount,
              remainingAmount: loadedState.remainingAmount,
              debt: loadedState.debt,
              personName: personName,
              amountPaid: newAmount, // Pass NEW amount for notification
              remainingBalance: loadedState.remainingAmount,
              note: note ?? '',
              lastDocument: loadedState.lastDocument,
              hasMore: loadedState.hasMore,
              isPaginationLoading: loadedState.isPaginationLoading,
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
    required String personName,
    required double amountBeingDeleted,
  }) async {
    emit(MyDebtDetailsReportLoading());
    final result = await deleteMyDebtPaymentUseCase(
      DeleteMyDebtPaymentParams(uid: uid, debtId: debtId, paymentId: paymentId),
    );

    await result.fold(
      (failure) async =>
          emit(MyDebtDetailsReportError(message: failure.message)),
      (_) async {
        // Trigger global refresh
        if (sl.isRegistered<MyDebtsCubit>()) {
          sl<MyDebtsCubit>().loadPersons(uid, forceRefresh: true);
        }
        if (sl.isRegistered<MyDebtsSummaryCubit>()) {
          sl<MyDebtsSummaryCubit>().refreshSummary(uid);
        }

        // Trigger details refresh
        if (sl.isRegistered<MyDebtDetailsCubit>()) {
          sl<MyDebtDetailsCubit>().loadDetails(uid, personName);
        }

        // Reload local transactions and debt info
        await loadTransactions(uid, debtId, forceRefresh: true);

        if (state is MyDebtDetailsReportLoaded) {
          final loadedState = state as MyDebtDetailsReportLoaded;
          emit(
            MyDebtDetailsDeleteSuccess(
              transactions: loadedState.transactions,
              totalAmount: loadedState.totalAmount,
              paidAmount: loadedState.paidAmount,
              remainingAmount: loadedState.remainingAmount,
              debt: loadedState.debt,
              personName: personName,
              amountPaid: amountBeingDeleted, // Absolute value for display
              remainingBalance: loadedState.remainingAmount,
              note: '',
              lastDocument: loadedState.lastDocument,
              hasMore: loadedState.hasMore,
              isPaginationLoading: loadedState.isPaginationLoading,
            ),
          );
        }
      },
    );
  }

  Future<void> settleSupplierCredit({
    required String uid,
    required String debtId,
    required String personName,
    required double creditAmount,
  }) async {
    final repo = sl<MyDebtRepository>();
    emit(MyDebtDetailsReportLoading());
    final result = await repo.settleSupplierCredit(
      uid: uid,
      debtId: debtId,
      creditAmount: creditAmount,
    );

    await result.fold(
      (failure) async =>
          emit(MyDebtDetailsReportError(message: failure.message)),
      (_) async {
        if (sl.isRegistered<MyDebtsCubit>()) {
          sl<MyDebtsCubit>().loadPersons(uid, forceRefresh: true);
        }
        if (sl.isRegistered<MyDebtsSummaryCubit>()) {
          sl<MyDebtsSummaryCubit>().refreshSummary(uid);
        }
        if (sl.isRegistered<MyDebtDetailsCubit>()) {
          sl<MyDebtDetailsCubit>().loadDetails(uid, personName);
        }
        if (sl.isRegistered<InventoryPurchasesCubit>()) {
          sl<InventoryPurchasesCubit>().fetchPurchases();
        }
        await loadTransactions(uid, debtId, forceRefresh: true);

        if (state is MyDebtDetailsReportLoaded) {
          final loadedState = state as MyDebtDetailsReportLoaded;
          emit(
            MyDebtDetailsUpdateSuccess(
              transactions: loadedState.transactions,
              totalAmount: loadedState.totalAmount,
              paidAmount: loadedState.paidAmount,
              remainingAmount: loadedState.remainingAmount,
              debt: loadedState.debt,
              personName: personName,
              amountPaid: creditAmount,
              remainingBalance: loadedState.remainingAmount,
              note: AppStrings.settleSupplierCreditSuccessMsg.tr(),
              lastDocument: loadedState.lastDocument,
              hasMore: loadedState.hasMore,
              isPaginationLoading: loadedState.isPaginationLoading,
            ),
          );
        }
      },
    );
  }
}

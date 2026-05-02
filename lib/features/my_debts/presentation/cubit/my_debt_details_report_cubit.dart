import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_item_payments_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/get_my_debt_by_id_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/delete_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/update_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_state.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';

class MyDebtDetailsReportCubit extends Cubit<MyDebtDetailsReportState> {
  final GetMyDebtItemPaymentsUseCase getMyDebtItemPaymentsUseCase;
  final UpdateMyDebtPaymentUseCase updateMyDebtPaymentUseCase;
  final DeleteMyDebtPaymentUseCase deleteMyDebtPaymentUseCase;
  final GetMyDebtByIdUseCase getMyDebtByIdUseCase;

  MyDebtDetailsReportCubit({
    required this.getMyDebtItemPaymentsUseCase,
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

    final result = await getMyDebtItemPaymentsUseCase(
      GetMyDebtItemPaymentsParams(
        uid: uid,
        debtId: debtId,
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
      (transactions) {
        double totalAmount = 0;
        double paidAmount = 0;

        for (var t in transactions) {
          if (t.type == PaymentType.debtAdded) {
            totalAmount += t.amountPaid;
          } else if (t.type == PaymentType.partial ||
              t.type == PaymentType.full ||
              t.type == PaymentType.settlement) {
            paidAmount += t.amountPaid;
          } else if (t.type == PaymentType.adjustment ||
              t.type == PaymentType.reversal) {
            // Keep for backward compatibility with old ledger data
            if (t.relatedTo == 'debt') {
              totalAmount += t.amountPaid;
            } else if (t.relatedTo == 'payment') {
              paidAmount += t.amountPaid;
            }
          }
        }

        emit(
          MyDebtDetailsReportLoaded(
            transactions: transactions,
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            remainingAmount: totalAmount - paidAmount,
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

        // Trigger details refresh
        if (sl.isRegistered<MyDebtDetailsCubit>()) {
          sl<MyDebtDetailsCubit>().loadDetails(uid, customerName);
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
              customerName: customerName,
              amountPaid: newAmount, // Pass NEW amount for notification
              remainingBalance: loadedState.remainingAmount,
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

        // Trigger details refresh
        if (sl.isRegistered<MyDebtDetailsCubit>()) {
          sl<MyDebtDetailsCubit>().loadDetails(uid, customerName);
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
              customerName: customerName,
              amountPaid: amountBeingDeleted, // Absolute value for display
              remainingBalance: loadedState.remainingAmount,
              note: '',
            ),
          );
        }
      },
    );
  }
}

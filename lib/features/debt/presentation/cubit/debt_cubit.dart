import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/usecases/add_debt_usecase.dart';
import '../../domain/usecases/get_debts_usecase.dart';
import '../../domain/usecases/pay_debt_usecase.dart';
import '../../domain/usecases/mark_customer_as_paid_usecase.dart';
import '../../domain/usecases/mark_item_as_paid_usecase.dart';
import '../../domain/usecases/pay_item_debt_usecase.dart';
import 'debt_state.dart';

class DebtCubit extends Cubit<DebtState> {
  final AddDebtUseCase addDebtUseCase;
  final GetDebtsUseCase getDebtsUseCase;
  final PayDebtUseCase payDebtUseCase;
  final MarkCustomerAsPaidUseCase markCustomerAsPaidUseCase;
  final PayItemDebtUseCase payItemDebtUseCase;
  final MarkItemAsPaidUseCase markItemAsPaidUseCase;

  DebtCubit({
    required this.addDebtUseCase,
    required this.getDebtsUseCase,
    required this.payDebtUseCase,
    required this.markCustomerAsPaidUseCase,
    required this.payItemDebtUseCase,
    required this.markItemAsPaidUseCase,
  }) : super(DebtInitial());

  Future<void> addDebt(DebtEntity debt) async {
    emit(DebtLoading());
    final result = await addDebtUseCase(AddDebtParams(debt: debt));
    result.fold(
      (failure) => emit(DebtFailure(message: failure.toString())),
      (debtId) => emit(DebtAddSuccess(debtId: debtId)),
    );
  }

  Future<void> getDebts(String uid) async {
    emit(DebtLoading());
    final result = await getDebtsUseCase(GetDebtsParams(uid: uid));
    result.fold(
      (failure) => emit(DebtFailure(message: failure.toString())),
      (debts) => emit(DebtsFetchSuccess(debts: debts)),
    );
  }

  Future<void> payDebt(String uid, String customerName, double amount) async {
    emit(DebtLoading());
    final result = await payDebtUseCase(PayDebtParams(
      uid: uid,
      customerName: customerName,
      amount: amount,
    ));
    result.fold(
      (failure) => emit(DebtFailure(message: failure.toString())),
      (_) {
        emit(const DebtPaymentSuccess());
        getDebts(uid);
      },
    );
  }

  Future<void> markAsPaid(String uid, String customerName) async {
    emit(DebtLoading());
    final result = await markCustomerAsPaidUseCase(uid, customerName);
    result.fold(
      (failure) => emit(DebtFailure(message: failure.toString())),
      (_) {
        emit(const DebtPaymentSuccess());
        getDebts(uid);
      },
    );
  }

  Future<void> payItemDebt(DebtEntity debt, double amount) async {
    emit(DebtLoading());
    final result = await payItemDebtUseCase(
      PayItemDebtParams(debt: debt, amountToPay: amount),
    );
    result.fold(
      (failure) => emit(DebtFailure(message: failure.toString())),
      (_) {
        emit(const DebtPaymentSuccess());
        getDebts(debt.uid);
      },
    );
  }

  Future<void> markItemAsPaid(DebtEntity debt) async {
    emit(DebtLoading());
    final result = await markItemAsPaidUseCase(debt);
    result.fold(
      (failure) => emit(DebtFailure(message: failure.toString())),
      (_) {
        emit(const DebtPaymentSuccess());
        getDebts(debt.uid);
      },
    );
  }
}

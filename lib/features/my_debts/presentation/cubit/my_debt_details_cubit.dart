import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_entity.dart';
import 'package:tahsel/features/my_debts/domain/usecases/my_debt_usecases.dart';

part 'my_debt_details_state.dart';

class MyDebtDetailsCubit extends Cubit<MyDebtDetailsState> {
  final GetMyDebtTransactionsUseCase getTransactionsUseCase;
  final AddMyDebtTransactionUseCase addTransactionUseCase;

  MyDebtDetailsCubit({
    required this.getTransactionsUseCase,
    required this.addTransactionUseCase,
  }) : super(const MyDebtDetailsState());

  Future<void> loadTransactions(String debtId) async {
    emit(state.copyWith(status: MyDebtDetailsStatus.loading));
    final result = await getTransactionsUseCase(debtId);
    result.fold(
      (failure) => emit(state.copyWith(status: MyDebtDetailsStatus.error, message: 'Failed to load history')),
      (transactions) => emit(state.copyWith(status: MyDebtDetailsStatus.loaded, transactions: transactions)),
    );
  }

  Future<void> addPayment({
    required String debtId,
    required double amount,
    String? note,
  }) async {
    emit(state.copyWith(status: MyDebtDetailsStatus.loading));
    final transaction = MyDebtTransactionEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      debtId: debtId,
      amount: amount,
      type: 'payment',
      note: note,
      date: DateTime.now(),
    );
    final result = await addTransactionUseCase(transaction);
    result.fold(
      (failure) => emit(state.copyWith(status: MyDebtDetailsStatus.error, message: 'Failed to add payment')),
      (_) => loadTransactions(debtId),
    );
  }
  
  Future<void> addMoreDebt({
    required String debtId,
    required double amount,
    String? note,
  }) async {
    emit(state.copyWith(status: MyDebtDetailsStatus.loading));
    final transaction = MyDebtTransactionEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      debtId: debtId,
      amount: amount,
      type: 'debt',
      note: note,
      date: DateTime.now(),
    );
    final result = await addTransactionUseCase(transaction);
    result.fold(
      (failure) => emit(state.copyWith(status: MyDebtDetailsStatus.error, message: 'Failed to add debt')),
      (_) => loadTransactions(debtId),
    );
  }
}

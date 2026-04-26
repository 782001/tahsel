part of 'my_debt_details_cubit.dart';

enum MyDebtDetailsStatus { initial, loading, loaded, error }

class MyDebtDetailsState extends Equatable {
  final MyDebtDetailsStatus status;
  final List<MyDebtTransactionEntity> transactions;
  final String? message;

  const MyDebtDetailsState({
    this.status = MyDebtDetailsStatus.initial,
    this.transactions = const [],
    this.message,
  });

  MyDebtDetailsState copyWith({
    MyDebtDetailsStatus? status,
    List<MyDebtTransactionEntity>? transactions,
    String? message,
  }) {
    return MyDebtDetailsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, transactions, message];
}

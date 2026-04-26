part of 'my_debts_cubit.dart';

enum MyDebtsStatus {
  initial,
  loading,
  addingDebt,
  addingPayment,
  markingAsPaid,
  deletingDebt,
  loaded,
  error
}

class MyDebtsState extends Equatable {
  final MyDebtsStatus status;
  final List<MyDebtEntity> debts;
  final List<MyDebtEntity> filteredDebts;
  final double totalOwed;
  final double totalPaid;
  final int totalPeople;
  final String? message;
  final String? lastPaymentPerson;
  final double? lastPaymentAmount;
  final double? lastPaymentRemaining;
  final String? lastPaymentNote;

  const MyDebtsState({
    this.status = MyDebtsStatus.initial,
    this.debts = const [],
    this.filteredDebts = const [],
    this.totalOwed = 0,
    this.totalPaid = 0,
    this.totalPeople = 0,
    this.message,
    this.lastPaymentPerson,
    this.lastPaymentAmount,
    this.lastPaymentRemaining,
    this.lastPaymentNote,
  });

  MyDebtsState copyWith({
    MyDebtsStatus? status,
    List<MyDebtEntity>? debts,
    List<MyDebtEntity>? filteredDebts,
    double? totalOwed,
    double? totalPaid,
    int? totalPeople,
    String? message,
    String? lastPaymentPerson,
    double? lastPaymentAmount,
    double? lastPaymentRemaining,
    String? lastPaymentNote,
  }) {
    return MyDebtsState(
      status: status ?? this.status,
      debts: debts ?? this.debts,
      filteredDebts: filteredDebts ?? this.filteredDebts,
      totalOwed: totalOwed ?? this.totalOwed,
      totalPaid: totalPaid ?? this.totalPaid,
      totalPeople: totalPeople ?? this.totalPeople,
      message: message ?? this.message,
      lastPaymentPerson: lastPaymentPerson ?? this.lastPaymentPerson,
      lastPaymentAmount: lastPaymentAmount ?? this.lastPaymentAmount,
      lastPaymentRemaining: lastPaymentRemaining ?? this.lastPaymentRemaining,
      lastPaymentNote: lastPaymentNote ?? this.lastPaymentNote,
    );
  }

  @override
  List<Object?> get props => [
        status,
        debts,
        filteredDebts,
        totalOwed,
        totalPaid,
        totalPeople,
        message,
        lastPaymentPerson,
        lastPaymentAmount,
        lastPaymentRemaining,
        lastPaymentNote,
      ];
}

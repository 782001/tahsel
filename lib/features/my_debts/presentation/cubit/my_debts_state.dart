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
  final List<MyDebtDetail> groupedDebts;
  final double totalOwed;
  final double totalPaid;
  final int totalPeople;
  final String? message;
  final String? processingId;
  final String? lastPaymentPerson;
  final double? lastPaymentAmount;
  final double? lastPaymentRemaining;
  final String? lastPaymentNote;

  const MyDebtsState({
    this.status = MyDebtsStatus.initial,
    this.debts = const [],
    this.filteredDebts = const [],
    this.groupedDebts = const [],
    this.totalOwed = 0,
    this.totalPaid = 0,
    this.totalPeople = 0,
    this.message,
    this.processingId,
    this.lastPaymentPerson,
    this.lastPaymentAmount,
    this.lastPaymentRemaining,
    this.lastPaymentNote,
  });

  MyDebtsState copyWith({
    MyDebtsStatus? status,
    List<MyDebtEntity>? debts,
    List<MyDebtEntity>? filteredDebts,
    List<MyDebtDetail>? groupedDebts,
    double? totalOwed,
    double? totalPaid,
    int? totalPeople,
    String? message,
    String? processingId,
    String? lastPaymentPerson,
    double? lastPaymentAmount,
    double? lastPaymentRemaining,
    String? lastPaymentNote,
    bool clearProcessingId = false,
    bool clearMessage = false,
    bool clearLastPayment = false,
  }) {
    return MyDebtsState(
      status: status ?? this.status,
      debts: debts ?? this.debts,
      filteredDebts: filteredDebts ?? this.filteredDebts,
      groupedDebts: groupedDebts ?? this.groupedDebts,
      totalOwed: totalOwed ?? this.totalOwed,
      totalPaid: totalPaid ?? this.totalPaid,
      totalPeople: totalPeople ?? this.totalPeople,
      message: clearMessage ? null : (message ?? this.message),
      processingId:
          clearProcessingId ? null : (processingId ?? this.processingId),
      lastPaymentPerson:
          clearLastPayment ? null : (lastPaymentPerson ?? this.lastPaymentPerson),
      lastPaymentAmount:
          clearLastPayment ? null : (lastPaymentAmount ?? this.lastPaymentAmount),
      lastPaymentRemaining: clearLastPayment
          ? null
          : (lastPaymentRemaining ?? this.lastPaymentRemaining),
      lastPaymentNote:
          clearLastPayment ? null : (lastPaymentNote ?? this.lastPaymentNote),
    );
  }

  @override
  List<Object?> get props => [
        status,
        debts,
        filteredDebts,
        groupedDebts,
        totalOwed,
        totalPaid,
        totalPeople,
        message,
        processingId,
        lastPaymentPerson,
        lastPaymentAmount,
        lastPaymentRemaining,
        lastPaymentNote,
      ];
}

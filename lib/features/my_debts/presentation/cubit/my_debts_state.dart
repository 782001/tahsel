import 'package:equatable/equatable.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';

enum MyDebtsStatus {
  initial,
  loading,
  loaded,
  error,
  addingDebt,
  addingPayment,
  markingAsPaid,
  deletingDebt,
}

class MyDebtsState extends Equatable {
  final MyDebtsStatus status;
  final List<MyDebtPersonEntity> persons;
  final List<MyDebtPersonEntity> filteredPersons;
  final double totalOwed;
  final double totalPaid;
  final int totalPeople;
  final String? message;
  final String? processingId;

  // Last payment info for success dialogs
  final String? lastPaymentPerson;
  final double? lastPaymentAmount;
  final double? lastPaymentRemaining;
  final String? lastPaymentNote;

  const MyDebtsState({
    this.status = MyDebtsStatus.initial,
    this.persons = const [],
    this.filteredPersons = const [],
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
    List<MyDebtPersonEntity>? persons,
    List<MyDebtPersonEntity>? filteredPersons,
    double? totalOwed,
    double? totalPaid,
    int? totalPeople,
    String? message,
    String? processingId,
    String? lastPaymentPerson,
    double? lastPaymentAmount,
    double? lastPaymentRemaining,
    String? lastPaymentNote,
    bool clearMessage = false,
    bool clearProcessingId = false,
    bool clearLastPayment = false,
  }) {
    return MyDebtsState(
      status: status ?? this.status,
      persons: persons ?? this.persons,
      filteredPersons: filteredPersons ?? this.filteredPersons,
      totalOwed: totalOwed ?? this.totalOwed,
      totalPaid: totalPaid ?? this.totalPaid,
      totalPeople: totalPeople ?? this.totalPeople,
      message: clearMessage ? null : (message ?? this.message),
      processingId: clearProcessingId
          ? null
          : (processingId ?? this.processingId),
      lastPaymentPerson: clearLastPayment
          ? null
          : (lastPaymentPerson ?? this.lastPaymentPerson),
      lastPaymentAmount: clearLastPayment
          ? null
          : (lastPaymentAmount ?? this.lastPaymentAmount),
      lastPaymentRemaining: clearLastPayment
          ? null
          : (lastPaymentRemaining ?? this.lastPaymentRemaining),
      lastPaymentNote: clearLastPayment
          ? null
          : (lastPaymentNote ?? this.lastPaymentNote),
    );
  }

  @override
  List<Object?> get props => [
    status,
    persons,
    filteredPersons,
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

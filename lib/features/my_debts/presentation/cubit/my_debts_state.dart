import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';

enum MyDebtsStatus {
  initial,
  loading,
  loaded,
  offlineLoaded,
  syncSuccess,
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

  // Pagination parameters
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isPaginationLoading;

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
    this.lastDocument,
    this.hasMore = false,
    this.isPaginationLoading = false,
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
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isPaginationLoading,
    bool clearMessage = false,
    bool clearProcessingId = false,
    bool clearLastPayment = false,
    bool clearLastDocument = false,
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
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
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
    lastDocument,
    hasMore,
    isPaginationLoading,
  ];
}

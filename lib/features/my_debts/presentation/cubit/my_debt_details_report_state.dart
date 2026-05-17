import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';

abstract class MyDebtDetailsReportState extends Equatable {
  const MyDebtDetailsReportState();

  @override
  List<Object?> get props => [];
}

class MyDebtDetailsReportLoading extends MyDebtDetailsReportState {}

class MyDebtDetailsReportLoaded extends MyDebtDetailsReportState {
  final List<PaymentEntity> transactions;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final MyDebtItemEntity? debt;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isPaginationLoading;

  const MyDebtDetailsReportLoaded({
    required this.transactions,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.debt,
    this.lastDocument,
    this.hasMore = false,
    this.isPaginationLoading = false,
  });

  MyDebtDetailsReportLoaded copyWith({
    List<PaymentEntity>? transactions,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    MyDebtItemEntity? debt,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isPaginationLoading,
    bool clearLastDocument = false,
  }) {
    return MyDebtDetailsReportLoaded(
      transactions: transactions ?? this.transactions,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      debt: debt ?? this.debt,
      lastDocument: clearLastDocument ? null : (lastDocument ?? this.lastDocument),
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    totalAmount,
    paidAmount,
    remainingAmount,
    debt,
    lastDocument,
    hasMore,
    isPaginationLoading,
  ];
}

class MyDebtDetailsReportNotFound extends MyDebtDetailsReportState {}

class MyDebtDetailsReportError extends MyDebtDetailsReportState {
  final String message;

  const MyDebtDetailsReportError({required this.message});

  @override
  List<Object?> get props => [message];
}

class MyDebtDetailsUpdateSuccess extends MyDebtDetailsReportState {
  final List<PaymentEntity> transactions;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final MyDebtItemEntity? debt;
  final String customerName;
  final double amountPaid;
  final double remainingBalance;
  final String note;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isPaginationLoading;

  const MyDebtDetailsUpdateSuccess({
    required this.transactions,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.debt,
    required this.customerName,
    required this.amountPaid,
    required this.remainingBalance,
    required this.note,
    this.lastDocument,
    this.hasMore = false,
    this.isPaginationLoading = false,
  });

  @override
  List<Object?> get props => [
    transactions,
    totalAmount,
    paidAmount,
    remainingAmount,
    debt,
    customerName,
    amountPaid,
    remainingBalance,
    note,
    lastDocument,
    hasMore,
    isPaginationLoading,
  ];
}

class MyDebtDetailsDeleteSuccess extends MyDebtDetailsReportState {
  final List<PaymentEntity> transactions;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final MyDebtItemEntity? debt;
  final String customerName;
  final double amountPaid;
  final double remainingBalance;
  final String note;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isPaginationLoading;

  const MyDebtDetailsDeleteSuccess({
    required this.transactions,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.debt,
    required this.customerName,
    required this.amountPaid,
    required this.remainingBalance,
    required this.note,
    this.lastDocument,
    this.hasMore = false,
    this.isPaginationLoading = false,
  });

  @override
  List<Object?> get props => [
    transactions,
    totalAmount,
    paidAmount,
    remainingAmount,
    debt,
    customerName,
    amountPaid,
    remainingBalance,
    note,
    lastDocument,
    hasMore,
    isPaginationLoading,
  ];
}

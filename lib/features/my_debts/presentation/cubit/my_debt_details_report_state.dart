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

  const MyDebtDetailsReportLoaded({
    required this.transactions,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.debt,
  });

  @override
  List<Object?> get props => [
    transactions,
    totalAmount,
    paidAmount,
    remainingAmount,
    debt,
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
  ];
}

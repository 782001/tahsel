import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_entity.dart';
import '../../../domain/entities/debt_entity.dart';

abstract class DebtDetailsState extends Equatable {
  const DebtDetailsState();

  @override
  List<Object?> get props => [];
}

class DebtDetailsInitial extends DebtDetailsState {}

class DebtDetailsLoading extends DebtDetailsState {}

class DebtDetailsLoaded extends DebtDetailsState {
  final List<PaymentEntity> transactions;
  final double totalAmount;
  final double totalPaid;
  final double remainingDebt;
  final DebtEntity? debt;

  const DebtDetailsLoaded({
    required this.transactions,
    required this.totalAmount,
    required this.totalPaid,
    required this.remainingDebt,
    this.debt,
  });

  @override
  List<Object?> get props => [
    transactions,
    totalAmount,
    totalPaid,
    remainingDebt,
    debt,
  ];
}

class DebtDetailsNotFound extends DebtDetailsState {}

class DebtDetailsError extends DebtDetailsState {
  final String message;

  const DebtDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

class DebtDetailsUpdateSuccess extends DebtDetailsState {
  final List<PaymentEntity> transactions;
  final double totalAmount;
  final double totalPaid;
  final double remainingDebt;
  final DebtEntity? debt;
  final String customerName;
  final double amountPaid;
  final double remainingBalance;
  final String note;

  const DebtDetailsUpdateSuccess({
    required this.transactions,
    required this.totalAmount,
    required this.totalPaid,
    required this.remainingDebt,
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
    totalPaid,
    remainingDebt,
    debt,
    customerName,
    amountPaid,
    remainingBalance,
    note,
  ];
}

class DebtDetailsDeleteSuccess extends DebtDetailsState {
  final List<PaymentEntity> transactions;
  final double totalAmount;
  final double totalPaid;
  final double remainingDebt;
  final DebtEntity? debt;
  final String customerName;
  final double amountPaid;
  final double remainingBalance;
  final String note;

  const DebtDetailsDeleteSuccess({
    required this.transactions,
    required this.totalAmount,
    required this.totalPaid,
    required this.remainingDebt,
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
    totalPaid,
    remainingDebt,
    debt,
    customerName,
    amountPaid,
    remainingBalance,
    note,
  ];
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/debt_entity.dart';

abstract class DebtState extends Equatable {
  const DebtState();

  @override
  List<Object?> get props => [];
}

class DebtInitial extends DebtState {}

class DebtLoading extends DebtState {}

class DebtAddSuccess extends DebtState {
  final String debtId;
  const DebtAddSuccess({required this.debtId});

  @override
  List<Object?> get props => [debtId];
}

class DebtsFetchSuccess extends DebtState {
  final List<DebtEntity> debts;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isPaginationLoading;

  const DebtsFetchSuccess({
    required this.debts,
    this.lastDocument,
    this.hasMore = false,
    this.isPaginationLoading = false,
  });

  DebtsFetchSuccess copyWith({
    List<DebtEntity>? debts,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isPaginationLoading,
  }) {
    return DebtsFetchSuccess(
      debts: debts ?? this.debts,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
    );
  }

  @override
  List<Object?> get props => [debts, lastDocument, hasMore, isPaginationLoading];
}

class DebtPaymentSuccess extends DebtState {
  final String customerName;
  final double amountPaid;
  final double remainingBalance;
  final String? note;

  const DebtPaymentSuccess({
    required this.customerName,
    required this.amountPaid,
    required this.remainingBalance,
    this.note,
  });

  @override
  List<Object?> get props => [customerName, amountPaid, remainingBalance, note];
}

class DebtDeleteSuccess extends DebtState {
  const DebtDeleteSuccess();
}

class DebtFailure extends DebtState {
  final String message;
  const DebtFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

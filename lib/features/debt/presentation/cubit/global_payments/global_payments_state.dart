import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/payment_entity.dart';

abstract class GlobalPaymentsState extends Equatable {
  const GlobalPaymentsState();

  @override
  List<Object?> get props => [];
}

class GlobalPaymentsInitial extends GlobalPaymentsState {}

class GlobalPaymentsLoading extends GlobalPaymentsState {}

class GlobalPaymentsLoaded extends GlobalPaymentsState {
  final List<PaymentEntity> transactions;
  final double totalPaid;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isPaginationLoading;

  const GlobalPaymentsLoaded({
    required this.transactions,
    required this.totalPaid,
    this.lastDocument,
    this.hasMore = false,
    this.isPaginationLoading = false,
  });

  GlobalPaymentsLoaded copyWith({
    List<PaymentEntity>? transactions,
    double? totalPaid,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isPaginationLoading,
  }) {
    return GlobalPaymentsLoaded(
      transactions: transactions ?? this.transactions,
      totalPaid: totalPaid ?? this.totalPaid,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    totalPaid,
    lastDocument,
    hasMore,
    isPaginationLoading,
  ];
}

class GlobalPaymentsError extends GlobalPaymentsState {
  final String message;

  const GlobalPaymentsError(this.message);

  @override
  List<Object?> get props => [message];
}

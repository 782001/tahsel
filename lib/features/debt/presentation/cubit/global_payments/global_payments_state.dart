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

  const GlobalPaymentsLoaded({
    required this.transactions,
    required this.totalPaid,
  });

  @override
  List<Object?> get props => [transactions, totalPaid];
}

class GlobalPaymentsError extends GlobalPaymentsState {
  final String message;

  const GlobalPaymentsError(this.message);

  @override
  List<Object?> get props => [message];
}

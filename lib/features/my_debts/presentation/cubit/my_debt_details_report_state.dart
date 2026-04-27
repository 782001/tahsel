import 'package:equatable/equatable.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';

abstract class MyDebtDetailsReportState extends Equatable {
  const MyDebtDetailsReportState();
  
  @override
  List<Object> get props => [];
}

class MyDebtDetailsReportLoading extends MyDebtDetailsReportState {}

class MyDebtDetailsReportLoaded extends MyDebtDetailsReportState {
  final List<PaymentEntity> transactions;

  const MyDebtDetailsReportLoaded({required this.transactions});

  @override
  List<Object> get props => [transactions];
}

class MyDebtDetailsReportError extends MyDebtDetailsReportState {
  final String message;

  const MyDebtDetailsReportError({required this.message});

  @override
  List<Object> get props => [message];
}

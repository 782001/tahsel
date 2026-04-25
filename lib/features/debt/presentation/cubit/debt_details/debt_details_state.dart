import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_entity.dart';

abstract class DebtDetailsState extends Equatable {
  const DebtDetailsState();

  @override
  List<Object?> get props => [];
}

class DebtDetailsInitial extends DebtDetailsState {}

class DebtDetailsLoading extends DebtDetailsState {}

class DebtDetailsLoaded extends DebtDetailsState {
  final List<PaymentEntity> transactions;

  const DebtDetailsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class DebtDetailsError extends DebtDetailsState {
  final String message;

  const DebtDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

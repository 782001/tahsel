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
  const DebtsFetchSuccess({required this.debts});

  @override
  List<Object?> get props => [debts];
}

class DebtFailure extends DebtState {
  final String message;
  const DebtFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

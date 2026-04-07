part of 'income_details_cubit.dart';

abstract class IncomeDetailsState extends Equatable {
  const IncomeDetailsState();

  @override
  List<Object?> get props => [];
}

class IncomeDetailsInitial extends IncomeDetailsState {}

class IncomeDetailsLoading extends IncomeDetailsState {}

class IncomeDetailsLoaded extends IncomeDetailsState {
  final List<OperationEntity> operations;

  const IncomeDetailsLoaded({required this.operations});

  @override
  List<Object?> get props => [operations];
}

class IncomeDetailsError extends IncomeDetailsState {
  final String message;

  const IncomeDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

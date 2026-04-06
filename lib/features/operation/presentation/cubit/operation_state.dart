import 'package:equatable/equatable.dart';

abstract class OperationState extends Equatable {
  const OperationState();

  @override
  List<Object> get props => [];
}

class OperationInitial extends OperationState {}

class OperationLoading extends OperationState {}

class OperationSuccess extends OperationState {
  final String message;

  const OperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class OperationFailure extends OperationState {
  final String message;

  const OperationFailure({required this.message});

  @override
  List<Object> get props => [message];
}

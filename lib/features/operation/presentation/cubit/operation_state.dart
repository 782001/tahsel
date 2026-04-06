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
  final String operationId;

  const OperationSuccess({required this.message, required this.operationId});

  @override
  List<Object> get props => [message, operationId];
}

class OperationFailure extends OperationState {
  final String message;

  const OperationFailure({required this.message});

  @override
  List<Object> get props => [message];
}

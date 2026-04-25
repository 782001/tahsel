import 'package:equatable/equatable.dart';

abstract class TotalDebtsState extends Equatable {
  const TotalDebtsState();

  @override
  List<Object> get props => [];
}

class TotalDebtsInitial extends TotalDebtsState {}

class TotalDebtsLoading extends TotalDebtsState {}

class TotalDebtsLoaded extends TotalDebtsState {
  final double totalAmount;
  final int customerCount;

  const TotalDebtsLoaded({
    required this.totalAmount,
    required this.customerCount,
  });

  @override
  List<Object> get props => [totalAmount, customerCount];
}

class TotalDebtsError extends TotalDebtsState {
  final String message;

  const TotalDebtsError(this.message);

  @override
  List<Object> get props => [message];
}

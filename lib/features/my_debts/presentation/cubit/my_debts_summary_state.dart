import 'package:equatable/equatable.dart';

abstract class MyDebtsSummaryState extends Equatable {
  const MyDebtsSummaryState();

  @override
  List<Object?> get props => [];
}

class MyDebtsSummaryInitial extends MyDebtsSummaryState {}

class MyDebtsSummaryLoading extends MyDebtsSummaryState {}

class MyDebtsSummaryLoaded extends MyDebtsSummaryState {
  final double totalOwed;
  final double totalPaid;
  final int totalPeople;

  const MyDebtsSummaryLoaded({
    required this.totalOwed,
    required this.totalPaid,
    required this.totalPeople,
  });

  @override
  List<Object?> get props => [totalOwed, totalPaid, totalPeople];
}

class MyDebtsSummaryError extends MyDebtsSummaryState {
  final String message;

  const MyDebtsSummaryError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import 'package:tahsel/features/debt/domain/entities/monthly_collected_amount.dart';

abstract class MonthlyCollectedState extends Equatable {
  const MonthlyCollectedState();

  @override
  List<Object?> get props => [];
}

class MonthlyCollectedInitial extends MonthlyCollectedState {}

class MonthlyCollectedLoading extends MonthlyCollectedState {}

class MonthlyCollectedSuccess extends MonthlyCollectedState {
  final List<MonthlyCollectedAmount> data;
  const MonthlyCollectedSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class MonthlyCollectedError extends MonthlyCollectedState {
  final String message;
  const MonthlyCollectedError(this.message);

  @override
  List<Object?> get props => [message];
}

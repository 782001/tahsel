import 'package:equatable/equatable.dart';
import '../../domain/entities/reports_entity.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsSuccess extends ReportsState {
  final ReportsEntity reports;
  const ReportsSuccess(this.reports);
  @override
  List<Object?> get props => [reports];
}

class ReportsError extends ReportsState {
  final String message;
  const ReportsError(this.message);
  @override
  List<Object?> get props => [message];
}

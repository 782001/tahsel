import 'package:equatable/equatable.dart';
import '../../data/models/app_employee_model.dart';

abstract class TeamManagementState extends Equatable {
  const TeamManagementState();

  @override
  List<Object?> get props => [];
}

class TeamManagementInitial extends TeamManagementState {}

class TeamManagementLoading extends TeamManagementState {}

class TeamManagementLoaded extends TeamManagementState {
  final List<AppEmployeeModel> employees;

  const TeamManagementLoaded(this.employees);

  @override
  List<Object?> get props => [employees];
}

class TeamManagementActionSuccess extends TeamManagementState {
  final String message;

  const TeamManagementActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TeamManagementFailure extends TeamManagementState {
  final String message;

  const TeamManagementFailure(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/customer_operation.dart';

abstract class CustomerDetailsState extends Equatable {
  const CustomerDetailsState();

  @override
  List<Object?> get props => [];
}

class CustomerDetailsInitial extends CustomerDetailsState {}

class CustomerDetailsLoading extends CustomerDetailsState {}

class CustomerDetailsLoaded extends CustomerDetailsState {
  final List<CustomerOperation> operations;
  final double totalSpent;
  final double totalPaid;
  final double remaining;

  const CustomerDetailsLoaded({
    required this.operations,
    required this.totalSpent,
    required this.totalPaid,
    required this.remaining,
  });

  @override
  List<Object?> get props => [operations, totalSpent, totalPaid, remaining];
}

class CustomerDetailsError extends CustomerDetailsState {
  final String message;

  const CustomerDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

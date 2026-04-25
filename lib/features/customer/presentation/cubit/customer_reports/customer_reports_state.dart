import 'package:equatable/equatable.dart';
import '../../../domain/entities/customer_entity.dart';

abstract class CustomerReportsState extends Equatable {
  const CustomerReportsState();

  @override
  List<Object?> get props => [];
}

class CustomerReportsInitial extends CustomerReportsState {}

class CustomerReportsLoading extends CustomerReportsState {}

class CustomerReportsLoaded extends CustomerReportsState {
  final List<CustomerEntity> customers;
  final List<CustomerEntity> filteredCustomers;
  final String searchQuery;

  const CustomerReportsLoaded({
    required this.customers,
    required this.filteredCustomers,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [customers, filteredCustomers, searchQuery];
}

class CustomerReportsError extends CustomerReportsState {
  final String message;

  const CustomerReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

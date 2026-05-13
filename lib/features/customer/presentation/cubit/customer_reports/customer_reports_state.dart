import 'package:cloud_firestore/cloud_firestore.dart';
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
  final bool hasReachedMax;
  final DocumentSnapshot? lastDoc;
  final bool isFetchingMore;

  const CustomerReportsLoaded({
    required this.customers,
    required this.filteredCustomers,
    this.searchQuery = '',
    this.hasReachedMax = false,
    this.lastDoc,
    this.isFetchingMore = false,
  });

  CustomerReportsLoaded copyWith({
    List<CustomerEntity>? customers,
    List<CustomerEntity>? filteredCustomers,
    String? searchQuery,
    bool? hasReachedMax,
    DocumentSnapshot? lastDoc,
    bool? isFetchingMore,
  }) {
    return CustomerReportsLoaded(
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      searchQuery: searchQuery ?? this.searchQuery,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      lastDoc: lastDoc ?? this.lastDoc,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }

  @override
  List<Object?> get props => [
    customers,
    filteredCustomers,
    searchQuery,
    hasReachedMax,
    lastDoc,
    isFetchingMore,
  ];
}

class CustomerReportsError extends CustomerReportsState {
  final String message;

  const CustomerReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

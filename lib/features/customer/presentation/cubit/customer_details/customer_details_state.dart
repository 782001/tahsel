import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/customer_operation.dart';

abstract class CustomerDetailsState extends Equatable {
  const CustomerDetailsState();

  @override
  List<Object?> get props => [];
}

class CustomerDetailsInitial extends CustomerDetailsState {}

class CustomerDetailsLoading extends CustomerDetailsState {}

class CustomerDetailsLoaded extends CustomerDetailsState {
  final List<CustomerOperation> allOperations;
  final List<CustomerOperation> operations;
  final double totalSpent;
  final double totalPaid;
  final double remaining;
  final double openingBalance;
  final bool hasReachedMax;
  final DocumentSnapshot? lastDoc;
  final bool isFetchingMore;
  final CustomerEntity? customer;
  final String selectedFilter; // 'all', 'thisMonth', 'lastMonth', 'custom'
  final DateTime? startDate;
  final DateTime? endDate;

  const CustomerDetailsLoaded({
    required this.operations,
    List<CustomerOperation>? allOperations,
    required this.totalSpent,
    required this.totalPaid,
    required this.remaining,
    this.openingBalance = 0.0,
    this.hasReachedMax = false,
    this.lastDoc,
    this.isFetchingMore = false,
    this.customer,
    this.selectedFilter = 'all',
    this.startDate,
    this.endDate,
  }) : allOperations = allOperations ?? operations;

  CustomerDetailsLoaded copyWith({
    List<CustomerOperation>? allOperations,
    List<CustomerOperation>? operations,
    double? totalSpent,
    double? totalPaid,
    double? remaining,
    double? openingBalance,
    bool? hasReachedMax,
    DocumentSnapshot? lastDoc,
    bool? isFetchingMore,
    CustomerEntity? customer,
    String? selectedFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CustomerDetailsLoaded(
      allOperations: allOperations ?? this.allOperations,
      operations: operations ?? this.operations,
      totalSpent: totalSpent ?? this.totalSpent,
      totalPaid: totalPaid ?? this.totalPaid,
      remaining: remaining ?? this.remaining,
      openingBalance: openingBalance ?? this.openingBalance,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      lastDoc: lastDoc ?? this.lastDoc,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      customer: customer ?? this.customer,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
    allOperations,
    operations,
    totalSpent,
    totalPaid,
    remaining,
    openingBalance,
    hasReachedMax,
    lastDoc,
    isFetchingMore,
    customer,
    selectedFilter,
    startDate,
    endDate,
  ];
}

class CustomerDetailsError extends CustomerDetailsState {
  final String message;

  const CustomerDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

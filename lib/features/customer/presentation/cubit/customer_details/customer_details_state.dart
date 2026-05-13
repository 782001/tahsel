import 'package:cloud_firestore/cloud_firestore.dart';
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
  final bool hasReachedMax;
  final DocumentSnapshot? lastDoc;
  final bool isFetchingMore;

  const CustomerDetailsLoaded({
    required this.operations,
    required this.totalSpent,
    required this.totalPaid,
    required this.remaining,
    this.hasReachedMax = false,
    this.lastDoc,
    this.isFetchingMore = false,
  });

  CustomerDetailsLoaded copyWith({
    List<CustomerOperation>? operations,
    double? totalSpent,
    double? totalPaid,
    double? remaining,
    bool? hasReachedMax,
    DocumentSnapshot? lastDoc,
    bool? isFetchingMore,
  }) {
    return CustomerDetailsLoaded(
      operations: operations ?? this.operations,
      totalSpent: totalSpent ?? this.totalSpent,
      totalPaid: totalPaid ?? this.totalPaid,
      remaining: remaining ?? this.remaining,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      lastDoc: lastDoc ?? this.lastDoc,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }

  @override
  List<Object?> get props => [
    operations,
    totalSpent,
    totalPaid,
    remaining,
    hasReachedMax,
    lastDoc,
    isFetchingMore,
  ];
}

class CustomerDetailsError extends CustomerDetailsState {
  final String message;

  const CustomerDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

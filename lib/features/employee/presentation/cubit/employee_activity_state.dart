import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/employee_activity_entity.dart';
import '../../data/datasources/employee_activity_remote_data_source.dart';

abstract class EmployeeActivityState extends Equatable {
  const EmployeeActivityState();

  @override
  List<Object?> get props => [];
}

class EmployeeActivityInitial extends EmployeeActivityState {
  const EmployeeActivityInitial();
}

class EmployeeActivityLoading extends EmployeeActivityState {
  const EmployeeActivityLoading();
}

class EmployeeActivityLoaded extends EmployeeActivityState {
  final List<EmployeeActivityEntity> activities;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isLoadingMore;
  final String selectedCategory;
  final DateTimeRange? selectedDateRange;
  final EmployeeActivityStats stats;
  final String? errorMessage;

  const EmployeeActivityLoaded({
    required this.activities,
    this.lastDocument,
    required this.hasMore,
    this.isLoadingMore = false,
    this.selectedCategory = 'all',
    this.selectedDateRange,
    this.stats = const EmployeeActivityStats(),
    this.errorMessage,
  });

  EmployeeActivityLoaded copyWith({
    List<EmployeeActivityEntity>? activities,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isLoadingMore,
    String? selectedCategory,
    DateTimeRange? selectedDateRange,
    bool clearDateRange = false,
    EmployeeActivityStats? stats,
    String? errorMessage,
  }) {
    return EmployeeActivityLoaded(
      activities: activities ?? this.activities,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedDateRange:
          clearDateRange ? null : (selectedDateRange ?? this.selectedDateRange),
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        activities,
        lastDocument,
        hasMore,
        isLoadingMore,
        selectedCategory,
        selectedDateRange,
        stats,
        errorMessage,
      ];
}

class EmployeeActivityError extends EmployeeActivityState {
  final String message;

  const EmployeeActivityError({required this.message});

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/column_mapping_entity.dart';
import '../../domain/entities/order_reconciliation_item.dart';
import '../../domain/entities/reconciliation_dashboard.dart';
import '../../domain/repositories/shipping_reconciliation_repository.dart';

enum ReconciliationFilterChip {
  all,
  delivered,
  returned,
  notShipped,
  fullyCollected,
  partiallyCollected,
  notCollected,
  conflicts,
  missing,
}

abstract class ShippingReconciliationState extends Equatable {
  const ShippingReconciliationState();

  @override
  List<Object?> get props => [];
}

class ShippingReconciliationInitial extends ShippingReconciliationState {}

class ShippingReconciliationFilesLoaded extends ShippingReconciliationState {
  final RawFileData? internalFile;
  final FileColumnMappingEntity? internalMapping;
  final RawFileData? shippingFile;
  final FileColumnMappingEntity? shippingMapping;
  final String? errorMessage;

  const ShippingReconciliationFilesLoaded({
    this.internalFile,
    this.internalMapping,
    this.shippingFile,
    this.shippingMapping,
    this.errorMessage,
  });

  bool get canProceed =>
      internalFile != null &&
      shippingFile != null &&
      internalMapping != null &&
      shippingMapping != null;

  bool get needsMappingReview =>
      (internalMapping != null && !internalMapping!.isConfident) ||
      (shippingMapping != null && !shippingMapping!.isConfident);

  ShippingReconciliationFilesLoaded copyWith({
    RawFileData? internalFile,
    FileColumnMappingEntity? internalMapping,
    RawFileData? shippingFile,
    FileColumnMappingEntity? shippingMapping,
    String? errorMessage,
  }) {
    return ShippingReconciliationFilesLoaded(
      internalFile: internalFile ?? this.internalFile,
      internalMapping: internalMapping ?? this.internalMapping,
      shippingFile: shippingFile ?? this.shippingFile,
      shippingMapping: shippingMapping ?? this.shippingMapping,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        internalFile,
        internalMapping,
        shippingFile,
        shippingMapping,
        errorMessage,
      ];
}

class ShippingReconciliationMappingReviewState
    extends ShippingReconciliationState {
  final RawFileData internalFile;
  final FileColumnMappingEntity internalMapping;
  final RawFileData shippingFile;
  final FileColumnMappingEntity shippingMapping;

  const ShippingReconciliationMappingReviewState({
    required this.internalFile,
    required this.internalMapping,
    required this.shippingFile,
    required this.shippingMapping,
  });

  @override
  List<Object?> get props => [
        internalFile,
        internalMapping,
        shippingFile,
        shippingMapping,
      ];
}

class ShippingReconciliationProcessingState
    extends ShippingReconciliationState {
  final String message;

  const ShippingReconciliationProcessingState({required this.message});

  @override
  List<Object?> get props => [message];
}

class ShippingReconciliationSuccessState
    extends ShippingReconciliationState {
  final ReconciliationDashboard dashboard;
  final List<OrderReconciliationItem> allItems;
  final List<OrderReconciliationItem> filteredItems;
  final String searchQuery;
  final ReconciliationFilterChip selectedFilter;

  const ShippingReconciliationSuccessState({
    required this.dashboard,
    required this.allItems,
    required this.filteredItems,
    required this.searchQuery,
    required this.selectedFilter,
  });

  ShippingReconciliationSuccessState copyWith({
    ReconciliationDashboard? dashboard,
    List<OrderReconciliationItem>? allItems,
    List<OrderReconciliationItem>? filteredItems,
    String? searchQuery,
    ReconciliationFilterChip? selectedFilter,
  }) {
    return ShippingReconciliationSuccessState(
      dashboard: dashboard ?? this.dashboard,
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  @override
  List<Object?> get props => [
        dashboard,
        allItems,
        filteredItems,
        searchQuery,
        selectedFilter,
      ];
}

class ShippingReconciliationFailureState
    extends ShippingReconciliationState {
  final String errorMessage;

  const ShippingReconciliationFailureState({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

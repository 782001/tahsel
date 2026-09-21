import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/customer_operation.dart';
import '../../../domain/usecases/get_customer_operations_usecase.dart';
import 'customer_details_state.dart';

class CustomerDetailsCubit extends Cubit<CustomerDetailsState> {
  final GetCustomerOperationsUseCase getCustomerOperationsUseCase;
  static const int _pageSize = 20;

  CustomerDetailsCubit({required this.getCustomerOperationsUseCase})
    : super(CustomerDetailsInitial());

  @override
  void emit(CustomerDetailsState state) {
    if (isClosed) return;
    super.emit(state);
  }

  void setCustomer(CustomerEntity customer) {
    final currentState = state;
    if (currentState is CustomerDetailsLoaded) {
      emit(currentState.copyWith(customer: customer));
    }
  }

  Future<void> fetchOperations(
    String uid,
    String customerName, {
    CustomerEntity? customer,
  }) async {
    emit(CustomerDetailsLoading());

    // Fetch all customer operations for a complete, mathematically coherent statement
    final result = await getCustomerOperationsUseCase(
      uid: uid,
      customerName: customerName,
      limit: 0,
    );

    result.fold(
      (failure) => emit(CustomerDetailsError(failure.message)),
      (paginatedData) {
        final operations = paginatedData.$1;
        final lastDoc = paginatedData.$2;
        final totalSpent = paginatedData.$3;
        final totalPaid = paginatedData.$4;
        final fetchedCustomer = paginatedData.$5;

        emit(
          CustomerDetailsLoaded(
            operations: operations,
            allOperations: operations,
            totalSpent: totalSpent,
            totalPaid: totalPaid,
            remaining: totalSpent - totalPaid,
            lastDoc: lastDoc,
            hasReachedMax: true,
            customer: customer ?? fetchedCustomer,
            selectedFilter: 'all',
          ),
        );
      },
    );
  }

  Future<void> fetchMoreOperations(String uid, String customerName) async {
    final currentState = state;
    if (currentState is! CustomerDetailsLoaded ||
        currentState.isFetchingMore ||
        currentState.hasReachedMax) {
      return;
    }

    emit(currentState.copyWith(isFetchingMore: true));

    final result = await getCustomerOperationsUseCase(
      uid: uid,
      customerName: customerName,
      limit: _pageSize,
      lastDoc: currentState.lastDoc,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isFetchingMore: false)),
      (paginatedData) {
        final newOperations = paginatedData.$1;
        final lastDoc = paginatedData.$2;

        if (newOperations.isEmpty) {
          emit(
            currentState.copyWith(hasReachedMax: true, isFetchingMore: false),
          );
          return;
        }

        final allOperations = List<CustomerOperation>.from(
          currentState.allOperations,
        )..addAll(newOperations);

        // Re-apply current filter in memory
        _applyFilter(
          currentState.selectedFilter,
          allOperations: allOperations,
          lastDoc: lastDoc,
          hasReachedMax: newOperations.length < _pageSize,
          isFetchingMore: false,
          customStart: currentState.startDate,
          customEnd: currentState.endDate,
        );
      },
    );
  }

  /// In-memory date filtering without triggering any extra Firestore reads
  void filterByPeriod(
    String filterType, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final currentState = state;
    if (currentState is! CustomerDetailsLoaded) return;

    _applyFilter(
      filterType,
      allOperations: currentState.allOperations,
      lastDoc: currentState.lastDoc,
      hasReachedMax: currentState.hasReachedMax,
      isFetchingMore: false,
      customStart: customStart,
      customEnd: customEnd,
    );
  }

  void _applyFilter(
    String filterType, {
    required List<CustomerOperation> allOperations,
    DocumentSnapshot? lastDoc,
    required bool hasReachedMax,
    required bool isFetchingMore,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final currentState = state;
    if (currentState is! CustomerDetailsLoaded) return;

    DateTime? startDate;
    DateTime? endDate;

    final now = DateTime.now();

    switch (filterType) {
      case 'thisMonth':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'lastMonth':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'custom':
        startDate = customStart != null
            ? DateTime(customStart.year, customStart.month, customStart.day, 0, 0, 0)
            : null;
        endDate = customEnd != null
            ? DateTime(customEnd.year, customEnd.month, customEnd.day, 23, 59, 59)
            : null;
        break;
      case 'all':
      default:
        startDate = null;
        endDate = null;
        break;
    }

    // Always sort chronologically (oldest to newest) to guarantee accurate math
    final sortedAll = List<CustomerOperation>.from(allOperations)
      ..sort((a, b) {
        final cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        if (a.type != b.type) {
          if (a.type == CustomerOperationType.payment) return 1;
          if (b.type == CustomerOperationType.payment) return -1;
        }
        return 0;
      });

    if (startDate == null && endDate == null) {
      double totalSpent = 0.0;
      double totalPaid = 0.0;
      double running = 0.0;
      final List<CustomerOperation> balancedAll = [];

      for (var op in sortedAll) {
        if (op.type == CustomerOperationType.quotation) {
          // Quotations have no financial impact
        } else if (op.type == CustomerOperationType.payment) {
          totalPaid += op.amount;
          running -= op.amount;
        } else {
          totalSpent += op.amount;
          running += op.amount;
        }
        balancedAll.add(op.copyWith(runningBalance: running));
      }

      final displayAll = balancedAll.reversed.toList();

      emit(
        currentState.copyWith(
          allOperations: displayAll,
          operations: displayAll,
          totalSpent: totalSpent,
          totalPaid: totalPaid,
          remaining: totalSpent - totalPaid,
          openingBalance: 0.0,
          selectedFilter: 'all',
          startDate: null,
          endDate: null,
          lastDoc: lastDoc,
          hasReachedMax: hasReachedMax,
          isFetchingMore: isFetchingMore,
        ),
      );
      return;
    }

    // Calculate opening balance before startDate and period running balance
    double openingBalance = 0.0;
    final List<CustomerOperation> periodChronological = [];
    double periodSpent = 0.0;
    double periodPaid = 0.0;

    for (var op in sortedAll) {
      if (startDate != null && op.date.isBefore(startDate)) {
        if (op.type == CustomerOperationType.quotation) {
          // Quotations have no impact on opening balance
        } else if (op.type == CustomerOperationType.payment) {
          openingBalance -= op.amount;
        } else {
          openingBalance += op.amount;
        }
      } else if ((startDate == null || !op.date.isBefore(startDate)) &&
          (endDate == null || !op.date.isAfter(endDate))) {
        if (op.type == CustomerOperationType.quotation) {
          // Quotations have no impact on period spent/paid
        } else if (op.type == CustomerOperationType.payment) {
          periodPaid += op.amount;
        } else {
          periodSpent += op.amount;
        }
        final double runningInPeriod = openingBalance + periodSpent - periodPaid;
        periodChronological.add(op.copyWith(runningBalance: runningInPeriod));
      }
    }

    final double periodRemaining = openingBalance + periodSpent - periodPaid;
    final displayFiltered = periodChronological.reversed.toList();

    emit(
      currentState.copyWith(
        allOperations: sortedAll.reversed.toList(),
        operations: displayFiltered,
        totalSpent: periodSpent,
        totalPaid: periodPaid,
        remaining: periodRemaining,
        openingBalance: openingBalance,
        selectedFilter: filterType,
        startDate: startDate,
        endDate: endDate,
        lastDoc: lastDoc,
        hasReachedMax: hasReachedMax,
        isFetchingMore: isFetchingMore,
      ),
    );
  }
}

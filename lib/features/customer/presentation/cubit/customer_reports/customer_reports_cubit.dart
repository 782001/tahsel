import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_customers_usecase.dart';
import 'customer_reports_state.dart';
import '../../../domain/entities/customer_entity.dart';

class CustomerReportsCubit extends Cubit<CustomerReportsState> {
  final GetCustomersUseCase getCustomersUseCase;
  Timer? _debounce;
  static const int _pageSize = 15;

  CustomerReportsCubit({required this.getCustomersUseCase})
    : super(CustomerReportsInitial());

  Future<void> fetchCustomers(String uid, {bool isRefresh = false}) async {
    if (isRefresh) {
      emit(CustomerReportsLoading());
    } else if (state is CustomerReportsInitial) {
      emit(CustomerReportsLoading());
    }

    final result = await getCustomersUseCase(
      GetCustomersParams(uid: uid, limit: _pageSize),
    );

    result.fold((failure) => emit(CustomerReportsError(failure.message)), (
      paginatedData,
    ) {
      final customers = paginatedData.$1;
      final lastDoc = paginatedData.$2;

      // Sort alphabetically by name
      final sorted = List<CustomerEntity>.from(customers)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      emit(
        CustomerReportsLoaded(
          customers: sorted,
          filteredCustomers: sorted,
          lastDoc: lastDoc,
          hasReachedMax: customers.length < _pageSize,
        ),
      );
    });
  }

  Future<void> fetchMoreCustomers(String uid) async {
    final currentState = state;
    if (currentState is! CustomerReportsLoaded ||
        currentState.isFetchingMore ||
        currentState.hasReachedMax) {
      return;
    }

    emit(currentState.copyWith(isFetchingMore: true));

    final result = await getCustomersUseCase(
      GetCustomersParams(
        uid: uid,
        limit: _pageSize,
        lastDoc: currentState.lastDoc,
      ),
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isFetchingMore: false)),
      (paginatedData) {
        final newCustomers = paginatedData.$1;
        final lastDoc = paginatedData.$2;

        if (newCustomers.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true, isFetchingMore: false));
          return;
        }

        final allCustomers = List<CustomerEntity>.from(currentState.customers)
          ..addAll(newCustomers);

        // Sort alphabetically
        final sorted = List<CustomerEntity>.from(allCustomers)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        emit(
          currentState.copyWith(
            customers: sorted,
            filteredCustomers: sorted, // Reset filter when loading more or re-apply? 
            // Usually, we should re-apply the filter if searchQuery is not empty
            lastDoc: lastDoc,
            hasReachedMax: newCustomers.length < _pageSize,
            isFetchingMore: false,
          ),
        );

        // If there's an active search, re-filter
        if (currentState.searchQuery.isNotEmpty) {
          searchCustomers(currentState.searchQuery, immediate: true);
        }
      },
    );
  }

  void searchCustomers(String query, {bool immediate = false}) {
    if (state is! CustomerReportsLoaded) return;
    final currentState = state as CustomerReportsLoaded;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    void performSearch() async {
      if (query.isEmpty) {
        emit(
          currentState.copyWith(
            filteredCustomers: currentState.customers,
            searchQuery: '',
          ),
        );
        return;
      }

      final filtered = await compute(_filterInIsolate, {
        'customers': currentState.customers,
        'query': query.toLowerCase(),
      });

      emit(currentState.copyWith(filteredCustomers: filtered, searchQuery: query));
    }

    if (immediate) {
      performSearch();
    } else {
      _debounce = Timer(const Duration(milliseconds: 500), performSearch);
    }
  }

  static List<CustomerEntity> _filterInIsolate(Map<String, dynamic> params) {
    final List<CustomerEntity> customers = params['customers'];
    final String query = params['query'];
    return customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              (c.phoneNumber?.contains(query) ?? false),
        )
        .toList();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

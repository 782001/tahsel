import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_customers_usecase.dart';
import 'customer_reports_state.dart';
import '../../../domain/entities/customer_entity.dart';

class CustomerReportsCubit extends Cubit<CustomerReportsState> {
  final GetCustomersUseCase getCustomersUseCase;
  Timer? _debounce;

  CustomerReportsCubit({required this.getCustomersUseCase})
    : super(CustomerReportsInitial());

  Future<void> fetchCustomers(String uid) async {
    emit(CustomerReportsLoading());
    final result = await getCustomersUseCase(GetCustomersParams(uid: uid));
    result.fold((failure) => emit(CustomerReportsError(failure.message)), (
      customers,
    ) {
      // Sort alphabetically by name
      final sorted = List<CustomerEntity>.from(customers)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(CustomerReportsLoaded(customers: sorted, filteredCustomers: sorted));
    });
  }

  void searchCustomers(String query) {
    if (state is! CustomerReportsLoaded) return;
    final currentState = state as CustomerReportsLoaded;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        emit(
          CustomerReportsLoaded(
            customers: currentState.customers,
            filteredCustomers: currentState.customers,
            searchQuery: '',
          ),
        );
        return;
      }

      // Use Isolate for filtering large datasets
      final filtered = await compute(_filterInIsolate, {
        'customers': currentState.customers,
        'query': query.toLowerCase(),
      });

      emit(
        CustomerReportsLoaded(
          customers: currentState.customers,
          filteredCustomers: filtered,
          searchQuery: query,
        ),
      );
    });
  }

  static List<CustomerEntity> _filterInIsolate(Map<String, dynamic> params) {
    final List<CustomerEntity> customers = params['customers'];
    final String query = params['query'];
    return customers
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

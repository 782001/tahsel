import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import '../../../domain/usecases/get_customers_usecase.dart';
import 'customer_reports_state.dart';
import '../../../domain/entities/customer_entity.dart';

class CustomerReportsCubit extends Cubit<CustomerReportsState> {
  final GetCustomersUseCase getCustomersUseCase;
  Timer? _debounce;
  static const int _pageSize = 15;

  List<CustomerEntity> _paginatedCustomers = [];
  DocumentSnapshot? _lastDoc;
  bool _lastHasReachedMax = false;
  List<CustomerEntity>? _serverAllCustomers;
  String? _uid;

  CustomerReportsCubit({required this.getCustomersUseCase})
    : super(CustomerReportsInitial());

  Future<void> fetchCustomers(String uid, {bool isRefresh = false}) async {
    _uid = uid;
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

      _paginatedCustomers = sorted;
      _lastDoc = lastDoc;
      _lastHasReachedMax = customers.length < _pageSize;
      _serverAllCustomers = null;

      emit(
        CustomerReportsLoaded(
          customers: sorted,
          filteredCustomers: sorted,
          lastDoc: lastDoc,
          hasReachedMax: _lastHasReachedMax,
          isFetchingMore: false,
          searchQuery: '',
        ),
      );
    });
  }

  Future<void> fetchMoreCustomers(String uid) async {
    _uid = uid;
    final currentState = state;
    if (currentState is! CustomerReportsLoaded ||
        currentState.isFetchingMore ||
        currentState.hasReachedMax ||
        currentState.searchQuery.trim().isNotEmpty) {
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
          _lastHasReachedMax = true;
          emit(
            currentState.copyWith(hasReachedMax: true, isFetchingMore: false),
          );
          return;
        }

        final allCustomers = List<CustomerEntity>.from(_paginatedCustomers)
          ..addAll(newCustomers);

        // Sort alphabetically
        final sorted = List<CustomerEntity>.from(
          allCustomers,
        )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        _paginatedCustomers = sorted;
        _lastDoc = lastDoc;
        _lastHasReachedMax = newCustomers.length < _pageSize;
        _serverAllCustomers = null;

        emit(
          currentState.copyWith(
            customers: sorted,
            filteredCustomers: sorted,
            lastDoc: lastDoc,
            hasReachedMax: _lastHasReachedMax,
            isFetchingMore: false,
          ),
        );
      },
    );
  }

  void searchCustomers(String query, {bool immediate = false}) {
    if (state is! CustomerReportsLoaded && state is! CustomerReportsLoading) return;

    _debounce?.cancel();

    void performSearch() async {
      if (isClosed) return;
      final q = query.trim().toLowerCase();
      final currentState = state;
      if (currentState is! CustomerReportsLoaded) return;

      if (q.isEmpty) {
        emit(
          currentState.copyWith(
            customers: _paginatedCustomers,
            filteredCustomers: _paginatedCustomers,
            lastDoc: _lastDoc,
            hasReachedMax: _lastHasReachedMax,
            isFetchingMore: false,
            searchQuery: '',
          ),
        );
        return;
      }

      // Fetch all customers from server for exhaustive search across entire collection
      List<CustomerEntity> sourceCustomers = _serverAllCustomers ?? [];
      if (_serverAllCustomers == null) {
        final activeUid = (_uid != null && _uid!.isNotEmpty)
            ? _uid!
            : AppStrings.userToken;
        if (activeUid.isNotEmpty) {
          final result = await getCustomersUseCase(
            GetCustomersParams(uid: activeUid, limit: 0),
          );
          result.fold((_) {}, (paginatedData) {
            final all = List<CustomerEntity>.from(paginatedData.$1)
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            _serverAllCustomers = all;
            sourceCustomers = all;
          });
        }
      }

      if (sourceCustomers.isEmpty) {
        sourceCustomers = _paginatedCustomers;
      }

      final filtered = sourceCustomers.where((c) {
        final name = c.name.toLowerCase();
        final phone = (c.phoneNumber ?? '').toLowerCase();
        final ledger = (c.ledgerNumber ?? '').toLowerCase();
        return name.contains(q) || phone.contains(q) || ledger.contains(q);
      }).toList();

      if (isClosed) return;
      emit(
        currentState.copyWith(
          filteredCustomers: filtered,
          searchQuery: query,
          hasReachedMax: true, // In search mode, matches are exhaustive; disable trailing pagination
          isFetchingMore: false,
        ),
      );
    }

    if (immediate) {
      performSearch();
    } else {
      _debounce = Timer(const Duration(milliseconds: 350), performSearch);
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/save_customer_usecase.dart';
import '../../domain/usecases/update_customer_phone_usecase.dart';
import '../../domain/usecases/update_customer_preference_usecase.dart';
import '../../../shipping_reconciliation/data/services/text_normalization_service.dart';
import 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final SaveCustomerUseCase saveCustomerUseCase;
  final UpdateCustomerPhoneUseCase updateCustomerPhoneUseCase;
  final UpdateCustomerPreferenceUseCase updateCustomerPreferenceUseCase;

  List<CustomerEntity> _allCustomers = [];
  bool _isFetching = false;

  CustomerCubit({
    required this.getCustomersUseCase,
    required this.saveCustomerUseCase,
    required this.updateCustomerPhoneUseCase,
    required this.updateCustomerPreferenceUseCase,
  }) : super(CustomerInitial());

  @override
  void emit(CustomerState state) {
    if (isClosed) return;
    super.emit(state);
  }

  Future<void> fetchCustomers(
    String uid, {
    int limit = 0,
    bool force = false,
  }) async {
    if (_isFetching && !force) return;
    _isFetching = true;
    if (_allCustomers.isEmpty) {
      emit(CustomerLoading());
    }
    final result = await getCustomersUseCase(
      GetCustomersParams(uid: uid, limit: limit),
    );
    _isFetching = false;
    result.fold(
      (failure) {
        if (_allCustomers.isEmpty) {
          emit(CustomerError(failure.message));
        }
      },
      (paginated) {
        final customers = paginated.$1;
        _allCustomers = customers;
        emit(CustomerLoaded(customers));
      },
    );
  }

  void addOrUpdateCustomerLocally(CustomerEntity customer) {
    final index = _allCustomers.indexWhere(
      (c) => c.name.trim().toLowerCase() == customer.name.trim().toLowerCase(),
    );
    if (index >= 0) {
      _allCustomers[index] = customer;
    } else {
      _allCustomers.insert(0, customer);
    }
    emit(CustomerLoaded(List.from(_allCustomers)));
  }

  Future<void> saveCustomer(
    String uid,
    String name, {
    String? ledgerNumber,
    String? phoneNumber,
  }) async {
    final customer = CustomerEntity(
      name: name,
      lastUsedAt: DateTime.now(),
      ledgerNumber: ledgerNumber,
      phoneNumber: phoneNumber,
    );

    // We don't await this if we want to be fast, but usually UI expects some feedback or just quiet update
    final result = await saveCustomerUseCase(
      SaveCustomerParams(uid: uid, customer: customer),
    );
    result.fold(
      (failure) => null, // Silently fail for now or log
      (_) {
        // Refresh local list
        fetchCustomers(uid);
      },
    );
  }

  Future<void> updateCustomerPhone(
    String uid,
    String name,
    String phoneNumber,
  ) async {
    // Optimistic Update
    if (state is CustomerLoaded) {
      final currentLoaded = state as CustomerLoaded;
      final updatedCustomers = currentLoaded.customers.map((c) {
        if (c.name.trim() == name.trim()) {
          return c.copyWith(phoneNumber: phoneNumber);
        }
        return c;
      }).toList();
      _allCustomers = updatedCustomers;
      emit(CustomerLoaded(updatedCustomers));
    }

    final result = await updateCustomerPhoneUseCase(
      UpdateCustomerPhoneParams(uid: uid, name: name, phoneNumber: phoneNumber),
    );
    result.fold(
      (failure) => fetchCustomers(uid), // Rollback/Refresh on failure
      (_) => null,
    );
  }

  Future<void> updateCustomerPreference(
    String uid,
    String name,
    String preference,
  ) async {
    // Optimistic Update
    if (state is CustomerLoaded) {
      final currentLoaded = state as CustomerLoaded;
      final updatedCustomers = currentLoaded.customers.map((c) {
        if (c.name.trim() == name.trim()) {
          return c.copyWith(notificationPreference: preference);
        }
        return c;
      }).toList();
      _allCustomers = updatedCustomers;
      emit(CustomerLoaded(updatedCustomers));
    }

    final result = await updateCustomerPreferenceUseCase(
      UpdateCustomerPreferenceParams(
        uid: uid,
        name: name,
        preference: preference,
      ),
    );
    result.fold(
      (failure) => fetchCustomers(uid), // Rollback/Refresh on failure
      (_) => null,
    );
  }

  List<CustomerEntity> getSuggestions(String query) {
    if (query.trim().isEmpty) return _allCustomers;
    final normalizedQuery =
        TextNormalizationService.normalizeForMatching(query);
    final rawLowerQuery = query.trim().toLowerCase();

    return _allCustomers.where((c) {
      final normalizedName =
          TextNormalizationService.normalizeForMatching(c.name);
      return normalizedName.contains(normalizedQuery) ||
          c.name.toLowerCase().contains(rawLowerQuery);
    }).toList();
  }

  void clearData() {
    _allCustomers.clear();
    emit(CustomerInitial());
  }
}

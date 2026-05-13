import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/save_customer_usecase.dart';
import '../../domain/usecases/update_customer_phone_usecase.dart';
import '../../domain/usecases/update_customer_preference_usecase.dart';
import 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final SaveCustomerUseCase saveCustomerUseCase;
  final UpdateCustomerPhoneUseCase updateCustomerPhoneUseCase;
  final UpdateCustomerPreferenceUseCase updateCustomerPreferenceUseCase;

  List<CustomerEntity> _allCustomers = [];

  CustomerCubit({
    required this.getCustomersUseCase,
    required this.saveCustomerUseCase,
    required this.updateCustomerPhoneUseCase,
    required this.updateCustomerPreferenceUseCase,
  }) : super(CustomerInitial());

  Future<void> fetchCustomers(String uid) async {
    emit(CustomerLoading());
    final result = await getCustomersUseCase(
      GetCustomersParams(uid: uid, limit: 100),
    );
    result.fold((failure) => emit(CustomerError(failure.message)), (paginated) {
      final customers = paginated.$1;
      _allCustomers = customers;
      emit(CustomerLoaded(customers));
    });
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
    if (query.isEmpty) return _allCustomers;
    return _allCustomers
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void clearData() {
    _allCustomers.clear();
    emit(CustomerInitial());
  }
}

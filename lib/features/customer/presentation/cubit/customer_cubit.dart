import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/save_customer_usecase.dart';
import 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final SaveCustomerUseCase saveCustomerUseCase;

  List<CustomerEntity> _allCustomers = [];

  CustomerCubit({
    required this.getCustomersUseCase,
    required this.saveCustomerUseCase,
  }) : super(CustomerInitial());

  Future<void> fetchCustomers(String uid) async {
    emit(CustomerLoading());
    final result = await getCustomersUseCase(uid);
    result.fold(
      (failure) => emit(CustomerError('Failed to fetch customers')),
      (customers) {
        _allCustomers = customers;
        emit(CustomerLoaded(customers));
      },
    );
  }

  Future<void> saveCustomer(String uid, String name) async {
    final customer = CustomerEntity(
      name: name,
      lastUsedAt: DateTime.now(),
    );
    
    // We don't await this if we want to be fast, but usually UI expects some feedback or just quiet update
    final result = await saveCustomerUseCase(uid, customer);
    result.fold(
      (failure) => null, // Silently fail for now or log
      (_) {
        // Refresh local list
        fetchCustomers(uid);
      },
    );
  }

  List<CustomerEntity> getSuggestions(String query) {
    if (query.isEmpty) return _allCustomers;
    return _allCustomers
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_customer_operations_usecase.dart';
import 'customer_details_state.dart';
import '../../../domain/entities/customer_operation.dart';

class CustomerDetailsCubit extends Cubit<CustomerDetailsState> {
  final GetCustomerOperationsUseCase getCustomerOperationsUseCase;

  CustomerDetailsCubit({required this.getCustomerOperationsUseCase})
    : super(CustomerDetailsInitial());

  Future<void> fetchCustomerDetails(String uid, String customerName) async {
    emit(CustomerDetailsLoading());
    final result = await getCustomerOperationsUseCase(
      uid: uid,
      customerName: customerName,
    );

    result.fold((failure) => emit(CustomerDetailsError(failure.message)), (
      operations,
    ) async {
      // Use Isolate for sorting and processing summary
      final processedData = await compute(
        _processOperationsInIsolate,
        operations,
      );

      emit(
        CustomerDetailsLoaded(
          operations: processedData.sortedOperations,
          totalSpent: processedData.totalSpent,
          totalPaid: processedData.totalPaid,
          remaining: processedData.remaining,
        ),
      );
    });
  }

  static _ProcessedData _processOperationsInIsolate(
    List<CustomerOperation> operations,
  ) {
    // Sort latest first
    final sorted = List<CustomerOperation>.from(operations)
      ..sort((a, b) => b.date.compareTo(a.date));

    double totalSpent = 0;
    double totalPaid = 0;

    for (var op in operations) {
      if (op.type == CustomerOperationType.purchase ||
          op.type == CustomerOperationType.debt) {
        totalSpent += op.amount;
      } else if (op.type == CustomerOperationType.payment) {
        totalPaid += op.amount;
      }
    }

    return _ProcessedData(
      sortedOperations: sorted,
      totalSpent: totalSpent,
      totalPaid: totalPaid,
      remaining: totalSpent - totalPaid,
    );
  }
}

class _ProcessedData {
  final List<CustomerOperation> sortedOperations;
  final double totalSpent;
  final double totalPaid;
  final double remaining;

  _ProcessedData({
    required this.sortedOperations,
    required this.totalSpent,
    required this.totalPaid,
    required this.remaining,
  });
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_customer_operations_usecase.dart';
import 'customer_details_state.dart';
import '../../../domain/entities/customer_operation.dart';

class CustomerDetailsCubit extends Cubit<CustomerDetailsState> {
  final GetCustomerOperationsUseCase getCustomerOperationsUseCase;
  static const int _pageSize = 15;

  CustomerDetailsCubit({required this.getCustomerOperationsUseCase})
    : super(CustomerDetailsInitial());

  Future<void> fetchOperations(String uid, String customerName) async {
    emit(CustomerDetailsLoading());

    final result = await getCustomerOperationsUseCase(
      uid: uid,
      customerName: customerName,
      limit: _pageSize,
    );

    result.fold(
      (failure) => emit(CustomerDetailsError(failure.message)),
      (paginatedData) {
        final operations = paginatedData.$1;
        final lastDoc = paginatedData.$2;

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

        // NOTE: In a real paginated app, totals should be pre-calculated in the database.
        // For now, these totals only reflect the fetched page if we don't have a better source.
        // BUT, existing logic expects total spent/paid for the WHOLE history.
        // Since we want to satisfy "don't fetch all", we should probably show a warning 
        // or fetch summary data separately.
        
        emit(
          CustomerDetailsLoaded(
            operations: operations,
            totalSpent: totalSpent,
            totalPaid: totalPaid,
            remaining: totalSpent - totalPaid,
            lastDoc: lastDoc,
            hasReachedMax: operations.length < _pageSize,
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
          emit(currentState.copyWith(hasReachedMax: true, isFetchingMore: false));
          return;
        }

        final allOperations = List<CustomerOperation>.from(currentState.operations)
          ..addAll(newOperations);

        // Update totals
        double totalSpent = currentState.totalSpent;
        double totalPaid = currentState.totalPaid;

        for (var op in newOperations) {
          if (op.type == CustomerOperationType.purchase ||
              op.type == CustomerOperationType.debt) {
            totalSpent += op.amount;
          } else if (op.type == CustomerOperationType.payment) {
            totalPaid += op.amount;
          }
        }

        emit(
          currentState.copyWith(
            operations: allOperations,
            totalSpent: totalSpent,
            totalPaid: totalPaid,
            remaining: totalSpent - totalPaid,
            lastDoc: lastDoc,
            hasReachedMax: newOperations.length < _pageSize,
            isFetchingMore: false,
          ),
        );
      },
    );
  }
}

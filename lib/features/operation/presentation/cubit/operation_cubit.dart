import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/operation_entity.dart';
import '../../domain/usecases/add_operation_usecase.dart';
import '../../domain/usecases/calculate_remaining_debt_usecase.dart';
import 'operation_state.dart';

class OperationCubit extends Cubit<OperationState> {
  final AddOperationUseCase addOperationUseCase;
  final CalculateRemainingDebtUseCase calculateRemainingDebtUseCase;

  OperationCubit({
    required this.addOperationUseCase,
    required this.calculateRemainingDebtUseCase,
  }) : super(OperationInitial());

  Future<double> calculateDebt(double total, double paid) async {
    return await calculateRemainingDebtUseCase(
      CalculateRemainingDebtParams(totalAmount: total, paidAmount: paid),
    );
  }

  Future<void> addOperation(OperationEntity operation) async {
    emit(OperationLoading());
    final result = await addOperationUseCase(
      AddOperationParams(operation: operation),
    );

    result.fold(
      (failure) => emit(OperationFailure(message: failure.toString())),
      (id) =>
          emit(OperationSuccess(message: 'operation_success', operationId: id)),
    );
  }

  void clearData() {
    emit(OperationInitial());
  }
}

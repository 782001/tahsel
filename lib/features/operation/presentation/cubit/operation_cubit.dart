import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/operation_entity.dart';
import '../../domain/usecases/add_operation_usecase.dart';
import 'operation_state.dart';

class OperationCubit extends Cubit<OperationState> {
  final AddOperationUseCase addOperationUseCase;

  OperationCubit({required this.addOperationUseCase}) : super(OperationInitial());

  Future<void> addOperation(OperationEntity operation) async {
    emit(OperationLoading());
    final result = await addOperationUseCase(AddOperationParams(operation: operation));

    result.fold(
      (failure) => emit(OperationFailure(message: failure.message ?? 'Unknown error occurred')),
      (_) => emit(const OperationSuccess(message: 'operation_success')),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/stock_movement_entity.dart';
import '../../domain/usecases/stock_movement_usecases.dart';

abstract class InventoryStockMovementsState extends Equatable {
  const InventoryStockMovementsState();
  @override
  List<Object?> get props => [];
}

class InventoryStockMovementsInitial extends InventoryStockMovementsState {}

class InventoryStockMovementsLoading extends InventoryStockMovementsState {}

class InventoryStockMovementsLoaded extends InventoryStockMovementsState {
  final List<StockMovementEntity> movements;
  const InventoryStockMovementsLoaded(this.movements);
  @override
  List<Object?> get props => [movements];
}

class InventoryStockMovementsError extends InventoryStockMovementsState {
  final String message;
  const InventoryStockMovementsError(this.message);
  @override
  List<Object?> get props => [message];
}

class InventoryStockMovementsCubit extends Cubit<InventoryStockMovementsState> {
  final GetStockMovementsUseCase getStockMovementsUseCase;
  final CreateManualStockAdjustmentUseCase createManualAdjustmentUseCase;

  InventoryStockMovementsCubit({
    required this.getStockMovementsUseCase,
    required this.createManualAdjustmentUseCase,
  }) : super(InventoryStockMovementsInitial());

  Future<void> fetchStockMovements({String? productId}) async {
    emit(InventoryStockMovementsLoading());
    final result = await getStockMovementsUseCase(productId: productId);
    result.fold(
      (failure) => emit(InventoryStockMovementsError(failure.message)),
      (movements) => emit(InventoryStockMovementsLoaded(movements)),
    );
  }

  Future<bool> createManualAdjustment({
    required String productId,
    required double adjustmentQuantity,
    required String reason,
  }) async {
    final result = await createManualAdjustmentUseCase(
      productId: productId,
      adjustmentQuantity: adjustmentQuantity,
      reason: reason,
    );
    return result.fold(
      (failure) {
        emit(InventoryStockMovementsError(failure.message));
        return false;
      },
      (_) {
        fetchStockMovements(productId: productId);
        return true;
      },
    );
  }
}

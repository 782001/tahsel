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
  final bool hasMore;
  final bool isPaginationLoading;

  const InventoryStockMovementsLoaded(
    this.movements, {
    this.hasMore = true,
    this.isPaginationLoading = false,
  });

  InventoryStockMovementsLoaded copyWith({
    List<StockMovementEntity>? movements,
    bool? hasMore,
    bool? isPaginationLoading,
  }) {
    return InventoryStockMovementsLoaded(
      movements ?? this.movements,
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
    );
  }

  @override
  List<Object?> get props => [movements, hasMore, isPaginationLoading];
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

  int _currentLimit = 15;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  InventoryStockMovementsCubit({
    required this.getStockMovementsUseCase,
    required this.createManualAdjustmentUseCase,
  }) : super(InventoryStockMovementsInitial());

  Future<void> fetchStockMovements({String? productId}) async {
    _currentLimit = 15;
    _hasMore = true;
    _isFetchingMore = false;
    emit(InventoryStockMovementsLoading());
    final result = await getStockMovementsUseCase(
      productId: productId,
      limit: _currentLimit,
    );
    result.fold(
      (failure) => emit(InventoryStockMovementsError(failure.message)),
      (movements) {
        _hasMore = movements.length >= _currentLimit;
        emit(
          InventoryStockMovementsLoaded(
            movements,
            hasMore: _hasMore,
            isPaginationLoading: false,
          ),
        );
      },
    );
  }

  Future<void> fetchMoreStockMovements({String? productId}) async {
    final currentState = state;
    if (currentState is! InventoryStockMovementsLoaded) return;
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    emit(currentState.copyWith(isPaginationLoading: true));

    _currentLimit += 15;
    final result = await getStockMovementsUseCase(
      productId: productId,
      limit: _currentLimit,
    );

    result.fold(
      (failure) {
        _isFetchingMore = false;
        emit(currentState.copyWith(isPaginationLoading: false));
      },
      (movements) {
        _isFetchingMore = false;
        _hasMore = movements.length >= _currentLimit;
        emit(
          InventoryStockMovementsLoaded(
            movements,
            hasMore: _hasMore,
            isPaginationLoading: false,
          ),
        );
      },
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

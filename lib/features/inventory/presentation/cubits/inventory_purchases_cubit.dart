import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_purchase_entity.dart';
import '../../domain/usecases/inventory_purchase_usecases.dart';

abstract class InventoryPurchasesState extends Equatable {
  const InventoryPurchasesState();
  @override
  List<Object?> get props => [];
}

class InventoryPurchasesInitial extends InventoryPurchasesState {}

class InventoryPurchasesLoading extends InventoryPurchasesState {}

class InventoryPurchasesLoaded extends InventoryPurchasesState {
  final List<InventoryPurchaseEntity> purchases;
  final bool hasMore;
  final bool isPaginationLoading;

  const InventoryPurchasesLoaded(
    this.purchases, {
    this.hasMore = true,
    this.isPaginationLoading = false,
  });

  InventoryPurchasesLoaded copyWith({
    List<InventoryPurchaseEntity>? purchases,
    bool? hasMore,
    bool? isPaginationLoading,
  }) {
    return InventoryPurchasesLoaded(
      purchases ?? this.purchases,
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
    );
  }

  @override
  List<Object?> get props => [purchases, hasMore, isPaginationLoading];
}

class InventoryPurchasesError extends InventoryPurchasesState {
  final String message;
  const InventoryPurchasesError(this.message);
  @override
  List<Object?> get props => [message];
}

class InventoryPurchasesCubit extends Cubit<InventoryPurchasesState> {
  final GetInventoryPurchasesUseCase getPurchasesUseCase;
  final CreateInventoryPurchaseUseCase createPurchaseUseCase;
  final UpdateInventoryPurchaseUseCase updatePurchaseUseCase;
  final DeleteInventoryPurchaseUseCase deletePurchaseUseCase;

  int _currentLimit = 15;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  InventoryPurchasesCubit({
    required this.getPurchasesUseCase,
    required this.createPurchaseUseCase,
    required this.updatePurchaseUseCase,
    required this.deletePurchaseUseCase,
  }) : super(InventoryPurchasesInitial());

  Future<void> fetchPurchases({String? supplierId}) async {
    _currentLimit = 15;
    _hasMore = true;
    _isFetchingMore = false;
    emit(InventoryPurchasesLoading());
    final result = await getPurchasesUseCase(
      supplierId: supplierId,
      limit: _currentLimit,
    );
    result.fold(
      (failure) => emit(InventoryPurchasesError(failure.message)),
      (purchases) {
        _hasMore = purchases.length >= _currentLimit;
        emit(
          InventoryPurchasesLoaded(
            purchases,
            hasMore: _hasMore,
            isPaginationLoading: false,
          ),
        );
      },
    );
  }

  Future<void> fetchMorePurchases({String? supplierId}) async {
    final currentState = state;
    if (currentState is! InventoryPurchasesLoaded) return;
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    emit(currentState.copyWith(isPaginationLoading: true));

    _currentLimit += 15;
    final result = await getPurchasesUseCase(
      supplierId: supplierId,
      limit: _currentLimit,
    );

    result.fold(
      (failure) {
        _isFetchingMore = false;
        emit(currentState.copyWith(isPaginationLoading: false));
      },
      (purchases) {
        _isFetchingMore = false;
        _hasMore = purchases.length >= _currentLimit;
        emit(
          InventoryPurchasesLoaded(
            purchases,
            hasMore: _hasMore,
            isPaginationLoading: false,
          ),
        );
      },
    );
  }

  Future<bool> createPurchase(InventoryPurchaseEntity purchase) async {
    final prevState = state;
    final result = await createPurchaseUseCase(purchase);
    return result.fold(
      (failure) {
        if (prevState is InventoryPurchasesLoaded) {
          emit(prevState);
        } else {
          emit(InventoryPurchasesError(failure.message));
        }
        return false;
      },
      (_) {
        fetchPurchases();
        return true;
      },
    );
  }

  Future<bool> updatePurchase({
    required InventoryPurchaseEntity oldPurchase,
    required InventoryPurchaseEntity newPurchase,
  }) async {
    final prevState = state;
    final result = await updatePurchaseUseCase(
      oldPurchase: oldPurchase,
      newPurchase: newPurchase,
    );
    return result.fold(
      (failure) {
        if (prevState is InventoryPurchasesLoaded) {
          emit(prevState);
        } else {
          emit(InventoryPurchasesError(failure.message));
        }
        return false;
      },
      (_) {
        fetchPurchases();
        return true;
      },
    );
  }

  Future<bool> deletePurchase(InventoryPurchaseEntity purchase) async {
    final prevState = state;
    final result = await deletePurchaseUseCase(purchase);
    return result.fold(
      (failure) {
        if (prevState is InventoryPurchasesLoaded) {
          emit(prevState);
        } else {
          emit(InventoryPurchasesError(failure.message));
        }
        return false;
      },
      (_) {
        fetchPurchases();
        return true;
      },
    );
  }
}

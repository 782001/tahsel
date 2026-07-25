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
  const InventoryPurchasesLoaded(this.purchases);
  @override
  List<Object?> get props => [purchases];
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

  InventoryPurchasesCubit({
    required this.getPurchasesUseCase,
    required this.createPurchaseUseCase,
    required this.updatePurchaseUseCase,
    required this.deletePurchaseUseCase,
  }) : super(InventoryPurchasesInitial());

  Future<void> fetchPurchases({String? supplierId}) async {
    emit(InventoryPurchasesLoading());
    final result = await getPurchasesUseCase(supplierId: supplierId);
    result.fold(
      (failure) => emit(InventoryPurchasesError(failure.message)),
      (purchases) => emit(InventoryPurchasesLoaded(purchases)),
    );
  }

  Future<bool> createPurchase(InventoryPurchaseEntity purchase) async {
    final result = await createPurchaseUseCase(purchase);
    return result.fold(
      (failure) {
        emit(InventoryPurchasesError(failure.message));
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
    final result = await updatePurchaseUseCase(
      oldPurchase: oldPurchase,
      newPurchase: newPurchase,
    );
    return result.fold(
      (failure) {
        emit(InventoryPurchasesError(failure.message));
        return false;
      },
      (_) {
        fetchPurchases();
        return true;
      },
    );
  }

  Future<bool> deletePurchase(InventoryPurchaseEntity purchase) async {
    final result = await deletePurchaseUseCase(purchase);
    return result.fold(
      (failure) {
        emit(InventoryPurchasesError(failure.message));
        return false;
      },
      (_) {
        fetchPurchases();
        return true;
      },
    );
  }
}

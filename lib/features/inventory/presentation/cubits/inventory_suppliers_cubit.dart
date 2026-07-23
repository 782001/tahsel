import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/entities/inventory_purchase_entity.dart';
import '../../domain/entities/inventory_supplier_entity.dart';
import '../../domain/usecases/inventory_product_usecases.dart';
import '../../domain/usecases/inventory_purchase_usecases.dart';
import '../../domain/usecases/inventory_supplier_usecases.dart';

abstract class InventorySuppliersState extends Equatable {
  const InventorySuppliersState();
  @override
  List<Object?> get props => [];
}

class InventorySuppliersInitial extends InventorySuppliersState {}

class InventorySuppliersLoading extends InventorySuppliersState {}

class InventorySuppliersLoaded extends InventorySuppliersState {
  final List<InventorySupplierEntity> suppliers;
  const InventorySuppliersLoaded(this.suppliers);
  @override
  List<Object?> get props => [suppliers];
}

class SupplierDetailsLoaded extends InventorySuppliersState {
  final InventorySupplierEntity supplier;
  final List<InventoryPurchaseEntity> purchases;
  final List<InventoryProductEntity> suppliedProducts;

  const SupplierDetailsLoaded({
    required this.supplier,
    required this.purchases,
    required this.suppliedProducts,
  });

  @override
  List<Object?> get props => [supplier, purchases, suppliedProducts];
}

class InventorySuppliersError extends InventorySuppliersState {
  final String message;
  const InventorySuppliersError(this.message);
  @override
  List<Object?> get props => [message];
}

class InventorySuppliersCubit extends Cubit<InventorySuppliersState> {
  final GetInventorySuppliersUseCase getSuppliersUseCase;
  final SaveInventorySupplierUseCase saveSupplierUseCase;
  final DeleteInventorySupplierUseCase deleteSupplierUseCase;
  final GetInventoryPurchasesUseCase getPurchasesUseCase;
  final GetInventoryProductsUseCase getProductsUseCase;

  InventorySuppliersCubit({
    required this.getSuppliersUseCase,
    required this.saveSupplierUseCase,
    required this.deleteSupplierUseCase,
    required this.getPurchasesUseCase,
    required this.getProductsUseCase,
  }) : super(InventorySuppliersInitial());

  Future<void> fetchSuppliers() async {
    emit(InventorySuppliersLoading());
    final result = await getSuppliersUseCase();
    result.fold(
      (failure) => emit(InventorySuppliersError(failure.message)),
      (suppliers) => emit(InventorySuppliersLoaded(suppliers)),
    );
  }

  Future<void> fetchSupplierDetails(InventorySupplierEntity supplier) async {
    emit(InventorySuppliersLoading());
    final purchasesRes = await getPurchasesUseCase(supplierId: supplier.id);
    final productsRes = await getProductsUseCase(supplierId: supplier.id);

    purchasesRes.fold(
      (failure) => emit(InventorySuppliersError(failure.message)),
      (purchases) {
        productsRes.fold(
          (failure) => emit(InventorySuppliersError(failure.message)),
          (products) {
            emit(SupplierDetailsLoaded(
              supplier: supplier,
              purchases: purchases,
              suppliedProducts: products,
            ));
          },
        );
      },
    );
  }

  Future<bool> saveSupplier(InventorySupplierEntity supplier) async {
    final result = await saveSupplierUseCase(supplier);
    return result.fold(
      (failure) {
        emit(InventorySuppliersError(failure.message));
        return false;
      },
      (_) {
        fetchSuppliers();
        return true;
      },
    );
  }

  Future<bool> deleteSupplier(String id) async {
    final result = await deleteSupplierUseCase(id);
    return result.fold(
      (failure) {
        emit(InventorySuppliersError(failure.message));
        return false;
      },
      (_) {
        fetchSuppliers();
        return true;
      },
    );
  }
}

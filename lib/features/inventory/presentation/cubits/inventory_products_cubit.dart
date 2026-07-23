import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_product_entity.dart';
import '../../domain/usecases/inventory_product_usecases.dart';

abstract class InventoryProductsState extends Equatable {
  const InventoryProductsState();
  @override
  List<Object?> get props => [];
}

class InventoryProductsInitial extends InventoryProductsState {}

class InventoryProductsLoading extends InventoryProductsState {}

class InventoryProductsLoaded extends InventoryProductsState {
  final List<InventoryProductEntity> products;
  const InventoryProductsLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class InventoryProductsError extends InventoryProductsState {
  final String message;
  const InventoryProductsError(this.message);
  @override
  List<Object?> get props => [message];
}

class InventoryProductsCubit extends Cubit<InventoryProductsState> {
  final GetInventoryProductsUseCase getProductsUseCase;
  final SaveInventoryProductUseCase saveProductUseCase;
  final DeleteInventoryProductUseCase deleteProductUseCase;

  InventoryProductsCubit({
    required this.getProductsUseCase,
    required this.saveProductUseCase,
    required this.deleteProductUseCase,
  }) : super(InventoryProductsInitial());

  Future<void> fetchProducts({
    String? query,
    String? categoryId,
    String? supplierId,
  }) async {
    emit(InventoryProductsLoading());
    final result = await getProductsUseCase(
      query: query,
      categoryId: categoryId,
      supplierId: supplierId,
    );
    result.fold(
      (failure) => emit(InventoryProductsError(failure.message)),
      (products) => emit(InventoryProductsLoaded(products)),
    );
  }

  Future<bool> saveProduct(InventoryProductEntity product) async {
    final result = await saveProductUseCase(product);
    return result.fold(
      (failure) {
        emit(InventoryProductsError(failure.message));
        return false;
      },
      (_) {
        fetchProducts();
        return true;
      },
    );
  }

  Future<bool> deleteProduct(String id) async {
    final result = await deleteProductUseCase(id);
    return result.fold(
      (failure) {
        emit(InventoryProductsError(failure.message));
        return false;
      },
      (_) {
        fetchProducts();
        return true;
      },
    );
  }
}

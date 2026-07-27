import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/inventory_local_data_source.dart';
import '../../data/services/inventory_excel_service.dart';
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
  final bool hasMore;
  final bool isPaginationLoading;

  const InventoryProductsLoaded(
    this.products, {
    this.hasMore = true,
    this.isPaginationLoading = false,
  });

  InventoryProductsLoaded copyWith({
    List<InventoryProductEntity>? products,
    bool? hasMore,
    bool? isPaginationLoading,
  }) {
    return InventoryProductsLoaded(
      products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
    );
  }

  @override
  List<Object?> get props => [products, hasMore, isPaginationLoading];
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

  int _currentLimit = 15;
  bool _hasMore = true;
  bool _isFetchingMore = false;

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
    _currentLimit = 15;
    _hasMore = true;
    _isFetchingMore = false;
    emit(InventoryProductsLoading());
    final result = await getProductsUseCase(
      query: query,
      categoryId: categoryId,
      supplierId: supplierId,
      limit: _currentLimit,
    );
    result.fold((failure) => emit(InventoryProductsError(failure.message)), (
      products,
    ) {
      _hasMore = products.length >= _currentLimit;
      emit(
        InventoryProductsLoaded(
          products,
          hasMore: _hasMore,
          isPaginationLoading: false,
        ),
      );
    });
  }

  Future<void> fetchMoreProducts({
    String? query,
    String? categoryId,
    String? supplierId,
  }) async {
    final currentState = state;
    if (currentState is! InventoryProductsLoaded) return;
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    emit(currentState.copyWith(isPaginationLoading: true));

    _currentLimit += 15;
    final result = await getProductsUseCase(
      query: query,
      categoryId: categoryId,
      supplierId: supplierId,
      limit: _currentLimit,
    );

    result.fold(
      (failure) {
        _isFetchingMore = false;
        emit(currentState.copyWith(isPaginationLoading: false));
      },
      (products) {
        _isFetchingMore = false;
        _hasMore = products.length >= _currentLimit;
        emit(
          InventoryProductsLoaded(
            products,
            hasMore: _hasMore,
            isPaginationLoading: false,
          ),
        );
      },
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

  Future<String?> exportAllProductsToExcel() async {
    try {
      final localDataSource = GetIt.I<InventoryLocalDataSource>();
      final localModels = await localDataSource.getProducts();
      if (localModels.isEmpty) return null;

      final products = localModels
          .map((m) => m as InventoryProductEntity)
          .toList();
      products.sort((a, b) => a.name.compareTo(b.name));

      return await InventoryExcelService.exportProducts(products);
    } catch (_) {
      return null;
    }
  }
}

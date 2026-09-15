import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tahsel/core/utils/app_logger.dart';

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

  List<InventoryProductEntity> _allProducts = [];
  int _currentLimit = 15;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  InventoryProductsCubit({
    required this.getProductsUseCase,
    required this.saveProductUseCase,
    required this.deleteProductUseCase,
  }) : super(InventoryProductsInitial());

  @override
  void emit(InventoryProductsState state) {
    if (isClosed) return;
    super.emit(state);
  }

  void clearData() {
    _allProducts.clear();
    _currentLimit = 15;
    _hasMore = true;
    _isFetchingMore = false;
    emit(InventoryProductsInitial());
  }

  Future<void> fetchProducts({
    String? query,
    String? categoryId,
    String? supplierId,
    bool loadAll = false,
  }) async {
    _currentLimit = loadAll ? 1000000 : 15;
    _hasMore = !loadAll;
    _isFetchingMore = false;
    if (isClosed) return;
    emit(InventoryProductsLoading());
    final result = await getProductsUseCase(
      query: query,
      categoryId: categoryId,
      supplierId: supplierId,
      limit: _currentLimit,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        if (!isClosed) emit(InventoryProductsError(failure.message));
      },
      (products) {
        _allProducts = products;
        _hasMore = loadAll ? false : _allProducts.length > _currentLimit;
        if (!isClosed) {
          emit(
            InventoryProductsLoaded(
              loadAll ? _allProducts : _allProducts.take(_currentLimit).toList(),
              hasMore: _hasMore,
              isPaginationLoading: false,
            ),
          );
        }
      },
    );
  }

  Future<void> fetchMoreProducts({
    String? query,
    String? categoryId,
    String? supplierId,
  }) async {
    final currentState = state;
    if (currentState is! InventoryProductsLoaded) return;
    if (_isFetchingMore || !_hasMore || isClosed) return;

    _isFetchingMore = true;
    emit(currentState.copyWith(isPaginationLoading: true));

    _currentLimit += 15;
    _hasMore = _allProducts.length > _currentLimit;
    _isFetchingMore = false;

    if (!isClosed) {
      emit(
        InventoryProductsLoaded(
          _allProducts.take(_currentLimit).toList(),
          hasMore: _hasMore,
          isPaginationLoading: false,
        ),
      );
    }
  }

  Future<bool> saveProduct(InventoryProductEntity product) async {
    final result = await saveProductUseCase(product);
    return result.fold(
      (failure) {
        if (!isClosed) emit(InventoryProductsError(failure.message));
        return false;
      },
      (_) {
        if (!isClosed) {
          fetchProducts();
        }
        return true;
      },
    );
  }

  Future<bool> deleteProduct(String id) async {
    final result = await deleteProductUseCase(id);
    return result.fold(
      (failure) {
        if (!isClosed) emit(InventoryProductsError(failure.message));
        return false;
      },
      (_) {
        if (!isClosed) {
          fetchProducts();
        }
        return true;
      },
    );
  }

  Future<String?> exportAllProductsToExcel() async {
    try {
      List<InventoryProductEntity> products = [];

      // 1. Try local data source first
      if (GetIt.I.isRegistered<InventoryLocalDataSource>()) {
        try {
          final localDataSource = GetIt.I<InventoryLocalDataSource>();
          final localModels = await localDataSource.getProducts();
          if (localModels.isNotEmpty) {
            products = localModels.cast<InventoryProductEntity>().toList();
          }
        } catch (e) {
          AppLogger.printMessage('LocalDataSource getProducts error: $e');
        }
      }

      // 2. If local cache was empty, fall back to in-memory products
      if (products.isEmpty && _allProducts.isNotEmpty) {
        products = List.from(_allProducts);
      }

      // 3. If still empty and state has loaded products, use state
      if (products.isEmpty && state is InventoryProductsLoaded) {
        products = List.from((state as InventoryProductsLoaded).products);
      }

      // 4. If still empty, fetch directly via getProductsUseCase
      if (products.isEmpty) {
        final result = await getProductsUseCase(limit: 100000);
        result.fold(
          (failure) => AppLogger.printMessage(
            'getProductsUseCase error: ${failure.message}',
          ),
          (fetched) => products = fetched,
        );
      }

      if (products.isEmpty) {
        AppLogger.printMessage('exportAllProductsToExcel: No products available to export');
        return null;
      }

      products.sort((a, b) => a.name.compareTo(b.name));

      return await InventoryExcelService.exportProducts(products);
    } catch (e) {
      AppLogger.printMessage('exportAllProductsToExcel error: $e');
      return null;
    }
  }
}

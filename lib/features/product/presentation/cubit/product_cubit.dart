import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/save_product_usecase.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final GetProductsUseCase getProductsUseCase;
  final SaveProductUseCase saveProductUseCase;

  List<ProductEntity> _allProducts = [];

  ProductCubit({
    required this.getProductsUseCase,
    required this.saveProductUseCase,
  }) : super(ProductInitial());

  Future<void> fetchProducts(String uid) async {
    emit(ProductLoading());
    final result = await getProductsUseCase(uid);
    result.fold(
      (failure) => emit(ProductError('Failed to fetch products')),
      (products) {
        _allProducts = products;
        emit(ProductLoaded(products));
      },
    );
  }

  Future<void> saveProduct(String uid, String name) async {
    final product = ProductEntity(
      name: name,
      lastUsedAt: DateTime.now(),
    );
    
    // We don't await this if we want to be fast, but usually UI expects some feedback or just quiet update
    final result = await saveProductUseCase(uid, product);
    result.fold(
      (failure) => null, // Silently fail for now or log
      (_) {
        // Refresh local list
        fetchProducts(uid);
      },
    );
  }

  List<ProductEntity> getSuggestions(String query) {
    if (query.isEmpty) return _allProducts;
    return _allProducts
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

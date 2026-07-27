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
    final result = await getProductsUseCase(GetProductsParams(uid: uid));
    result.fold((failure) => emit(ProductError(failure.message)), (products) {
      _allProducts = products;
      emit(ProductLoaded(products));
    });
  }

  Future<void> saveProduct(String uid, String name) async {
    String cleanName = name.trim();
    final match =
        RegExp(r'^(.*?)(?:\s*\(\s*\d+.*?\))?$').firstMatch(cleanName);
    if (match != null) {
      final extracted = match.group(1)?.trim();
      if (extracted != null && extracted.isNotEmpty) {
        cleanName = extracted;
      }
    }

    if (cleanName.isEmpty) return;

    final product = ProductEntity(name: cleanName, lastUsedAt: DateTime.now());

    // We don't await this if we want to be fast, but usually UI expects some feedback or just quiet update
    final result = await saveProductUseCase(
      SaveProductParams(uid: uid, product: product),
    );
    result.fold(
      (failure) => null, // Silently fail for now or log
      (_) {
        // Refresh local list
        fetchProducts(uid);
      },
    );
  }

  List<ProductEntity> getSuggestions(String query) {
    final Set<String> seenNames = {};
    final List<ProductEntity> result = [];

    for (final p in _allProducts) {
      String cleanName = p.name.trim();
      final match =
          RegExp(r'^(.*?)(?:\s*\(\s*\d+.*?\))?$').firstMatch(cleanName);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty) {
          cleanName = extracted;
        }
      }

      if (cleanName.isEmpty) continue;

      if (query.isEmpty ||
          cleanName.toLowerCase().contains(query.toLowerCase())) {
        final lowerKey = cleanName.toLowerCase();
        if (!seenNames.contains(lowerKey)) {
          seenNames.add(lowerKey);
          result.add(ProductEntity(
            id: p.id,
            name: cleanName,
            lastUsedAt: p.lastUsedAt,
          ));
        }
      }
    }

    return result;
  }

  void clearData() {
    _allProducts.clear();
    emit(ProductInitial());
  }
}

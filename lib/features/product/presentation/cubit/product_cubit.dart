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
    final cleanNames = _extractProductNames(name);
    if (cleanNames.isEmpty) return;

    for (final cleanName in cleanNames) {
      final product =
          ProductEntity(name: cleanName, lastUsedAt: DateTime.now());
      await saveProductUseCase(
        SaveProductParams(uid: uid, product: product),
      );
    }
    fetchProducts(uid);
  }

  static List<String> _extractProductNames(String input) {
    if (input.trim().isEmpty) return [];
    final parts = input.split(RegExp(r'[\+,\n،]'));
    final Set<String> cleanNames = {};
    final qtyPattern = RegExp(r'^(.*?)(?:\s*\(\s*\d+(?:\.\d+)?.*?\))?$');

    for (final part in parts) {
      String clean = part.trim();
      final match = qtyPattern.firstMatch(clean);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty) {
          clean = extracted;
        }
      }
      if (clean.isNotEmpty) {
        cleanNames.add(clean);
      }
    }
    return cleanNames.toList();
  }

  List<ProductEntity> getSuggestions(String query) {
    final Set<String> seenNames = {};
    final List<ProductEntity> result = [];
    final qtyPattern = RegExp(r'^(.*?)(?:\s*\(\s*\d+(?:\.\d+)?.*?\))?$');

    for (final p in _allProducts) {
      String cleanName = p.name.trim();
      final match = qtyPattern.firstMatch(cleanName);
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

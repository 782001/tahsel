import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/inventory_product_entity.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryProductsUseCase {
  final InventoryRepository repository;
  GetInventoryProductsUseCase(this.repository);

  Future<Either<Failure, List<InventoryProductEntity>>> call({
    String? query,
    String? categoryId,
    String? supplierId,
    int limit = 15,
  }) {
    return repository.getProducts(
      query: query,
      categoryId: categoryId,
      supplierId: supplierId,
      limit: limit,
    );
  }
}

class SaveInventoryProductUseCase {
  final InventoryRepository repository;
  SaveInventoryProductUseCase(this.repository);

  Future<Either<Failure, void>> call(InventoryProductEntity product) {
    return repository.saveProduct(product);
  }
}

class DeleteInventoryProductUseCase {
  final InventoryRepository repository;
  DeleteInventoryProductUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteProduct(id);
  }
}

class GetLowStockProductsUseCase {
  final InventoryRepository repository;
  GetLowStockProductsUseCase(this.repository);

  Future<Either<Failure, List<InventoryProductEntity>>> call() {
    return repository.getLowStockProducts();
  }
}

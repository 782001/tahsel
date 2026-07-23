import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/inventory_category_entity.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryCategoriesUseCase {
  final InventoryRepository repository;
  GetInventoryCategoriesUseCase(this.repository);

  Future<Either<Failure, List<InventoryCategoryEntity>>> call() {
    return repository.getCategories();
  }
}

class SaveInventoryCategoryUseCase {
  final InventoryRepository repository;
  SaveInventoryCategoryUseCase(this.repository);

  Future<Either<Failure, void>> call(InventoryCategoryEntity category) {
    return repository.saveCategory(category);
  }
}

class DeleteInventoryCategoryUseCase {
  final InventoryRepository repository;
  DeleteInventoryCategoryUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteCategory(id);
  }
}

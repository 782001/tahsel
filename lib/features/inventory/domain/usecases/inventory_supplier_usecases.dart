import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/inventory_supplier_entity.dart';
import '../repositories/inventory_repository.dart';

class GetInventorySuppliersUseCase {
  final InventoryRepository repository;
  GetInventorySuppliersUseCase(this.repository);

  Future<Either<Failure, List<InventorySupplierEntity>>> call() {
    return repository.getSuppliers();
  }
}

class SaveInventorySupplierUseCase {
  final InventoryRepository repository;
  SaveInventorySupplierUseCase(this.repository);

  Future<Either<Failure, void>> call(InventorySupplierEntity supplier) {
    return repository.saveSupplier(supplier);
  }
}

class DeleteInventorySupplierUseCase {
  final InventoryRepository repository;
  DeleteInventorySupplierUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteSupplier(id);
  }
}

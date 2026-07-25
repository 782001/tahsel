import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/inventory_purchase_entity.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryPurchasesUseCase {
  final InventoryRepository repository;
  GetInventoryPurchasesUseCase(this.repository);

  Future<Either<Failure, List<InventoryPurchaseEntity>>> call({
    String? supplierId,
    int limit = 15,
  }) {
    return repository.getPurchases(supplierId: supplierId, limit: limit);
  }
}

class CreateInventoryPurchaseUseCase {
  final InventoryRepository repository;
  CreateInventoryPurchaseUseCase(this.repository);

  Future<Either<Failure, void>> call(InventoryPurchaseEntity purchase) {
    return repository.createPurchase(purchase);
  }
}

class UpdateInventoryPurchaseUseCase {
  final InventoryRepository repository;
  UpdateInventoryPurchaseUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required InventoryPurchaseEntity oldPurchase,
    required InventoryPurchaseEntity newPurchase,
  }) {
    return repository.updatePurchase(
      oldPurchase: oldPurchase,
      newPurchase: newPurchase,
    );
  }
}

class DeleteInventoryPurchaseUseCase {
  final InventoryRepository repository;
  DeleteInventoryPurchaseUseCase(this.repository);

  Future<Either<Failure, void>> call(InventoryPurchaseEntity purchase) {
    return repository.deletePurchase(purchase);
  }
}

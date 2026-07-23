import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/inventory_purchase_entity.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryPurchasesUseCase {
  final InventoryRepository repository;
  GetInventoryPurchasesUseCase(this.repository);

  Future<Either<Failure, List<InventoryPurchaseEntity>>> call({String? supplierId}) {
    return repository.getPurchases(supplierId: supplierId);
  }
}

class CreateInventoryPurchaseUseCase {
  final InventoryRepository repository;
  CreateInventoryPurchaseUseCase(this.repository);

  Future<Either<Failure, void>> call(InventoryPurchaseEntity purchase) {
    return repository.createPurchase(purchase);
  }
}

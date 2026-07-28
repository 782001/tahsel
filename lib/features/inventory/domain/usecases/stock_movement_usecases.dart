import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/stock_movement_entity.dart';
import '../repositories/inventory_repository.dart';

class GetStockMovementsUseCase {
  final InventoryRepository repository;
  GetStockMovementsUseCase(this.repository);

  Future<Either<Failure, List<StockMovementEntity>>> call({
    String? productId,
    int? limit,
  }) {
    return repository.getStockMovements(
      productId: productId,
      limit: limit,
    );
  }
}

class CreateManualStockAdjustmentUseCase {
  final InventoryRepository repository;
  CreateManualStockAdjustmentUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String productId,
    required double adjustmentQuantity,
    required String reason,
  }) {
    return repository.createManualAdjustment(
      productId: productId,
      adjustmentQuantity: adjustmentQuantity,
      reason: reason,
    );
  }
}

class ProcessInvoiceStockUseCase {
  final InventoryRepository repository;
  ProcessInvoiceStockUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String invoiceId,
    required List<Map<String, dynamic>> items,
    required StockMovementType type,
  }) {
    return repository.processInvoiceStockChange(
      invoiceId: invoiceId,
      items: items,
      type: type,
    );
  }
}

class SyncInventoryDataUseCase {
  final InventoryRepository repository;
  SyncInventoryDataUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.syncInventoryData();
  }
}

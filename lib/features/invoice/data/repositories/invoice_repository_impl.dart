import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/core/utils/app_strings.dart';

import '../../../inventory/domain/entities/stock_movement_entity.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_data_source.dart';
import '../models/invoice_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;
  final OfflineSyncRepository offlineSyncRepository;
  final InternetConnectionChecker connectionChecker;

  InvoiceRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineSyncRepository,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, String>> createInvoice(InvoiceEntity invoice) async {
    try {
      final model = InvoiceModel.fromEntity(invoice);

      // ─── 1. GENERATE DETERMINISTIC ID (Idempotency) ───────────────────────
      // Rounded to nearest second to prevent race conditions from double-clicks.
      final timeKey = model.createdAt.millisecondsSinceEpoch ~/ 1000;
      final fingerprint =
          '${model.uid}_${model.totalAmount}_${model.customerName ?? "anon"}_$timeKey';
      final invoiceId = 'inv_${fingerprint.hashCode.abs()}';

      final modelWithId = InvoiceModel.fromEntity(
        invoice.copyWith(id: invoiceId),
      );

      await remoteDataSource.createInvoice(modelWithId);

      // Deduct inventory stock automatically if VIP subscription is active (never for quotation)
      if (AppStrings.isVip && !invoice.isQuotation) {
        _deductInventoryStockForInvoice(invoiceId, modelWithId.items);
      }

      return Right(invoiceId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices(String uid) async {
    try {
      final result = await remoteDataSource.getInvoices(uid);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<InvoiceEntity>>> getInvoicesPaginated(
    String uid, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  }) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      final effectiveForceRefresh = hasConnection ? forceRefresh : false;

      final result = await remoteDataSource.getInvoicesPaginated(
        uid,
        limit: limit,
        lastDocument: lastDocument,
        forceRefresh: effectiveForceRefresh,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getPendingInvoices() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, InvoiceEntity>> getInvoiceById(
    String uid,
    String invoiceId,
  ) async {
    try {
      final result = await remoteDataSource.getInvoiceById(uid, invoiceId);
      if (result == null) {
        return const Left(ServerFailure('Invoice not found'));
      }
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordPayment(
    String uid,
    String invoiceId,
    InvoicePayment payment,
  ) async {
    try {
      final paymentModel = InvoicePaymentModel.fromEntity(payment);
      await remoteDataSource.recordPayment(uid, invoiceId, paymentModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> linkDebtToInvoice(
    String uid,
    String invoiceId,
    String debtId,
  ) async {
    try {
      await remoteDataSource.linkDebtToInvoice(uid, invoiceId, debtId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateInvoice(
    InvoiceEntity invoice, {
    InvoiceEntity? previous,
  }) async {
    try {
      final model = InvoiceModel.fromEntity(invoice);

      // Pre-fetch previous invoice if not provided to guarantee accurate reconciliation
      InvoiceEntity? oldInvoice = previous;
      if (oldInvoice == null && AppStrings.isVip) {
        final existingRes = await getInvoiceById(invoice.uid, invoice.id);
        oldInvoice = existingRes.fold((_) => null, (inv) => inv);
      }

      await remoteDataSource.updateInvoice(model);

      if (AppStrings.isVip && !invoice.isQuotation) {
        if (oldInvoice != null) {
          _reconcileInvoiceStockDeltas(
            invoiceId: model.id,
            oldItems: oldInvoice.items,
            newItems: model.items,
          );
        } else {
          _deductInventoryStockForInvoice(model.id, model.items);
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> voidInvoice(
    String uid,
    String invoiceId, {
    InvoiceEntity? invoice,
  }) async {
    try {
      InvoiceEntity? invoiceToVoid = invoice;
      if (invoiceToVoid == null && AppStrings.isVip) {
        final existingRes = await getInvoiceById(uid, invoiceId);
        invoiceToVoid = existingRes.fold((_) => null, (inv) => inv);
      }

      await remoteDataSource.voidInvoice(uid, invoiceId);

      // Return items back to inventory if VIP subscription is active
      if (AppStrings.isVip &&
          invoiceToVoid != null &&
          !invoiceToVoid.isQuotation &&
          invoiceToVoid.status != InvoiceStatus.voided) {
        await _returnInventoryStockForInvoice(invoiceId, invoiceToVoid.items);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _reconcileInvoiceStockDeltas({
    required String invoiceId,
    required List<InvoiceItem> oldItems,
    required List<InvoiceItem> newItems,
  }) async {
    try {
      if (!AppStrings.isVip) return;
      if (!GetIt.I.isRegistered<InventoryRepository>()) return;

      final inventoryRepo = GetIt.I<InventoryRepository>();

      String cleanName(String raw) {
        String name = raw.trim();
        final match = RegExp(r'^(.*?)(?:\s*\(\s*(\d+(?:\.\d+)?)\s*×.*?\))?$')
            .firstMatch(name);
        if (match != null && match.group(1)?.trim().isNotEmpty == true) {
          name = match.group(1)!.trim();
        }
        return name.toLowerCase();
      }

      final Map<String, _ProductQty> oldMap = {};
      for (final item in oldItems) {
        final key = cleanName(item.description);
        oldMap[key] = _ProductQty(
          name: item.description,
          qty: (oldMap[key]?.qty ?? 0) + item.quantity,
        );
      }

      final Map<String, _ProductQty> newMap = {};
      for (final item in newItems) {
        final key = cleanName(item.description);
        newMap[key] = _ProductQty(
          name: item.description,
          qty: (newMap[key]?.qty ?? 0) + item.quantity,
        );
      }

      final allKeys = {...oldMap.keys, ...newMap.keys};

      final List<Map<String, dynamic>> itemsToReturn = [];
      final List<Map<String, dynamic>> itemsToDeduct = [];

      for (final key in allKeys) {
        final oldQty = oldMap[key]?.qty ?? 0.0;
        final newQty = newMap[key]?.qty ?? 0.0;
        final name = newMap[key]?.name ?? oldMap[key]?.name ?? key;

        final diff = newQty - oldQty;
        if (diff < 0) {
          // Quantity decreased or item deleted -> Return stock back to inventory
          itemsToReturn.add({
            'name': name,
            'quantity': diff.abs(),
          });
        } else if (diff > 0) {
          // Quantity increased or new item added -> Deduct additional stock
          itemsToDeduct.add({
            'name': name,
            'quantity': diff,
          });
        }
      }

      if (itemsToReturn.isNotEmpty) {
        await inventoryRepo.processInvoiceStockChange(
          invoiceId: invoiceId,
          items: itemsToReturn,
          type: StockMovementType.invoiceReturn,
        );
      }

      if (itemsToDeduct.isNotEmpty) {
        await inventoryRepo.processInvoiceStockChange(
          invoiceId: invoiceId,
          items: itemsToDeduct,
          type: StockMovementType.invoiceSale,
        );
      }
    } catch (_) {}
  }

  Future<void> _deductInventoryStockForInvoice(
    String invoiceId,
    List<InvoiceItem> items,
  ) async {
    try {
      if (!AppStrings.isVip) return;
      if (!GetIt.I.isRegistered<InventoryRepository>()) return;

      final inventoryRepo = GetIt.I<InventoryRepository>();
      final itemsMap = items.map((item) {
        String name = item.description.trim();
        final match = RegExp(r'^(.*?)(?:\s*\(\s*(\d+(?:\.\d+)?)\s*×.*?\))?$')
            .firstMatch(name);
        if (match != null && match.group(1)?.trim().isNotEmpty == true) {
          name = match.group(1)!.trim();
        }
        return {
          'name': name,
          'quantity': item.quantity,
        };
      }).toList();

      await inventoryRepo.processInvoiceStockChange(
        invoiceId: invoiceId,
        items: itemsMap,
        type: StockMovementType.invoiceSale,
      );
    } catch (_) {}
  }

  Future<void> _returnInventoryStockForInvoice(
    String invoiceId,
    List<InvoiceItem> items,
  ) async {
    try {
      if (!AppStrings.isVip) return;
      if (!GetIt.I.isRegistered<InventoryRepository>()) return;

      final inventoryRepo = GetIt.I<InventoryRepository>();

      String cleanName(String raw) {
        String name = raw.trim();
        final match = RegExp(r'^(.*?)(?:\s*\(\s*(\d+(?:\.\d+)?)\s*×.*?\))?$')
            .firstMatch(name);
        if (match != null && match.group(1)?.trim().isNotEmpty == true) {
          name = match.group(1)!.trim();
        }
        return name.toLowerCase();
      }

      final Map<String, _ProductQty> grouped = {};
      for (final item in items) {
        final key = cleanName(item.description);
        grouped[key] = _ProductQty(
          name: item.description,
          qty: (grouped[key]?.qty ?? 0) + item.quantity,
        );
      }

      final itemsMap = grouped.values.map((p) {
        String name = p.name.trim();
        final match = RegExp(r'^(.*?)(?:\s*\(\s*(\d+(?:\.\d+)?)\s*×.*?\))?$')
            .firstMatch(name);
        if (match != null && match.group(1)?.trim().isNotEmpty == true) {
          name = match.group(1)!.trim();
        }
        return {
          'name': name,
          'quantity': p.qty,
        };
      }).toList();

      await inventoryRepo.processInvoiceStockChange(
        invoiceId: invoiceId,
        items: itemsMap,
        type: StockMovementType.invoiceReturn,
      );
    } catch (_) {}
  }
}

class _ProductQty {
  final String name;
  final double qty;
  _ProductQty({required this.name, required this.qty});
}

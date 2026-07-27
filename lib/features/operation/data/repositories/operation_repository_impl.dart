import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/utils/app_strings.dart';

import '../../../../core/error/failures.dart';
import '../../../inventory/domain/entities/stock_movement_entity.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../offline_sync/data/models/offline_record.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../domain/entities/operation_entity.dart';
import '../../domain/repositories/operation_repository.dart';
import '../datasources/operation_remote_data_source.dart';
import '../models/operation_model.dart';

class OperationRepositoryImpl implements OperationRepository {
  final OperationRemoteDataSource remoteDataSource;
  final OfflineSyncRepository offlineSyncRepository;
  final InternetConnectionChecker connectionChecker;

  OperationRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineSyncRepository,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, String>> addOperation(
    OperationEntity operation,
  ) async {
    try {
      final model = OperationModel.fromEntity(operation);

      // 1. Generate a DETERMINISTIC local ID (Idempotency Key)
      // This prevents duplicates if the same data is sent multiple times within a short window.
      final transactionDate = model.timestamp ?? DateTime.now();
      final localId = _generateIdempotencyKey(model, transactionDate);

      final Map<String, dynamic> hivePayload = {
        'uid': model.uid,
        'type': model.type,
        'subType': model.subType,
        'customerName': model.customerName,
        'productName': model.productName,
        'totalAmount': model.totalAmount,
        'paidAmount': model.paidAmount,
        'remainingDebt': model.remainingDebt,
        'timestamp': transactionDate.toIso8601String(), // Safe for JSON
        'durationMinutes': model.durationMinutes,
        'turnCount': model.turnCount,
        'rate': model.rate,
      };

      final payloadJson = jsonEncode(hivePayload);

      final offlineRecord = OfflineRecord(
        id: localId,
        amount: model.totalAmount,
        date: transactionDate,
        customerName: model.customerName ?? '',
        type: model.type, // 'cafe' or 'playstation'
        isSynced: false,
        payloadJson: payloadJson,
        collectionName: 'users/${model.uid}/operations',
      );

      // Save to local cache first
      final saveResult = await offlineSyncRepository.saveOfflineRecord(
        offlineRecord,
      );

      // Deduct inventory stock automatically if matching product exists
      if (model.type == 'shop' &&
          model.productName != null &&
          model.productName!.trim().isNotEmpty &&
          AppStrings.isVip) {
        _deductInventoryStock(localId, model.productName!.trim());
      }

      return saveResult.fold((failure) => Left(failure), (_) async {
        // 2. Immediate prioritized sync if online
        final hasConnection = await connectionChecker.hasConnection;
        if (hasConnection) {
          await offlineSyncRepository.syncSingleRecord(offlineRecord);
        }
        return Right(localId);
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _deductInventoryStock(
    String localId,
    String rawProductName,
  ) async {
    try {
      if (!GetIt.I.isRegistered<InventoryRepository>()) return;

      String name = rawProductName;
      double quantity = 1.0;
      final match = RegExp(
        r'^(.*?)(?:\s*\(\s*(\d+(?:\.\d+)?)\s*×.*?\))?$',
      ).firstMatch(rawProductName);
      if (match != null) {
        final extractedName = match.group(1)?.trim();
        if (extractedName != null && extractedName.isNotEmpty) {
          name = extractedName;
        }
        if (match.group(2) != null) {
          quantity = double.tryParse(match.group(2)!) ?? 1.0;
        }
      }

      final inventoryRepo = GetIt.I<InventoryRepository>();
      await inventoryRepo.processInvoiceStockChange(
        invoiceId: localId,
        items: [
          {'name': name, 'quantity': quantity},
        ],
        type: StockMovementType.invoiceSale,
      );
    } catch (_) {}
  }

  String _generateIdempotencyKey(OperationModel model, DateTime date) {
    // Round to the nearest second to collapse millisecond double-taps
    final timeKey = date.millisecondsSinceEpoch ~/ 1000;
    final fingerprint =
        '${model.uid}_${model.type}_${model.totalAmount}_${model.customerName}_$timeKey';
    return 'op_${fingerprint.hashCode.toString()}';
  }
}

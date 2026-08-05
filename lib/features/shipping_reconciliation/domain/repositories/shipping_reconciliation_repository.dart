import 'package:dartz/dartz.dart';
import '../entities/column_mapping_entity.dart';
import '../entities/order_reconciliation_item.dart';
import '../entities/reconciliation_dashboard.dart';

class RawFileData {
  final String fileName;
  final List<String> headers;
  final List<List<dynamic>> rows;

  RawFileData({
    required this.fileName,
    required this.headers,
    required this.rows,
  });

  int get totalRows => rows.length;
}

class ReconciliationResultData {
  final ReconciliationDashboard dashboard;
  final List<OrderReconciliationItem> items;

  ReconciliationResultData({
    required this.dashboard,
    required this.items,
  });
}

abstract class ShippingReconciliationRepository {
  Future<Either<String, RawFileData>> parseFileBytes({
    required List<int> bytes,
    required String fileName,
  });

  Future<Either<String, FileColumnMappingEntity>> detectColumnMapping({
    required RawFileData rawFile,
    required bool isInternalFile,
  });

  Future<Either<String, ReconciliationResultData>> reconcile({
    required RawFileData internalFile,
    required FileColumnMappingEntity internalMapping,
    required RawFileData shippingFile,
    required FileColumnMappingEntity shippingMapping,
  });
}

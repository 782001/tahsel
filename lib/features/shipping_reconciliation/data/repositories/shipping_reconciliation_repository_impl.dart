import 'package:dartz/dartz.dart';

import '../../domain/entities/column_mapping_entity.dart';
import '../../domain/repositories/shipping_reconciliation_repository.dart';
import '../services/column_detector_service.dart';
import '../services/file_parser_service.dart';
import '../services/reconciliation_engine.dart';

class ShippingReconciliationRepositoryImpl
    implements ShippingReconciliationRepository {
  @override
  Future<Either<String, RawFileData>> parseFileBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final rawData = FileParserService.parseBytes(
        bytes: bytes,
        fileName: fileName,
      );
      return Right(rawData);
    } catch (e) {
      return Left('فشل قراءة الملف ($fileName): ${e.toString()}');
    }
  }

  @override
  Future<Either<String, FileColumnMappingEntity>> detectColumnMapping({
    required RawFileData rawFile,
    required bool isInternalFile,
  }) async {
    try {
      final mapping = ColumnDetectorService.detectMapping(
        fileName: rawFile.fileName,
        rawHeaders: rawFile.headers,
        sampleRows: rawFile.rows.take(20).toList(),
        isInternalFile: isInternalFile,
      );
      return Right(mapping);
    } catch (e) {
      return Left('فشل كشف أعمدة الملف (${rawFile.fileName}): ${e.toString()}');
    }
  }

  @override
  Future<Either<String, ReconciliationResultData>> reconcile({
    required RawFileData internalFile,
    required FileColumnMappingEntity internalMapping,
    required RawFileData shippingFile,
    required FileColumnMappingEntity shippingMapping,
  }) async {
    try {
      final params = ReconciliationInputParams(
        internalFile: internalFile,
        internalMapping: internalMapping,
        shippingFile: shippingFile,
        shippingMapping: shippingMapping,
      );

      final result = await ReconciliationEngine.reconcileInIsolate(params);
      return Right(result);
    } catch (e) {
      return Left('حدث خطأ أثناء معالجة وتسوية التقارير: ${e.toString()}');
    }
  }
}

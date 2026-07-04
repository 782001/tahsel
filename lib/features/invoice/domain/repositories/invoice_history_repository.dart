import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/invoice_history_entity.dart';

abstract class InvoiceHistoryRepository {
  /// Appends a batch of history entries for a single invoice edit operation.
  /// Each entry is atomic and immutable after creation.
  Future<Either<Failure, void>> addHistoryEntries({
    required String uid,
    required String invoiceId,
    required List<InvoiceHistoryEntity> entries,
  });

  /// Fetches all history entries for an invoice, ordered newest-first.
  Future<Either<Failure, List<InvoiceHistoryEntity>>> getHistory({
    required String uid,
    required String invoiceId,
  });
}

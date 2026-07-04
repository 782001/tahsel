import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/invoice_history_entity.dart';
import '../repositories/invoice_history_repository.dart';

/// Appends one or more history entries produced by a single edit operation.
/// Call this right after [UpdateInvoiceUseCase] succeeds.
class AddInvoiceHistoryUseCase {
  final InvoiceHistoryRepository repository;
  const AddInvoiceHistoryUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required String invoiceId,
    required List<InvoiceHistoryEntity> entries,
  }) =>
      repository.addHistoryEntries(
        uid: uid,
        invoiceId: invoiceId,
        entries: entries,
      );
}

/// Fetches the full history timeline for a given invoice.
class GetInvoiceHistoryUseCase {
  final InvoiceHistoryRepository repository;
  const GetInvoiceHistoryUseCase(this.repository);

  Future<Either<Failure, List<InvoiceHistoryEntity>>> call({
    required String uid,
    required String invoiceId,
  }) =>
      repository.getHistory(uid: uid, invoiceId: invoiceId);
}

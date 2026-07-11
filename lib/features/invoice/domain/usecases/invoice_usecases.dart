import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

/// Creates a new invoice and persists it locally + syncs if online.
class CreateInvoiceUseCase {
  final InvoiceRepository repository;

  CreateInvoiceUseCase(this.repository);

  Future<Either<Failure, String>> call(InvoiceEntity invoice) {
    return repository.createInvoice(invoice);
  }
}

/// Retrieves all invoices from Firestore for the current user.
class GetInvoicesUseCase {
  final InvoiceRepository repository;

  GetInvoicesUseCase(this.repository);

  Future<Either<Failure, List<InvoiceEntity>>> call(String uid) {
    return repository.getInvoices(uid);
  }
}

/// Returns locally-pending (unsynced) invoices.
class GetPendingInvoicesUseCase {
  final InvoiceRepository repository;

  GetPendingInvoicesUseCase(this.repository);

  Future<Either<Failure, List<InvoiceEntity>>> call() {
    return repository.getPendingInvoices();
  }
}

/// Fetches a single invoice by its ID (detail view).
class GetInvoiceByIdUseCase {
  final InvoiceRepository repository;

  GetInvoiceByIdUseCase(this.repository);

  Future<Either<Failure, InvoiceEntity>> call(String uid, String invoiceId) {
    return repository.getInvoiceById(uid, invoiceId);
  }
}

/// Records a ledger-based payment against an invoice.
/// Never overwrites existing data — appends a new payment record.
class RecordPaymentUseCase {
  final InvoiceRepository repository;

  RecordPaymentUseCase(this.repository);

  Future<Either<Failure, void>> call(
      String uid, String invoiceId, InvoicePayment payment) {
    return repository.recordPayment(uid, invoiceId, payment);
  }
}

/// Links a debt record to an existing invoice.
class LinkDebtToInvoiceUseCase {
  final InvoiceRepository repository;

  LinkDebtToInvoiceUseCase(this.repository);

  Future<Either<Failure, void>> call(
      String uid, String invoiceId, String debtId) {
    return repository.linkDebtToInvoice(uid, invoiceId, debtId);
  }
}

/// Updates mutable invoice fields (customer info, notes, items).
/// Never overwrites payment history or creation metadata.
class UpdateInvoiceUseCase {
  final InvoiceRepository repository;

  UpdateInvoiceUseCase(this.repository);

  Future<Either<Failure, void>> call(InvoiceEntity invoice) {
    return repository.updateInvoice(invoice);
  }
}

/// Permanently voids an invoice.
class VoidInvoiceUseCase {
  final InvoiceRepository repository;

  VoidInvoiceUseCase(this.repository);

  Future<Either<Failure, void>> call(String uid, String invoiceId) {
    return repository.voidInvoice(uid, invoiceId);
  }
}

/// Fetches invoices paginated from Firestore.
class GetInvoicesPaginatedUseCase {
  final InvoiceRepository repository;

  GetInvoicesPaginatedUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<InvoiceEntity>>> call(
    GetInvoicesPaginatedParams params,
  ) {
    return repository.getInvoicesPaginated(
      params.uid,
      limit: params.limit,
      lastDocument: params.lastDocument,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetInvoicesPaginatedParams {
  final String uid;
  final int limit;
  final DocumentSnapshot? lastDocument;
  final bool forceRefresh;

  GetInvoicesPaginatedParams({
    required this.uid,
    this.limit = 15,
    this.lastDocument,
    this.forceRefresh = false,
  });
}


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

// ─────────────────────────────────────────────────────────────────────────────
// Invoice Items / Price Adjustment Use Case
//
// Business Rules (must hold for EVERY invocation):
//
//  1. PRESERVE HISTORY
//     Payment records that already exist MUST NOT be deleted or mutated.
//     The repository layer reads them atomically inside a Firestore transaction
//     so callers never need to pass the old payments list.
//
//  2. RECALCULATION FORMULA
//     After items are edited the new remaining balance is computed as:
//
//         New Remaining = New Invoice Total − Σ All Existing Payments
//
//     The repository layer executes this formula inside the same transaction.
//
//  3. DEBT BASELINE UPDATE
//     If the invoice is linked to a baseline Debt entity (via linkedDebtId),
//     that debt's `totalAmount` and `remainingAmount` MUST be updated to match
//     the new invoice total so every screen stays in sync instantly.
// ─────────────────────────────────────────────────────────────────────────────

/// Params for [UpdateInvoiceUseCase].
///
/// Carry only mutable fields — [updated] contains the new state (items, notes,
/// customer info). The payment array and created-at are always preserved by
/// the repository and must never be passed here.
class UpdateInvoiceItemsParams {
  /// The invoice snapshot with edited fields already applied.
  final InvoiceEntity updated;

  /// The original unmodified snapshot before editing. Used by the cubit to
  /// generate an audit-trail diff. Pass null only when no history is needed.
  final InvoiceEntity? previous;

  const UpdateInvoiceItemsParams({
    required this.updated,
    this.previous,
  });
}

/// Updates mutable invoice fields (customer info, notes, items) and
/// atomically re-syncs the linked Debt entity's baseline.
///
/// Enforces all three business rules documented in [UpdateInvoiceItemsParams].
/// Never overwrites payment history or creation metadata.
class UpdateInvoiceUseCase {
  final InvoiceRepository repository;

  UpdateInvoiceUseCase(this.repository);

  Future<Either<Failure, void>> call(InvoiceEntity invoice,
      {InvoiceEntity? previous}) {
    return repository.updateInvoice(invoice, previous: previous);
  }
}

/// Permanently voids an invoice.
class VoidInvoiceUseCase {
  final InvoiceRepository repository;

  VoidInvoiceUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String uid,
    String invoiceId, {
    InvoiceEntity? invoice,
  }) {
    return repository.voidInvoice(uid, invoiceId, invoice: invoice);
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


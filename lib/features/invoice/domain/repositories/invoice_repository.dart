import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/invoice_entity.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';

abstract class InvoiceRepository {
  /// Creates a new invoice. Saves locally first, syncs if online.
  Future<Either<Failure, String>> createInvoice(InvoiceEntity invoice);

  /// Fetches all invoices for the authenticated user from Firestore.
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices(String uid);

  /// Fetches invoices for the authenticated user paginated from Firestore.
  Future<Either<Failure, PaginatedResult<InvoiceEntity>>> getInvoicesPaginated(
    String uid, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  });

  /// Returns the invoices that are pending local sync.
  Future<Either<Failure, List<InvoiceEntity>>> getPendingInvoices();

  /// Fetches a single invoice by its ID.
  Future<Either<Failure, InvoiceEntity>> getInvoiceById(
      String uid, String invoiceId);

  /// Records a new ledger payment against an existing invoice.
  /// Never mutates the original invoice — creates a new payment record.
  Future<Either<Failure, void>> recordPayment(
      String uid, String invoiceId, InvoicePayment payment);

  /// Links a debt record to an existing invoice.
  Future<Either<Failure, void>> linkDebtToInvoice(
      String uid, String invoiceId, String debtId);

  /// Updates mutable fields (customer info, notes, items) on an existing invoice.
  /// Payments and original totals are never mutated.
  Future<Either<Failure, void>> updateInvoice(InvoiceEntity invoice,
      {InvoiceEntity? previous});

  /// Irreversibly voids an invoice. Status becomes [InvoiceStatus.voided].
  Future<Either<Failure, void>> voidInvoice(
    String uid,
    String invoiceId, {
    InvoiceEntity? invoice,
  });
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/invoice_entity.dart';
import '../models/invoice_model.dart';

import 'package:tahsel/core/usecases/pagination_params.dart';

abstract class InvoiceRemoteDataSource {
  Future<void> createInvoice(InvoiceModel invoice);
  Future<List<InvoiceEntity>> getInvoices(String uid);
  Future<PaginatedResult<InvoiceEntity>> getInvoicesPaginated(
    String uid, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  });
  Future<InvoiceEntity?> getInvoiceById(String uid, String invoiceId);

  /// Atomically appends a payment to the invoice document's `payments` array
  /// and recalculates the status.
  Future<void> recordPayment(
      String uid, String invoiceId, InvoicePaymentModel payment);

  /// Links a debt record to an existing invoice.
  Future<void> linkDebtToInvoice(
      String uid, String invoiceId, String debtId);

  /// Updates mutable invoice fields (customer info, notes, items).
  /// Payments and created-at are never overwritten.
  Future<void> updateInvoice(InvoiceModel invoice);

  /// Marks an invoice as voided. Irreversible.
  Future<void> voidInvoice(String uid, String invoiceId);

  /// Syncs an invoice's paid/remaining totals from its linked debt record.
  /// Called by the Debt module whenever a payment is edited or deleted.
  /// The [debtId] must follow the `debt_inv_<invoiceId>` naming convention.
  Future<void> syncInvoiceFromDebt({
    required String uid,
    required String debtId,
  });
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final FirebaseFirestore firestore;

  InvoiceRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> createInvoice(InvoiceModel invoice) async {
    final payload = invoice.toMap();

    // Convert ISO string dates back to Firestore Timestamps for native querying
    payload['createdAt'] = Timestamp.fromDate(invoice.createdAt);
    if (invoice.lastUpdatedAt != null) {
      payload['lastUpdatedAt'] = Timestamp.fromDate(invoice.lastUpdatedAt!);
    }
    payload['syncedAt'] = FieldValue.serverTimestamp();

    await firestore
        .collection('users/${invoice.uid}/invoices')
        .doc(invoice.id)
        .set(payload, SetOptions(merge: true));
  }

  @override
  Future<List<InvoiceEntity>> getInvoices(String uid) async {
    final snapshot = await firestore
        .collection('users/$uid/invoices')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      _normalizeDates(data);
      data['id'] = doc.id;
      return InvoiceModel.fromMap(data);
    }).toList();
  }

  @override
  Future<PaginatedResult<InvoiceEntity>> getInvoicesPaginated(
    String uid, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  }) async {
    try {
      var query = firestore
          .collection('users/$uid/invoices')
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query
          .limit(limit + 1)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;

      final items = docs.map((doc) {
        final data = doc.data();
        _normalizeDates(data);
        data['id'] = doc.id;
        return InvoiceModel.fromMap(data);
      }).toList();

      final newLastDoc = docs.isNotEmpty ? docs.last : null;

      return PaginatedResult(
        items: items,
        lastDocument: newLastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<InvoiceEntity?> getInvoiceById(String uid, String invoiceId) async {
    final doc = await firestore
        .collection('users/$uid/invoices')
        .doc(invoiceId)
        .get();

    if (!doc.exists) return null;
    final data = doc.data()!;
    _normalizeDates(data);
    data['id'] = doc.id;
    return InvoiceModel.fromMap(data);
  }

  @override
  Future<void> recordPayment(
      String uid, String invoiceId, InvoicePaymentModel payment) async {
    final ref = firestore.collection('users/$uid/invoices').doc(invoiceId);

    // Use a transaction so the status is recalculated atomically
    await firestore.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      _normalizeDates(data);
      data['id'] = snapshot.id;

      final existing = InvoiceModel.fromMap(data);

      // Append the new payment (ledger approach — never overwrites)
      final updatedPayments = [
        ...existing.payments
            .map((p) => InvoicePaymentModel.fromEntity(p).toMap()),
        payment.toMap(),
      ];

      // Recalculate the status based on new totals
      final totalPaid = updatedPayments.fold<double>(
        0.0,
        (acc, p) => acc + (p['amount'] as num).toDouble(),
      );
      final totalAmount = existing.totalAmount;
      final remaining = totalAmount - totalPaid;
      final String newStatus;
      if (remaining <= 0) {
        newStatus = InvoiceStatus.paid.name;
      } else if (totalPaid > 0) {
        newStatus = InvoiceStatus.partial.name;
      } else {
        newStatus = InvoiceStatus.pending.name;
      }

      txn.update(ref, {
        'payments': updatedPayments,
        'status': newStatus,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> linkDebtToInvoice(
      String uid, String invoiceId, String debtId) async {
    final ref = firestore.collection('users/$uid/invoices').doc(invoiceId);
    await ref.update({
      'linkedDebtId': debtId,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    final ref = firestore
        .collection('users/${invoice.uid}/invoices')
        .doc(invoice.id);

    final items = invoice.items
        .map((i) => InvoiceItemModel.fromEntity(i).toMap())
        .toList();

    // Recalculate totalAmount from the updated items so Firestore stays in sync.
    final newTotalAmount = invoice.totalAmount;

    // Use a transaction so we can also recalculate status from the live payments.
    await firestore.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      _normalizeDates(data);
      data['id'] = snapshot.id;

      final existing = InvoiceModel.fromMap(data);

      // Do not touch voided invoices — their status must stay 'voided'.
      if (existing.status == InvoiceStatus.voided) {
        txn.update(ref, {
          'customerName': invoice.customerName,
          'customerPhone': invoice.customerPhone,
          'ledgerNumber': invoice.ledgerNumber,
          'notes': invoice.notes,
          'items': items,
          'totalAmount': newTotalAmount,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Recalculate status based on the new totalAmount and existing payments.
      final totalPaid = existing.payments.fold<double>(
        0.0,
        (acc, p) => acc + p.amount,
      );
      final remaining = (newTotalAmount - totalPaid).clamp(0.0, double.infinity);
      final String newStatus;
      if (remaining <= 0 && newTotalAmount > 0) {
        newStatus = InvoiceStatus.paid.name;
      } else if (totalPaid > 0) {
        newStatus = InvoiceStatus.partial.name;
      } else {
        newStatus = InvoiceStatus.pending.name;
      }

      txn.update(ref, {
        'customerName': invoice.customerName,
        'customerPhone': invoice.customerPhone,
        'ledgerNumber': invoice.ledgerNumber,
        'notes': invoice.notes,
        'items': items,
        'totalAmount': newTotalAmount,
        'status': newStatus,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> voidInvoice(String uid, String invoiceId) async {
    final ref = firestore.collection('users/$uid/invoices').doc(invoiceId);
    await ref.update({
      'status': InvoiceStatus.voided.name,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> syncInvoiceFromDebt({
    required String uid,
    required String debtId,
  }) async {
    // The debt ID convention used when creating invoice-linked debts is:
    //   debt_inv_<invoiceId>
    // Extract the invoiceId from the debtId.
    const prefix = 'debt_inv_';
    if (!debtId.startsWith(prefix)) return; // Not an invoice-linked debt
    final invoiceId = debtId.substring(prefix.length);
    if (invoiceId.isEmpty) return;

    final debtRef = firestore
        .collection('users/$uid/debts')
        .doc(debtId);
    final invoiceRef = firestore
        .collection('users/$uid/invoices')
        .doc(invoiceId);

    await firestore.runTransaction((txn) async {
      // Read both documents inside the transaction
      final debtSnap = await txn.get(debtRef);
      final invoiceSnap = await txn.get(invoiceRef);

      if (!invoiceSnap.exists) return; // Invoice may have been voided/deleted

      final invoiceData = invoiceSnap.data()!;
      _normalizeDates(invoiceData);
      invoiceData['id'] = invoiceSnap.id;

      final invoice = InvoiceModel.fromMap(invoiceData);

      // Do not touch voided invoices
      if (invoice.status == InvoiceStatus.voided) return;

      double totalPaid = 0.0;

      if (debtSnap.exists) {
        final debtData = debtSnap.data()!;
        // paidAmount on the debt == how much has been paid via the Debt module
        // totalAmount on the debt == remaining from the invoice (set at debt creation)
        // Invoice.totalPaid = sum of all InvoicePayments + payments recorded via debt
        //
        // Strategy: recalculate from the invoice's own payment ledger (the ground
        // truth for what was paid at invoice time) plus whatever the debt shows
        // as paidAmount (paid via the Debt module after the debt was created).
        final debtPaid = (debtData['paidAmount'] as num?)?.toDouble() ?? 0.0;

        // Payments recorded directly on the invoice (before debt was created)
        final invoicePaymentTotal = invoice.payments.fold<double>(
          0.0,
          (acc, p) => acc + p.amount,
        );

        totalPaid = invoicePaymentTotal + debtPaid;
      } else {
        // Debt was deleted — only count invoice-level payments
        totalPaid = invoice.payments.fold<double>(0.0, (acc, p) => acc + p.amount);
      }

      final totalAmount = invoice.totalAmount;
      final remaining = (totalAmount - totalPaid).clamp(0.0, double.infinity);

      final String newStatus;
      if (remaining <= 0) {
        newStatus = InvoiceStatus.paid.name;
      } else if (totalPaid > 0) {
        newStatus = InvoiceStatus.partial.name;
      } else {
        newStatus = InvoiceStatus.pending.name;
      }

      txn.update(invoiceRef, {
        'status': newStatus,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _normalizeDates(Map<String, dynamic> data) {
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] =
          (data['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (data['lastUpdatedAt'] is Timestamp) {
      data['lastUpdatedAt'] =
          (data['lastUpdatedAt'] as Timestamp).toDate().toIso8601String();
    }
  }
}

/// Converts a raw JSON payload string from an OfflineRecord into
/// a Firestore-ready Map. Used by OfflineRemoteDataSource.
Map<String, dynamic> invoicePayloadToFirestoreMap(String payloadJson) {
  final map = jsonDecode(payloadJson) as Map<String, dynamic>;
  // Convert date strings to Timestamps
  if (map['createdAt'] is String) {
    map['createdAt'] = Timestamp.fromDate(DateTime.parse(map['createdAt']));
  }
  if (map['lastUpdatedAt'] is String && map['lastUpdatedAt'] != null) {
    map['lastUpdatedAt'] =
        Timestamp.fromDate(DateTime.parse(map['lastUpdatedAt'] as String));
  }
  map['syncedAt'] = FieldValue.serverTimestamp();
  return map;
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/core/utils/summary_helper.dart';

import '../../domain/entities/invoice_entity.dart';
import '../models/invoice_model.dart';

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
    String uid,
    String invoiceId,
    InvoicePaymentModel payment,
  );

  /// Links a debt record to an existing invoice.
  Future<void> linkDebtToInvoice(String uid, String invoiceId, String debtId);

  /// Updates mutable invoice fields (customer info, notes, items).
  /// Payments and created-at are never overwritten.
  Future<void> updateInvoice(InvoiceModel invoice);

  /// Marks an invoice as voided. Irreversible.
  Future<void> voidInvoice(String uid, String invoiceId);
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
    String uid,
    String invoiceId,
    InvoicePaymentModel payment,
  ) async {
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
        ...existing.payments.map(
          (p) => InvoicePaymentModel.fromEntity(p).toMap(),
        ),
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
    String uid,
    String invoiceId,
    String debtId,
  ) async {
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

    // Pre-read the invoice BEFORE the transaction to capture the old total and
    // linkedDebtId. This avoids needing to read a subcollection inside the
    // transaction, which causes a platform-thread crash on Windows desktop.
    String? capturedDebtId;
    double oldInvoiceTotal = 0;

    final preSnap = await ref.get();
    if (preSnap.exists) {
      final preData = preSnap.data()!;
      capturedDebtId =
          (preData['linkedDebtId'] as String?) ?? 'debt_inv_${invoice.id}';
      oldInvoiceTotal = (preData['totalAmount'] as num?)?.toDouble() ?? 0.0;
    }

    // Use a transaction to atomically update the invoice + linked debt.
    await firestore.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      _normalizeDates(data);
      data['id'] = snapshot.id;

      final existing = InvoiceModel.fromMap(data);

      final debtId = existing.linkedDebtId ?? 'debt_inv_${invoice.id}';
      final debtRef = firestore
          .collection('users/${invoice.uid}/debts')
          .doc(debtId);
      final debtSnap = await txn.get(debtRef);

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
      // Use debt.paidAmount if the debt exists, as it is the single source of truth.
      double totalPaid;
      if (debtSnap.exists) {
        final debtData = debtSnap.data()!;
        totalPaid = (debtData['paidAmount'] as num?)?.toDouble() ?? 0.0;
      } else {
        totalPaid = existing.payments.fold<double>(
          0.0,
          (acc, p) => acc + p.amount,
        );
      }

      final double debtRemaining = newTotalAmount - totalPaid;
      
      final String newStatus;
      if (debtRemaining <= 0 && newTotalAmount > 0) {
        newStatus = InvoiceStatus.paid.name;
      } else if (totalPaid > 0) {
        newStatus = InvoiceStatus.partial.name;
      } else {
        newStatus = InvoiceStatus.pending.name;
      }

      // Update the linked baseline Debt entity if it exists.
      if (debtSnap.exists) {
        txn.update(debtRef, {
          'totalAmount': newTotalAmount,
          'remainingAmount': debtRemaining,
          'isPaid': debtRemaining <= 0,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
          if (invoice.customerName != null)
            'customerName': (invoice.customerName ?? '')
                .replaceAll('/', ' ')
                .trim(),
          if (invoice.customerPhone != null)
            'phoneNumber': invoice.customerPhone,
        });

        // Update summaries to keep TotalDebtsSummaryCard in sync
        final debtData = debtSnap.data()!;
        final currentRemaining = (debtData['remainingAmount'] as num?)?.toDouble() ?? 0.0;
        
        if (debtRemaining != currentRemaining || newTotalAmount != oldInvoiceTotal) {
          final debtTimestamp = (debtData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          
          final currentIsPaid = currentRemaining <= 0;
          final newIsPaid = debtRemaining <= 0;
          
          final totalDebtsDelta = debtRemaining - currentRemaining;
          final unpaidDelta = (newIsPaid ? 0.0 : debtRemaining) - (currentIsPaid ? 0.0 : currentRemaining);
          
          final oldPaidDebtValue = currentIsPaid ? oldInvoiceTotal : 0.0;
          final newPaidDebtValue = newIsPaid ? newTotalAmount : 0.0;
          final paidDelta = newPaidDebtValue - oldPaidDebtValue;
          
          final Map<String, Map<String, double>> summaryAccumulator = {};
          void addSummaryIncrement(String key, String field, double value) {
            if (value == 0) return;
            summaryAccumulator.putIfAbsent(key, () => {});
            summaryAccumulator[key]![field] = (summaryAccumulator[key]![field] ?? 0.0) + value;
          }

          final debtKeys = SummaryHelper.getSummaryKeys(debtTimestamp);
          for (final key in debtKeys) {
            addSummaryIncrement(key, 'totalDebts', totalDebtsDelta);
            addSummaryIncrement(key, 'unpaidDebts', unpaidDelta);
            addSummaryIncrement(key, 'paidDebts', paidDelta);
          }

          for (final entry in summaryAccumulator.entries) {
            final summaryRef = firestore
                .collection('users/${invoice.uid}/summaries')
                .doc(entry.key);
            final Map<String, dynamic> updateData = {};
            entry.value.forEach((field, val) {
              updateData[field] = FieldValue.increment(val);
            });
            updateData['lastUpdatedAt'] = FieldValue.serverTimestamp();

            txn.set(summaryRef, updateData, SetOptions(merge: true));
          }
        }
      }

      txn.update(ref, {
        'customerName': invoice.customerName,
        'customerPhone': invoice.customerPhone,
        'ledgerNumber': invoice.ledgerNumber,
        'notes': invoice.notes,
        'items': items,
        'totalAmount': newTotalAmount,
        'status': newStatus,
        'syncedTotalPaid': totalPaid,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    });

    // ── Post-transaction: update _initial payment record ─────────────────────
    // This MUST be outside the transaction to avoid a Firestore platform-thread
    // crash on Windows desktop when reading a subcollection inside a transaction.
    // Applies whenever the total changes in either direction (increase OR decrease).
    // When the total decreases below what was already paid, the debt's original
    // amount is adjusted to match the new invoice total so all calculations remain
    // based on the actual agreed amount.
    if (capturedDebtId != null && newTotalAmount != oldInvoiceTotal) {
      final initialPayRef = firestore
          .collection('users/${invoice.uid}/debts')
          .doc(capturedDebtId)
          .collection('payments')
          .doc('${capturedDebtId}_initial');

      final initialSnap = await initialPayRef.get();
      if (initialSnap.exists) {
        // remainingAmount on the _initial record always mirrors the new invoice
        // total — it represents what was originally owed, not how much is left.
        await initialPayRef.update({
          'amountPaid': newTotalAmount,
          'remainingAmount': newTotalAmount,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Future<void> voidInvoice(String uid, String invoiceId) async {
    final invoiceRef = firestore
        .collection('users/$uid/invoices')
        .doc(invoiceId);

    // ── 1. Read the invoice to discover linkedDebtId ──────────────────────────
    final invoiceDoc = await invoiceRef.get();
    final linkedDebtId =
        (invoiceDoc.data()?['linkedDebtId'] as String?) ??
        'debt_inv_$invoiceId';

    final debtRef = firestore.collection('users/$uid/debts').doc(linkedDebtId);
    final debtDoc = await debtRef.get();

    final batch = firestore.batch();

    // ── 2. Mark invoice as voided ─────────────────────────────────────────────
    batch.update(invoiceRef, {
      'status': InvoiceStatus.voided.name,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    // ── 3. Clean up linked debt (if it exists) ────────────────────────────────
    if (debtDoc.exists) {
      final debtData = debtDoc.data()!;

      // 3a. Fetch all payment sub-documents and schedule their deletion
      final paymentsSnap = await debtRef.collection('payments').get();
      for (final payDoc in paymentsSnap.docs) {
        batch.delete(payDoc.reference);
      }

      // 3b. Delete the linked operation record (if any)
      final operationId = debtData['operationId'] as String?;
      if (operationId != null && operationId.isNotEmpty) {
        batch.delete(
          firestore.collection('users/$uid/operations').doc(operationId),
        );
      }

      // 3c. Delete the debt document itself
      batch.delete(debtRef);

      // ── 4. Decrement summary metrics ─────────────────────────────────────────
      final timestamp =
          (debtData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final remainingAmount =
          (debtData['remainingAmount'] as num?)?.toDouble() ?? 0.0;
      final totalAmount = (debtData['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final isPaid = (debtData['isPaid'] as bool?) ?? false;

      // Check if this was the customer's last unpaid debt so we can decrement
      // the debtCustomersCount summary field.
      bool shouldDecrementCustomerCount = false;
      if (!isPaid) {
        final otherUnpaid = await firestore
            .collection('users/$uid/debts')
            .where('customerName', isEqualTo: debtData['customerName'])
            .where('isPaid', isEqualTo: false)
            .limit(2)
            .get();
        // <=1 means only the current (soon-to-be-deleted) debt is unpaid.
        if (otherUnpaid.docs.length <= 1) {
          shouldDecrementCustomerCount = true;
        }
      }

      // Accumulate all summary field increments so we write each doc once.
      final Map<String, Map<String, double>> summaryAccumulator = {};

      void addIncrement(String key, String field, double value) {
        summaryAccumulator.putIfAbsent(key, () => {});
        summaryAccumulator[key]![field] =
            (summaryAccumulator[key]![field] ?? 0.0) + value;
      }

      // Revert debt totals (keyed to the debt's original creation timestamp)
      final debtKeys = SummaryHelper.getSummaryKeys(timestamp);
      for (final key in debtKeys) {
        addIncrement(key, 'totalDebts', -remainingAmount);
        if (!isPaid) {
          addIncrement(key, 'unpaidDebts', -remainingAmount);
        } else {
          addIncrement(key, 'paidDebts', -totalAmount);
        }
      }

      // Revert each collected payment (keyed to the payment's own timestamp)
      for (final payDoc in paymentsSnap.docs) {
        final pData = payDoc.data();
        final type = pData['type'] as String?;
        final amountPaid = (pData['amountPaid'] as num?)?.toDouble() ?? 0.0;
        final payTimestamp =
            (pData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        if (type == 'full' || type == 'partial' || type == 'settlement') {
          final payKeys = SummaryHelper.getSummaryKeys(payTimestamp);
          for (final key in payKeys) {
            addIncrement(key, 'totalCollected', -amountPaid);
          }
        }
      }

      // Revert customer debt count (keyed to now)
      if (shouldDecrementCustomerCount) {
        final nowKeys = SummaryHelper.getSummaryKeys(DateTime.now());
        for (final key in nowKeys) {
          addIncrement(key, 'debtCustomersCount', -1.0);
        }
      }

      // Write all summary increments into the batch
      summaryAccumulator.forEach((key, fields) {
        final summaryRef = firestore
            .collection('users/$uid/summaries')
            .doc(key);
        final updateData = <String, dynamic>{
          for (final e in fields.entries) e.key: FieldValue.increment(e.value),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        };
        batch.set(summaryRef, updateData, SetOptions(merge: true));
      });
    }

    await batch.commit();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _normalizeDates(Map<String, dynamic> data) {
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    if (data['lastUpdatedAt'] is Timestamp) {
      data['lastUpdatedAt'] = (data['lastUpdatedAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    // Normalize paidAt inside each payment entry.
    // Payments added from the Debt module store paidAt as a Firestore Timestamp.
    if (data['payments'] is List) {
      final payments = data['payments'] as List<dynamic>;
      for (final p in payments) {
        if (p is Map<String, dynamic> && p['paidAt'] is Timestamp) {
          p['paidAt'] = (p['paidAt'] as Timestamp).toDate().toIso8601String();
        }
      }
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
    map['lastUpdatedAt'] = Timestamp.fromDate(
      DateTime.parse(map['lastUpdatedAt'] as String),
    );
  }
  map['syncedAt'] = FieldValue.serverTimestamp();
  return map;
}

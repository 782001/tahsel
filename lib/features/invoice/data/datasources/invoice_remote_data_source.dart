import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/activity_logger_service.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/core/utils/app_strings.dart';
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

  /// Converts an existing quotation into an active sales invoice.
  Future<void> convertQuotationToInvoice(
    InvoiceModel invoice, {
    DateTime? dueDate,
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
    if (invoice.dueDate != null) {
      payload['dueDate'] = Timestamp.fromDate(invoice.dueDate!);
    } else {
      payload['dueDate'] = null;
    }
    payload['syncedAt'] = FieldValue.serverTimestamp();

    await firestore
        .collection('users/${invoice.uid}/invoices')
        .doc(invoice.id)
        .set(payload, SetOptions(merge: true));

    if (sl.isRegistered<ActivityLoggerService>()) {
      final isQuotation = invoice.status == InvoiceStatus.quotation;
      final refNum =
          (invoice.referenceNumber != null &&
              invoice.referenceNumber!.isNotEmpty)
          ? invoice.referenceNumber!
          : invoice.id;
      final hasSpecificCustomer =
          invoice.customerName != null &&
          invoice.customerName!.trim().isNotEmpty;
      final cust = hasSpecificCustomer
          ? invoice.customerName!.trim()
          : 'عميل عام';
      final totalFormatted = invoice.totalAmount.toSmartAmount();
      final paid = invoice.syncedTotalPaid ?? 0.0;
      final paidFormatted = paid.toSmartAmount();
      final rem = invoice.totalAmount - paid;
      final remFormatted = rem > 0 ? rem.toSmartAmount() : "0.0";

      final actionTitle = isQuotation
          ? (hasSpecificCustomer
                ? 'عرض سعر للعميل: $cust'
                : 'عرض سعر جديد (#$refNum)')
          : (hasSpecificCustomer
                ? 'فاتورة مبيعات للعميل: $cust'
                : 'فاتورة مبيعات (#$refNum)');

      final actionDetails = isQuotation
          ? 'إنشاء وتجهيز عرض سعر للعميل ($cust) بقيمة $totalFormatted ${AppStrings.currencyEgp.tr()} (${invoice.items.length} أصناف) - الرقم المرجعي: $refNum'
          : 'فاتورة مبيعات للعميل ($cust) بقيمة $totalFormatted ${AppStrings.currencyEgp.tr()} (${invoice.items.length} أصناف) - المدفوع: $paidFormatted ج.م، المتبقي: $remFormatted ج.م (المرجع: $refNum)';

      sl<ActivityLoggerService>().logStandalone(
        ownerUid: invoice.uid,
        employeeUid: invoice.creatorEmployeeUid,
        employeeName: invoice.creatorEmployeeName,
        actionCategory: 'invoices',
        actionType: isQuotation ? 'create_quotation' : 'create_invoice',
        actionTitle: actionTitle,
        details: actionDetails,
        amount: invoice.totalAmount,
        extraData: {
          'invoiceId': invoice.id,
          'referenceNumber': invoice.referenceNumber,
          'customerName': invoice.customerName,
          'itemCount': invoice.items.length,
          'totalAmount': invoice.totalAmount,
          'paidAmount': invoice.syncedTotalPaid,
          'remainingAmount': rem > 0 ? rem : 0.0,
          'isQuotation': isQuotation,
          'status': invoice.status.name,
        },
        timestamp: invoice.createdAt,
      );
    }
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

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await query
            .limit(limit + 1)
            .get(
              GetOptions(
                source: forceRefresh ? Source.server : Source.serverAndCache,
              ),
            );
      } catch (e) {
        if (e is FirebaseException && e.code == 'unavailable') {
          snapshot = await query
              .limit(limit + 1)
              .get(const GetOptions(source: Source.cache));
        } else {
          rethrow;
        }
      }

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

    String? capturedRefNum;
    String? capturedCustName;
    double capturedRemaining = 0.0;
    String capturedStatus = '';

    // Use a transaction so the status is recalculated atomically
    await firestore.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      _normalizeDates(data);
      data['id'] = snapshot.id;

      final existing = InvoiceModel.fromMap(data);

      // Quotations and voided invoices cannot receive payments
      if (existing.status == InvoiceStatus.quotation ||
          existing.status == InvoiceStatus.voided) {
        return;
      }

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

      capturedRefNum = existing.referenceNumber;
      capturedCustName = existing.customerName;
      capturedRemaining = remaining;
      capturedStatus = newStatus;

      txn.update(ref, {
        'payments': updatedPayments,
        'status': newStatus,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    });

    if (sl.isRegistered<ActivityLoggerService>()) {
      final amtFormatted = payment.amount.toSmartAmount();
      final rem = capturedRemaining > 0
          ? capturedRemaining.toSmartAmount()
          : "0.0";
      final refNum = capturedRefNum != null && capturedRefNum!.isNotEmpty
          ? capturedRefNum!
          : invoiceId;
      final cust = capturedCustName != null && capturedCustName!.isNotEmpty
          ? ' للعميل $capturedCustName'
          : '';

      sl<ActivityLoggerService>().logStandalone(
        ownerUid: uid,
        actionCategory: 'invoices',
        actionType: 'record_invoice_payment',
        actionTitle: 'تحصيل دفعة فاتورة: $refNum',
        details:
            'تحصيل دفعة بقيمة $amtFormatted ${AppStrings.currencyEgp.tr()}$cust على الفاتورة $refNum (المتبقي: $rem ${AppStrings.currencyEgp.tr()})${payment.note != null && payment.note!.isNotEmpty ? " (${payment.note})" : ""}',
        amount: payment.amount,
        extraData: {
          'invoiceId': invoiceId,
          'paymentId': payment.id,
          'referenceNumber': capturedRefNum,
          'customerName': capturedCustName,
          'amountPaid': payment.amount,
          'remaining': capturedRemaining > 0 ? capturedRemaining : 0.0,
          'newStatus': capturedStatus,
          'note': payment.note,
        },
        timestamp: payment.paidAt,
      );
    }
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
    Map<String, dynamic>? preData;

    try {
      final preSnap = await ref.get();
      if (preSnap.exists && preSnap.data() != null) {
        preData = preSnap.data()!;
        capturedDebtId =
            (preData['linkedDebtId'] as String?) ?? 'debt_inv_${invoice.id}';
        oldInvoiceTotal = (preData['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}

    // Use a transaction to atomically update the invoice + linked debt.
    await firestore.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      _normalizeDates(data);
      data['id'] = snapshot.id;

      final existing = InvoiceModel.fromMap(data);
      oldInvoiceTotal = existing.totalAmount;

      final debtId = existing.linkedDebtId ?? 'debt_inv_${invoice.id}';
      final debtRef = firestore
          .collection('users/${invoice.uid}/debts')
          .doc(debtId);
      final debtSnap = await txn.get(debtRef);

      // The operation that represents the initial debt creation also shares the debtId
      final opRef = firestore
          .collection('users/${invoice.uid}/operations')
          .doc(debtId);
      final opSnap = await txn.get(opRef);

      // Do not recalculate status or touch debts for quotations or voided invoices.
      if (existing.status == InvoiceStatus.quotation ||
          existing.status == InvoiceStatus.voided) {
        txn.update(ref, {
          'customerName': invoice.customerName,
          'customerPhone': invoice.customerPhone,
          'ledgerNumber': invoice.ledgerNumber,
          'notes': invoice.notes,
          'items': items,
          'totalAmount': newTotalAmount,
          'discountAmount': invoice.discountAmount,
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
          'dueDate': invoice.dueDate != null
              ? Timestamp.fromDate(invoice.dueDate!)
              : null,
          'lastReminderSentAt': null,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
          if (invoice.customerName != null)
            'customerName': (invoice.customerName ?? '')
                .replaceAll('/', ' ')
                .trim(),
          if (invoice.customerPhone != null)
            'phoneNumber': invoice.customerPhone,
        });

        // Sync the same updates to the Operations log entry
        if (opSnap.exists) {
          txn.update(opRef, {
            'totalAmount': newTotalAmount,
            'remainingDebt': debtRemaining,
            'dueDate': invoice.dueDate != null
                ? Timestamp.fromDate(invoice.dueDate!)
                : null,
            if (invoice.customerName != null)
              'customerName': (invoice.customerName ?? '')
                  .replaceAll('/', ' ')
                  .trim(),
          });
        }

        // Update summaries to keep TotalDebtsSummaryCard in sync
        final debtData = debtSnap.data()!;
        final currentRemaining =
            (debtData['remainingAmount'] as num?)?.toDouble() ?? 0.0;

        if (debtRemaining != currentRemaining ||
            newTotalAmount != oldInvoiceTotal) {
          final debtTimestamp =
              (debtData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

          final currentIsPaid = currentRemaining <= 0;
          final newIsPaid = debtRemaining <= 0;

          final totalDebtsDelta = debtRemaining - currentRemaining;
          final unpaidDelta =
              (newIsPaid ? 0.0 : debtRemaining) -
              (currentIsPaid ? 0.0 : currentRemaining);

          final oldPaidDebtValue = currentIsPaid ? oldInvoiceTotal : 0.0;
          final newPaidDebtValue = newIsPaid ? newTotalAmount : 0.0;
          final paidDelta = newPaidDebtValue - oldPaidDebtValue;

          final Map<String, Map<String, double>> summaryAccumulator = {};
          void addSummaryIncrement(String key, String field, double value) {
            if (value == 0) return;
            summaryAccumulator.putIfAbsent(key, () => {});
            summaryAccumulator[key]![field] =
                (summaryAccumulator[key]![field] ?? 0.0) + value;
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
        'discountAmount': invoice.discountAmount,
        'status': newStatus,
        'syncedTotalPaid': totalPaid,
        'dueDate': invoice.dueDate != null
            ? Timestamp.fromDate(invoice.dueDate!)
            : null,
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

    if (sl.isRegistered<ActivityLoggerService>()) {
      final refNum =
          (invoice.referenceNumber != null &&
              invoice.referenceNumber!.isNotEmpty)
          ? invoice.referenceNumber!
          : invoice.id;
      final hasTotalChanged = (newTotalAmount - oldInvoiceTotal).abs() > 0.001;
      final oldFormatted = oldInvoiceTotal.toSmartAmount();
      final newFormatted = newTotalAmount.toSmartAmount();
      final delta = newTotalAmount - oldInvoiceTotal;
      final deltaFormatted = delta.toSmartAmount();
      final cust =
          (invoice.customerName != null && invoice.customerName!.isNotEmpty)
          ? invoice.customerName!
          : 'عميل عام';

      final List<String> changes = [];
      if (hasTotalChanged) {
        final sign = delta >= 0 ? '+$deltaFormatted' : deltaFormatted;
        changes.add(
          'الإجمالي من $oldFormatted إلى $newFormatted ${AppStrings.currencyEgp.tr()} ($sign)',
        );
      }
      if (preData != null) {
        final oldCust = (preData['customerName'] as String?)?.trim() ?? '';
        final newCust = (invoice.customerName ?? '').trim();
        if (oldCust != newCust && (oldCust.isNotEmpty || newCust.isNotEmpty)) {
          changes.add(
            'العميل من "${oldCust.isEmpty ? 'عميل عام' : oldCust}" إلى "${newCust.isEmpty ? 'عميل عام' : newCust}"',
          );
        }
        final oldPhone = (preData['customerPhone'] as String?)?.trim() ?? '';
        final newPhone = (invoice.customerPhone ?? '').trim();
        if (oldPhone != newPhone &&
            (oldPhone.isNotEmpty || newPhone.isNotEmpty)) {
          changes.add(
            'الهاتف من "${oldPhone.isEmpty ? 'بدون' : oldPhone}" إلى "${newPhone.isEmpty ? 'بدون' : newPhone}"',
          );
        }
        final oldDiscount =
            (preData['discountAmount'] as num?)?.toDouble() ?? 0.0;
        final newDiscount = invoice.discountAmount;
        if ((oldDiscount - newDiscount).abs() > 0.001) {
          changes.add(
            'الخصم من ${oldDiscount.toSmartAmount()} إلى ${newDiscount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
          );
        }
        final oldItemsRaw = preData['items'] as List<dynamic>?;
        final oldItemsCount = oldItemsRaw?.length ?? 0;
        if (oldItemsCount != invoice.items.length) {
          changes.add(
            'عدد الأصناف من $oldItemsCount إلى ${invoice.items.length}',
          );
        }
        DateTime? oldDueDate;
        final rawOldDue = preData['dueDate'];
        if (rawOldDue is Timestamp) {
          oldDueDate = rawOldDue.toDate();
        } else if (rawOldDue is String) {
          oldDueDate = DateTime.tryParse(rawOldDue);
        }
        if (oldDueDate != invoice.dueDate) {
          if (oldDueDate != null && invoice.dueDate != null) {
            final oldDStr =
                '${oldDueDate.year}-${oldDueDate.month.toString().padLeft(2, '0')}-${oldDueDate.day.toString().padLeft(2, '0')}';
            final newDStr =
                '${invoice.dueDate!.year}-${invoice.dueDate!.month.toString().padLeft(2, '0')}-${invoice.dueDate!.day.toString().padLeft(2, '0')}';
            if (oldDStr != newDStr) {
              changes.add('تاريخ الاستحقاق من $oldDStr إلى $newDStr');
            }
          } else if (oldDueDate == null && invoice.dueDate != null) {
            final newDStr =
                '${invoice.dueDate!.year}-${invoice.dueDate!.month.toString().padLeft(2, '0')}-${invoice.dueDate!.day.toString().padLeft(2, '0')}';
            changes.add('تحديد تاريخ استحقاق: $newDStr');
          } else if (oldDueDate != null && invoice.dueDate == null) {
            changes.add('إلغاء تاريخ الاستحقاق');
          }
        }
        final oldNotes = (preData['notes'] as String?)?.trim() ?? '';
        final newNotes = (invoice.notes ?? '').trim();
        if (oldNotes != newNotes &&
            (oldNotes.isNotEmpty || newNotes.isNotEmpty)) {
          changes.add(
            'الملاحظات من "${oldNotes.isEmpty ? 'بدون' : oldNotes}" إلى "${newNotes.isEmpty ? 'بدون' : newNotes}"',
          );
        }
      }

      final detailsText = changes.isNotEmpty
          ? 'تعديل الفاتورة ($refNum) للعميل $cust: تم تعديل ${changes.join("، ")}'
          : (hasTotalChanged
                ? 'تعديل فاتورة للعميل $cust: تم تغيير المبلغ من $oldFormatted ${AppStrings.currencyEgp.tr()} إلى $newFormatted ${AppStrings.currencyEgp.tr()} (الفارق: $deltaFormatted ${AppStrings.currencyEgp.tr()})'
                : 'تعديل بيانات وأصناف الفاتورة $refNum للعميل $cust');

      sl<ActivityLoggerService>().logStandalone(
        ownerUid: invoice.uid,
        actionCategory: 'invoices',
        actionType: hasTotalChanged
            ? 'update_invoice_total'
            : 'update_invoice_details',
        actionTitle: hasTotalChanged
            ? 'تعديل قيمة فاتورة: $refNum'
            : 'تعديل بيانات فاتورة: $refNum',
        details: detailsText,
        amount: newTotalAmount,
        extraData: {
          'invoiceId': invoice.id,
          'referenceNumber': invoice.referenceNumber,
          'oldTotal': oldInvoiceTotal,
          'newTotal': newTotalAmount,
          'delta': delta,
          'customerName': invoice.customerName,
          'itemCount': invoice.items.length,
          'changes': changes,
        },
      );
    }
  }

  @override
  Future<void> voidInvoice(String uid, String invoiceId) async {
    final invoiceRef = firestore
        .collection('users/$uid/invoices')
        .doc(invoiceId);

    // ── 1. Read the invoice to discover linkedDebtId ──────────────────────────
    final invoiceDoc = await invoiceRef.get();
    if (!invoiceDoc.exists) return;
    if (invoiceDoc.data()?['status'] == InvoiceStatus.quotation.name) {
      return; // Quotations cannot be voided
    }
    final linkedDebtId =
        (invoiceDoc.data()?['linkedDebtId'] as String?) ??
        'debt_inv_$invoiceId';

    final debtRef = firestore.collection('users/$uid/debts').doc(linkedDebtId);
    final debtDoc = await debtRef.get();

    final batch = firestore.batch();

    // ── 2. Mark invoice as voided and sanitize payments array ────────────────
    final rawPayments = (invoiceDoc.data()?['payments'] as List<dynamic>? ?? [])
        .map((p) => InvoicePaymentModel.fromMap(p as Map<String, dynamic>))
        .toList();
    final cleanPayments = InvoiceEntity.deduplicatePayments(rawPayments);
    final cleanPaymentsPayload = cleanPayments
        .map((p) => InvoicePaymentModel.fromEntity(p).toMap())
        .toList();

    batch.update(invoiceRef, {
      'status': InvoiceStatus.voided.name,
      'payments': cleanPaymentsPayload,
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
        addIncrement(key, 'totalDebts', -totalAmount);
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

    // ── Log Employee Activity ──
    if (sl.isRegistered<ActivityLoggerService>()) {
      final totalAmount =
          (invoiceDoc.data()?['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final totalFormatted = totalAmount.toSmartAmount();
      final refNum =
          (invoiceDoc.data()?['referenceNumber'] as String?) ?? invoiceId;
      final cust =
          (invoiceDoc.data()?['customerName'] as String?)?.trim() ?? '';
      final hasCust = cust.isNotEmpty;

      final actionTitle = hasCust
          ? 'إلغاء فاتورة مبيعات للعميل: $cust'
          : 'إلغاء فاتورة مبيعات (#$refNum)';

      sl<ActivityLoggerService>().appendToBatch(
        batch,
        ownerUid: uid,
        actionCategory: 'invoices',
        actionType: 'void_invoice',
        actionTitle: actionTitle,
        details:
            'إلغاء الفاتورة رقم $refNum بالكامل بقيمة $totalFormatted ${AppStrings.currencyEgp.tr()}${hasCust ? " للعميل $cust" : ""} وإلغاء قيود الديون المرتبطة بها',
        amount: totalAmount,
        extraData: {
          'invoiceId': invoiceId,
          'referenceNumber': refNum,
          'customerName': cust,
          'totalAmount': totalAmount,
        },
      );
    }

    await batch.commit();
  }

  @override
  Future<void> convertQuotationToInvoice(
    InvoiceModel invoice, {
    DateTime? dueDate,
  }) async {
    final ref = firestore
        .collection('users/${invoice.uid}/invoices')
        .doc(invoice.id);

    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    _normalizeDates(data);
    data['id'] = snap.id;
    final existing = InvoiceModel.fromMap(data);

    if (existing.status != InvoiceStatus.quotation) return;

    final items = invoice.items
        .map((i) => InvoiceItemModel.fromEntity(i).toMap())
        .toList();
    final effectiveDueDate = dueDate ?? invoice.dueDate;

    final conversionDate = DateTime.now();
    final conversionTimestamp = Timestamp.fromDate(conversionDate);

    await ref.update({
      'status': InvoiceStatus.pending.name,
      'createdAt': conversionTimestamp,
      'convertedAt': conversionTimestamp,
      'customerName': invoice.customerName,
      'customerPhone': invoice.customerPhone,
      'ledgerNumber': invoice.ledgerNumber,
      'notes': invoice.notes,
      'items': items,
      'totalAmount': invoice.totalAmount,
      'discountAmount': invoice.discountAmount,
      if (invoice.taxRate != null) 'taxRate': invoice.taxRate,
      'dueDate': effectiveDueDate != null
          ? Timestamp.fromDate(effectiveDueDate)
          : null,
      'lastUpdatedAt': conversionTimestamp,
    });

    if (sl.isRegistered<ActivityLoggerService>()) {
      final refNum =
          (invoice.referenceNumber != null &&
              invoice.referenceNumber!.isNotEmpty)
          ? invoice.referenceNumber!
          : invoice.id;
      final hasSpecificCustomer =
          invoice.customerName != null &&
          invoice.customerName!.trim().isNotEmpty;
      final cust = hasSpecificCustomer
          ? invoice.customerName!.trim()
          : 'عميل عام';
      final totalFormatted = invoice.totalAmount.toSmartAmount();

      sl<ActivityLoggerService>().logStandalone(
        ownerUid: invoice.uid,
        actionCategory: 'invoices',
        actionType: 'convert_quotation',
        actionTitle: 'تحويل عرض سعر إلى فاتورة (#$refNum)',
        details:
            'تحويل عرض السعر رقم $refNum للعميل ($cust) بقيمة $totalFormatted ${AppStrings.currencyEgp.tr()} إلى فاتورة مبيعات فعلية',
        amount: invoice.totalAmount,
        extraData: {
          'invoiceId': invoice.id,
          'referenceNumber': invoice.referenceNumber,
          'customerName': invoice.customerName,
          'totalAmount': invoice.totalAmount,
          'itemCount': invoice.items.length,
          'convertedAt': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      );
    }
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
    if (data['dueDate'] is Timestamp) {
      data['dueDate'] = (data['dueDate'] as Timestamp)
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
  if (map['dueDate'] is String && map['dueDate'] != null) {
    map['dueDate'] = Timestamp.fromDate(
      DateTime.parse(map['dueDate'] as String),
    );
  }
  map['syncedAt'] = FieldValue.serverTimestamp();
  return map;
}

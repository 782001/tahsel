import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_history_entity.dart';

/// Compares two [InvoiceEntity] snapshots and returns a list of
/// [InvoiceHistoryEntity] records describing every meaningful change.
///
/// This is the ONLY place that decides what constitutes a change worth auditing.
/// Business logic belongs here — not in Widgets or Cubits.
class InvoiceHistoryDiff {
  InvoiceHistoryDiff._();

  /// Generates a list of audit entries from [before] → [after].
  /// Returns an empty list if nothing has changed.
  static List<InvoiceHistoryEntity> diff({
    required InvoiceEntity before,
    required InvoiceEntity after,
    required String uid,
  }) {
    final entries = <InvoiceHistoryEntity>[];
    final now = DateTime.now();
    int seq = 0; // sub-ms counter to ensure unique IDs in the same batch

    String newId() {
      seq++;
      return 'hist_${now.millisecondsSinceEpoch}_$seq';
    }

    // ── 1. Customer name ──────────────────────────────────────────────────────
    if ((before.customerName ?? '') != (after.customerName ?? '')) {
      entries.add(InvoiceHistoryEntity(
        id: newId(),
        invoiceId: after.id,
        uid: uid,
        changeType: InvoiceHistoryChangeType.customerUpdated,
        timestamp: now,
        oldValue: before.customerName,
        newValue: after.customerName,
      ));
    }

    // ── 2. Notes ──────────────────────────────────────────────────────────────
    if ((before.notes ?? '') != (after.notes ?? '')) {
      entries.add(InvoiceHistoryEntity(
        id: newId(),
        invoiceId: after.id,
        uid: uid,
        changeType: InvoiceHistoryChangeType.notesUpdated,
        timestamp: now,
        oldValue: before.notes,
        newValue: after.notes,
      ));
    }

    // ── 3. Items — detect removed, added, and mutated ─────────────────────────
    final oldById = {for (final i in before.items) i.id: i};
    final newById = {for (final i in after.items) i.id: i};

    // Items present in old but missing in new → REMOVED
    for (final oldItem in before.items) {
      if (!newById.containsKey(oldItem.id)) {
        entries.add(InvoiceHistoryEntity(
          id: newId(),
          invoiceId: after.id,
          uid: uid,
          changeType: InvoiceHistoryChangeType.itemRemoved,
          timestamp: now,
          fieldLabel: oldItem.description,
          metadata: {
            'quantity': oldItem.quantity,
            'unitPrice': oldItem.unitPrice,
            'subtotal': oldItem.subtotal,
          },
        ));
      }
    }

    // Items present in new but missing in old → ADDED
    for (final newItem in after.items) {
      if (!oldById.containsKey(newItem.id)) {
        entries.add(InvoiceHistoryEntity(
          id: newId(),
          invoiceId: after.id,
          uid: uid,
          changeType: InvoiceHistoryChangeType.itemAdded,
          timestamp: now,
          fieldLabel: newItem.description,
          metadata: {
            'quantity': newItem.quantity,
            'unitPrice': newItem.unitPrice,
            'subtotal': newItem.subtotal,
          },
        ));
      }
    }

    // Items present in BOTH → check for mutations
    for (final newItem in after.items) {
      final oldItem = oldById[newItem.id];
      if (oldItem == null) continue;

      // Quantity changed
      if (oldItem.quantity != newItem.quantity) {
        entries.add(InvoiceHistoryEntity(
          id: newId(),
          invoiceId: after.id,
          uid: uid,
          changeType: InvoiceHistoryChangeType.quantityUpdated,
          timestamp: now,
          fieldLabel: newItem.description,
          oldValue: oldItem.quantity.toStringAsFixed(
            oldItem.quantity % 1 == 0 ? 0 : 2,
          ),
          newValue: newItem.quantity.toStringAsFixed(
            newItem.quantity % 1 == 0 ? 0 : 2,
          ),
        ));
      }

      // Unit price changed
      if (oldItem.unitPrice != newItem.unitPrice) {
        entries.add(InvoiceHistoryEntity(
          id: newId(),
          invoiceId: after.id,
          uid: uid,
          changeType: InvoiceHistoryChangeType.priceUpdated,
          timestamp: now,
          fieldLabel: newItem.description,
          oldValue: oldItem.unitPrice.toStringAsFixed(2),
          newValue: newItem.unitPrice.toStringAsFixed(2),
        ));
      }

      // Discount changed
      if (oldItem.discountRate != newItem.discountRate) {
        final oldPct = (oldItem.discountRate * 100).toStringAsFixed(
          oldItem.discountRate % 1 == 0 ? 0 : 1,
        );
        final newPct = (newItem.discountRate * 100).toStringAsFixed(
          newItem.discountRate % 1 == 0 ? 0 : 1,
        );
        entries.add(InvoiceHistoryEntity(
          id: newId(),
          invoiceId: after.id,
          uid: uid,
          changeType: InvoiceHistoryChangeType.discountUpdated,
          timestamp: now,
          fieldLabel: newItem.description,
          oldValue: '$oldPct%',
          newValue: '$newPct%',
        ));
      }
    }

    // ── 4. Grand total change ─────────────────────────────────────────────────
    // Record a single monetary summary entry whenever the total changes.
    // This makes the audit log immediately readable without summing per-item
    // diffs. (Uses a small tolerance to ignore floating-point noise.)
    final oldTotal = before.totalAmount;
    final newTotal = after.totalAmount;
    if ((oldTotal - newTotal).abs() > 0.001) {
      entries.add(InvoiceHistoryEntity(
        id: newId(),
        invoiceId: after.id,
        uid: uid,
        changeType: InvoiceHistoryChangeType.totalUpdated,
        timestamp: now,
        oldValue: oldTotal.toStringAsFixed(2),
        newValue: newTotal.toStringAsFixed(2),
      ));
    }

    return entries;
  }
}

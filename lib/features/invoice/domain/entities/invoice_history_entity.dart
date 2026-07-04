import 'package:equatable/equatable.dart';

/// The type of change captured in an audit record.
enum InvoiceHistoryChangeType {
  itemAdded,
  itemRemoved,
  quantityUpdated,
  priceUpdated,
  customerUpdated,
  notesUpdated,
  discountUpdated,
}

/// A single, immutable audit log entry for an invoice edit.
///
/// Every field that changed generates its own [InvoiceHistoryEntity].
/// Records are append-only — they are NEVER modified after creation.
class InvoiceHistoryEntity extends Equatable {
  final String id;
  final String invoiceId;
  final String uid;
  final InvoiceHistoryChangeType changeType;
  final DateTime timestamp;

  /// Human-readable label for the affected item/field (e.g. product name).
  final String? fieldLabel;

  /// Old value as a string (for display purposes).
  final String? oldValue;

  /// New value as a string (for display purposes).
  final String? newValue;

  /// Additional context — e.g. quantity, unit price, subtotal.
  final Map<String, dynamic> metadata;

  const InvoiceHistoryEntity({
    required this.id,
    required this.invoiceId,
    required this.uid,
    required this.changeType,
    required this.timestamp,
    this.fieldLabel,
    this.oldValue,
    this.newValue,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
        id,
        invoiceId,
        uid,
        changeType,
        timestamp,
        fieldLabel,
        oldValue,
        newValue,
        metadata,
      ];
}

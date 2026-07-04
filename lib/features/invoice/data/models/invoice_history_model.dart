import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/invoice_history_entity.dart';

class InvoiceHistoryModel extends InvoiceHistoryEntity {
  const InvoiceHistoryModel({
    required super.id,
    required super.invoiceId,
    required super.uid,
    required super.changeType,
    required super.timestamp,
    super.fieldLabel,
    super.oldValue,
    super.newValue,
    super.metadata,
  });

  factory InvoiceHistoryModel.fromEntity(InvoiceHistoryEntity e) =>
      InvoiceHistoryModel(
        id: e.id,
        invoiceId: e.invoiceId,
        uid: e.uid,
        changeType: e.changeType,
        timestamp: e.timestamp,
        fieldLabel: e.fieldLabel,
        oldValue: e.oldValue,
        newValue: e.newValue,
        metadata: e.metadata,
      );

  factory InvoiceHistoryModel.fromMap(Map<String, dynamic> map) {
    // Handle Firestore Timestamp or ISO8601 string
    DateTime timestamp;
    final raw = map['timestamp'];
    if (raw is Timestamp) {
      timestamp = raw.toDate();
    } else {
      timestamp = DateTime.parse(raw as String);
    }

    return InvoiceHistoryModel(
      id: map['id'] as String,
      invoiceId: map['invoiceId'] as String,
      uid: map['uid'] as String,
      changeType: InvoiceHistoryChangeType.values.firstWhere(
        (t) => t.name == (map['changeType'] as String),
        orElse: () => InvoiceHistoryChangeType.notesUpdated,
      ),
      timestamp: timestamp,
      fieldLabel: map['fieldLabel'] as String?,
      oldValue: map['oldValue'] as String?,
      newValue: map['newValue'] as String?,
      metadata: Map<String, dynamic>.from(
        (map['metadata'] as Map<dynamic, dynamic>? ?? {}),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoiceId': invoiceId,
        'uid': uid,
        'changeType': changeType.name,
        'timestamp': timestamp.toIso8601String(),
        'fieldLabel': fieldLabel,
        'oldValue': oldValue,
        'newValue': newValue,
        'metadata': metadata,
      };

  /// Returns a Firestore-ready map with [Timestamp] instead of ISO strings.
  Map<String, dynamic> toFirestoreMap() {
    final map = toMap();
    map['timestamp'] = Timestamp.fromDate(timestamp);
    map['syncedAt'] = FieldValue.serverTimestamp();
    return map;
  }
}

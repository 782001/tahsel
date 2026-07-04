import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/invoice_history_entity.dart';
import '../models/invoice_history_model.dart';

abstract class InvoiceHistoryRemoteDataSource {
  /// Appends all [entries] to the Firestore history subcollection in one batch.
  Future<void> addHistoryEntries({
    required String uid,
    required String invoiceId,
    required List<InvoiceHistoryModel> entries,
  });

  /// Returns all history docs for the invoice, ordered newest-first.
  Future<List<InvoiceHistoryEntity>> getHistory({
    required String uid,
    required String invoiceId,
  });
}

class InvoiceHistoryRemoteDataSourceImpl
    implements InvoiceHistoryRemoteDataSource {
  final FirebaseFirestore firestore;

  const InvoiceHistoryRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> _historyCol(
    String uid,
    String invoiceId,
  ) =>
      firestore
          .collection('users')
          .doc(uid)
          .collection('invoices')
          .doc(invoiceId)
          .collection('history');

  @override
  Future<void> addHistoryEntries({
    required String uid,
    required String invoiceId,
    required List<InvoiceHistoryModel> entries,
  }) async {
    if (entries.isEmpty) return;

    // Firestore batch writes are atomic (max 500 docs — history per edit will
    // never exceed ~10 entries so this is perfectly safe).
    final batch = firestore.batch();
    final col = _historyCol(uid, invoiceId);

    for (final entry in entries) {
      final ref = col.doc(entry.id);
      batch.set(ref, entry.toFirestoreMap());
    }

    await batch.commit();
  }

  @override
  Future<List<InvoiceHistoryEntity>> getHistory({
    required String uid,
    required String invoiceId,
  }) async {
    final snap = await _historyCol(uid, invoiceId)
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return InvoiceHistoryModel.fromMap(data);
    }).toList();
  }
}

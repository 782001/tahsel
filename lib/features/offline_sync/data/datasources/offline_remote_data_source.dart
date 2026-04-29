import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'dart:convert';
import '../models/offline_record.dart';

abstract class OfflineRemoteDataSource {
  Future<void> syncRecord(OfflineRecord record);
}

class OfflineRemoteDataSourceImpl implements OfflineRemoteDataSource {
  final FirebaseFirestore firestore;

  OfflineRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> syncRecord(OfflineRecord record) async {
    try {
      AppLogger.printMessage("[OfflineSync] STARTING REAL SYNC for record: ${record.id} (Type: ${record.type})");
      
      final payload = jsonDecode(record.payloadJson) as Map<String, dynamic>;

      if (record.type == 'my_debt_add') {
        await _syncMyDebtAdd(record, payload);
      } else {
        // Simple collection sync (e.g., expenses)
        await _syncSimpleRecord(record, payload);
      }
      
      AppLogger.printMessage("[OfflineSync] REAL SYNC SUCCESS for record: ${record.id}");
    } catch (e) {
      AppLogger.printMessage("[OfflineSync] REAL SYNC FAILED for record: ${record.id} - Error: $e");
      rethrow;
    }
  }

  Future<void> _syncMyDebtAdd(OfflineRecord record, Map<String, dynamic> payload) async {
    final uid = payload['uid'] as String;
    final personName = payload['personName'] as String;
    final operationId = payload['operationId'] as String;
    final totalAmount = (payload['totalAmount'] as num).toDouble();
    final paidAmount = (payload['paidAmount'] as num).toDouble();
    final remainingAmount = (payload['remainingAmount'] as num).toDouble();
    final timestampStr = payload['timestamp'] as String;
    final timestamp = Timestamp.fromDate(DateTime.parse(timestampStr));

    final userRef = firestore.collection('users').doc(uid);
    final debtRef = userRef.collection('my_debt_items').doc(record.id); // Use Hive ID for idempotency
    
    // 0. CHECK IF ALREADY SYNCED (To prevent duplicate FieldValue.increment)
    final existingDoc = await debtRef.get();
    if (existingDoc.exists) {
      AppLogger.printMessage("[OfflineSync] Record ${record.id} already exists in Firestore. Skipping sync to prevent duplicate increments.");
      return; // Already synced, repository will handle Hive deletion
    }

    final opRef = userRef.collection('my_debt_operations').doc(operationId);
    final personRef = userRef.collection('my_debt_persons').doc(personName);

    AppLogger.printMessage("[OfflineSync] Preparing Batch for MyDebtAdd - Person: $personName, Amount: $totalAmount");

    final batch = firestore.batch();

    // 1. Add to debts collection
    // We update the timestamp to real Timestamp object
    payload['timestamp'] = timestamp;
    payload['lastUpdatedAt'] = FieldValue.serverTimestamp();
    payload['syncedAt'] = FieldValue.serverTimestamp();
    batch.set(debtRef, payload);

    // 2. Add to operations collection
    batch.set(opRef, {
      'uid': uid,
      'type': payload['operationType'] ?? 'debt',
      'personName': personName,
      'details': payload['details'],
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingDebt': remainingAmount,
      'timestamp': timestamp,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
    });

    // 3. Add initial transaction record
    final initialPaymentRef = debtRef.collection('payments').doc('${record.id}_initial');
    batch.set(initialPaymentRef, {
      'debtId': debtRef.id,
      'amountPaid': totalAmount,
      'remainingAmount': totalAmount,
      'createdAt': timestamp,
      'type': 'debtAdded',
    });

    // 4. Add initial payment if any
    if (paidAmount > 0) {
      final actualPaymentRef = debtRef.collection('payments').doc('${record.id}_payment');
      batch.set(actualPaymentRef, {
        'debtId': debtRef.id,
        'amountPaid': paidAmount,
        'remainingAmount': remainingAmount,
        'createdAt': Timestamp.fromDate(DateTime.parse(timestampStr).add(const Duration(milliseconds: 1))),
        'type': remainingAmount <= 0 ? 'full' : 'partial',
      });
    }

    // 5. Update person doc with totals
    batch.set(personRef, {
      'name': personName,
      'lastUsedAt': timestamp,
      'totalDebtAmount': FieldValue.increment(totalAmount),
      'totalRemainingDebt': FieldValue.increment(remainingAmount),
      'totalTransactions': FieldValue.increment(1),
    }, SetOptions(merge: true));

    AppLogger.printMessage("[OfflineSync] Committing Batch to Firestore...");
    await batch.commit();
    AppLogger.printMessage("[OfflineSync] Batch Committed Successfully.");
  }

  Future<void> _syncSimpleRecord(OfflineRecord record, Map<String, dynamic> payload) async {
    final collectionRef = firestore.collection(record.collectionName);

    // Convert string dates back to Timestamps
    if (payload['createdAt'] is String) {
      payload['createdAt'] = Timestamp.fromDate(DateTime.parse(payload['createdAt']));
    }
    if (payload['timestamp'] is String) {
      payload['timestamp'] = Timestamp.fromDate(DateTime.parse(payload['timestamp']));
    }

    payload['syncedAt'] = FieldValue.serverTimestamp();

    AppLogger.printMessage("[OfflineSync] Sending simple record to: ${record.collectionName}");
    await collectionRef.doc(record.id).set(payload, SetOptions(merge: true));
  }
}

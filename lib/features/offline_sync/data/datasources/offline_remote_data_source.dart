import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/summary_helper.dart';

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
      AppLogger.printMessage(
        "[OfflineSync] STARTING REAL SYNC for record: ${record.id} (Type: ${record.type})",
      );

      final payload = jsonDecode(record.payloadJson) as Map<String, dynamic>;

      if (record.type == 'my_debt_add') {
        await _syncMyDebtAdd(record, payload);
      } else if (record.type == 'debt_add') {
        await _syncDebtAdd(record, payload);
      } else {
        // Simple collection sync (e.g., expenses, operations)
        await _syncSimpleRecord(record, payload);
      }

      AppLogger.printMessage(
        "[OfflineSync] REAL SYNC SUCCESS for record: ${record.id}",
      );
    } catch (e) {
      AppLogger.printMessage(
        "[OfflineSync] REAL SYNC FAILED for record: ${record.id} - Error: $e",
      );
      rethrow;
    }
  }

  Future<void> _syncMyDebtAdd(
    OfflineRecord record,
    Map<String, dynamic> payload,
  ) async {
    final uid = payload['uid'] as String;
    final personName = payload['personName'] as String;
    final operationId = payload['operationId'] as String;
    final totalAmount = (payload['totalAmount'] as num).toDouble();
    final paidAmount = (payload['paidAmount'] as num).toDouble();
    final remainingAmount = (payload['remainingAmount'] as num).toDouble();
    final timestampStr = payload['timestamp'] as String;
    final timestamp = Timestamp.fromDate(DateTime.parse(timestampStr));

    final userRef = firestore.collection('users').doc(uid);
    final debtRef = userRef
        .collection('my_debt_items')
        .doc(record.id); // Use Hive ID for idempotency

    // 0. CHECK IF ALREADY SYNCED
    final existingDoc = await debtRef.get();
    if (existingDoc.exists) {
      AppLogger.printMessage(
        "[OfflineSync] Record ${record.id} already exists. Skipping.",
      );
      return;
    }

    final opRef = userRef.collection('my_debt_operations').doc(operationId);
    final personRef = userRef.collection('my_debt_persons').doc(personName);

    final batch = firestore.batch();

    payload['timestamp'] = timestamp;
    payload['lastUpdatedAt'] = FieldValue.serverTimestamp();
    payload['syncedAt'] = FieldValue.serverTimestamp();
    batch.set(debtRef, payload);

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

    final initialPaymentRef = debtRef
        .collection('payments')
        .doc('${record.id}_initial');
    batch.set(initialPaymentRef, {
      'debtId': debtRef.id,
      'amountPaid': totalAmount,
      'remainingAmount': totalAmount,
      'createdAt': timestamp,
      'type': 'debtAdded',
    });

    if (paidAmount > 0) {
      final actualPaymentRef = debtRef
          .collection('payments')
          .doc('${record.id}_payment');
      batch.set(actualPaymentRef, {
        'debtId': debtRef.id,
        'amountPaid': paidAmount,
        'remainingAmount': remainingAmount,
        'createdAt': Timestamp.fromDate(
          DateTime.parse(timestampStr).add(const Duration(milliseconds: 1)),
        ),
        'type': remainingAmount <= 0 ? 'full' : 'partial',
      });
    }

    batch.set(personRef, {
      'name': personName,
      'lastUsedAt': timestamp,
      'totalDebtAmount': FieldValue.increment(totalAmount),
      'totalRemainingDebt': FieldValue.increment(remainingAmount),
      'totalTransactions': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> _syncDebtAdd(
    OfflineRecord record,
    Map<String, dynamic> payload,
  ) async {
    final uid = payload['uid'] as String;
    final customerName = payload['customerName'] as String;
    final operationId = payload['operationId'] as String;
    final totalAmount = (payload['totalAmount'] as num).toDouble();
    final paidAmount = (payload['paidAmount'] as num).toDouble();
    final remainingAmount = (payload['remainingAmount'] as num).toDouble();
    final timestampStr = payload['timestamp'] as String;
    final timestampDate = DateTime.parse(timestampStr);
    final timestamp = Timestamp.fromDate(timestampDate);

    final userRef = firestore.collection('users').doc(uid);
    final debtRef = userRef.collection('debts').doc(operationId);

    // 0. IDEMPOTENCY CHECK
    final existingDoc = await debtRef.get();
    if (existingDoc.exists) {
      AppLogger.printMessage(
        "[OfflineSync] Debt record $operationId already exists. Skipping.",
      );
      return;
    }

    final opRef = userRef.collection('operations').doc(operationId);
    final batch = firestore.batch();

    payload['timestamp'] = timestamp;
    payload['lastUpdatedAt'] = FieldValue.serverTimestamp();
    payload['syncedAt'] = FieldValue.serverTimestamp();
    batch.set(debtRef, payload);

    batch.set(
      opRef,
      {
        'uid': uid,
        'type': payload['operationType'] ?? 'debt',
        'customerName': customerName,
        'productName': payload['productOrSessionDetails'],
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingDebt': remainingAmount,
        'timestamp': timestamp,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'syncedAt': FieldValue.serverTimestamp(),
        'ledgerNumber': payload['ledgerNumber'],
      },
      SetOptions(merge: true),
    );

    final initialPaymentRef = debtRef
        .collection('payments')
        .doc('${operationId}_initial');
    batch.set(initialPaymentRef, {
      'debtId': operationId,
      'amountPaid': totalAmount,
      'remainingAmount': totalAmount,
      'createdAt': timestamp,
      'type': 'debtAdded',
    });

    if (paidAmount > 0) {
      final actualPaymentRef = debtRef
          .collection('payments')
          .doc('${operationId}_payment');
      batch.set(actualPaymentRef, {
        'debtId': operationId,
        'amountPaid': paidAmount,
        'remainingAmount': remainingAmount,
        'createdAt': Timestamp.fromDate(
          timestampDate.add(const Duration(milliseconds: 1)),
        ),
        'type': remainingAmount <= 0 ? 'full' : 'partial',
      });
    }

    // 5. Update Summaries
    final summaryKeys = SummaryHelper.getSummaryKeys(timestampDate);
    for (final key in summaryKeys) {
      final summaryRef = userRef.collection('summaries').doc(key);
      batch.set(
        summaryRef,
        {
          'totalDebts': FieldValue.increment(remainingAmount),
          'unpaidDebts': FieldValue.increment(remainingAmount),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> _syncSimpleRecord(
    OfflineRecord record,
    Map<String, dynamic> payload,
  ) async {
    final collectionPath = record.collectionName;
    final docId = record.id;
    final docRef = firestore.doc('$collectionPath/$docId');

    // 0. IDEMPOTENCY CHECK
    final existingDoc = await docRef.get();
    if (existingDoc.exists) {
      AppLogger.printMessage("[OfflineSync] Simple record $docId already exists. Skipping.");
      return;
    }

    // Parse Dates
    DateTime? timestampDate;
    if (payload['createdAt'] is String) {
      timestampDate = DateTime.parse(payload['createdAt']);
      payload['createdAt'] = Timestamp.fromDate(timestampDate);
    }
    if (payload['timestamp'] is String) {
      timestampDate = DateTime.parse(payload['timestamp']);
      payload['timestamp'] = Timestamp.fromDate(timestampDate);
    }

    payload['syncedAt'] = FieldValue.serverTimestamp();
    
    final batch = firestore.batch();
    batch.set(docRef, payload, SetOptions(merge: true));

    // Handle Summary Updates for Operations and Expenses
    final uid = payload['uid'] as String?;
    if (uid != null && timestampDate != null) {
      final userRef = firestore.collection('users').doc(uid);
      final summaryKeys = SummaryHelper.getSummaryKeys(timestampDate);

      if (collectionPath.contains('operations')) {
        final totalAmount = (payload['totalAmount'] as num?)?.toDouble() ?? 0;
        final type = (payload['type'] as String?)?.toLowerCase() ?? '';
        final isShop = type == AppStrings.shop.toLowerCase() || type == 'cafe';
        final isPS = type == AppStrings.playStation.toLowerCase() || type == 'playstation';

        for (final key in summaryKeys) {
          batch.set(
            userRef.collection('summaries').doc(key),
            {
              'totalIncome': FieldValue.increment(totalAmount),
              if (isShop) 'cafeIncome': FieldValue.increment(totalAmount),
              if (isPS) 'playstationIncome': FieldValue.increment(totalAmount),
              'transactionCount': FieldValue.increment(1),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      } else if (collectionPath.contains('expenses')) {
        final amount = (payload['amount'] as num?)?.toDouble() ?? 0;
        for (final key in summaryKeys) {
          batch.set(
            userRef.collection('summaries').doc(key),
            {
              'totalExpenses': FieldValue.increment(amount),
              'transactionCount': FieldValue.increment(1),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }
    }

    await batch.commit();
  }
}

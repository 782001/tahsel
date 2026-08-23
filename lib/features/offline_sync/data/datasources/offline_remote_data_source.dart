import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/summary_helper.dart';

import '../models/offline_record.dart';
import 'package:tahsel/features/cashbox/domain/entities/vault_transaction_entity.dart';

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
      } else if (record.type == 'checkout_update') {
        await _syncCheckOutUpdate(record, payload);
      } else if (record.type == 'settle_advances') {
        await _syncSettleAdvances(record, payload);
      } else if (record.type == 'ps_session_start') {
        await _syncPsSessionStart(record, payload);
      } else if (record.type == 'ps_session_end') {
        await _syncPsSessionEnd(record, payload);
      } else {
        // Simple collection sync (e.g., expenses, operations, employees, attendance_checkin, payroll, advance)
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
    try {
      final existingDoc = await debtRef.get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (existingDoc.exists) {
        final data = existingDoc.data();
        if (data != null && data['syncedAt'] != null) {
          AppLogger.printMessage(
            "[OfflineSync] Record ${record.id} already exists. Skipping.",
          );
          return;
        }
      }
    } catch (_) {}

    final opRef = userRef.collection('my_debt_operations').doc(operationId);
    final personRef = userRef.collection('my_debt_persons').doc(personName);

    // Get person first to check if firstDate needs to be set/updated
    final personSnap = await personRef.get();
    final bool firstDateIsNull = !personSnap.exists || personSnap.data()?['firstDate'] == null;

    // Update firstDate if it's null OR if the new debt's date is earlier
    bool shouldUpdateFirstDate = firstDateIsNull;
    if (!shouldUpdateFirstDate && personSnap.exists) {
      final existingFirstDate = (personSnap.data()!['firstDate'] as Timestamp).toDate();
      shouldUpdateFirstDate = timestamp.toDate().isBefore(existingFirstDate);
    }

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

      if (AppStrings.isVaultEnabled()) {
        final bool isPurchase = (record.id.startsWith('debt_pur_') || operationId.startsWith('pur_'));
        final vaultTxRef = userRef.collection('vault_transactions').doc('vault_tx_mydebt_${record.id}_payment');
        final vaultSummaryRef = userRef.collection('vault').doc('summary');

        batch.set(vaultTxRef, {
          'id': 'vault_tx_mydebt_${record.id}_payment',
          'uid': uid,
          'amount': paidAmount,
          'direction': 'out',
          'source': isPurchase
              ? VaultTransactionSource.inventory.name
              : VaultTransactionSource.myDebt.name,
          'type': isPurchase ? 'purchase_payment' : 'debt_payment',
          'description': isPurchase
              ? 'سداد دفعة شراء (مزامنة): $personName'
              : 'سداد دين (مزامنة): $personName',
          'relatedEntityId': '${record.id}_payment',
          'relatedOperationId': record.id,
          'createdAt': Timestamp.fromDate(
            DateTime.parse(timestampStr).add(const Duration(milliseconds: 1)),
          ),
        });

        batch.set(
          vaultSummaryRef,
          {
            'currentBalance': FieldValue.increment(-paidAmount),
            'totalOut': FieldValue.increment(paidAmount),
            'transactionCount': FieldValue.increment(1),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    final Map<String, dynamic> personUpdate = {
      'name': personName,
      'lastUsedAt': timestamp,
      'totalDebtAmount': FieldValue.increment(totalAmount),
      'totalRemainingDebt': FieldValue.increment(remainingAmount),
      'totalTransactions': FieldValue.increment(1),
    };

    if (shouldUpdateFirstDate) {
      personUpdate['firstDate'] = timestamp;
    }

    batch.set(personRef, personUpdate, SetOptions(merge: true));

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
    try {
      final existingDoc = await debtRef.get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (existingDoc.exists) {
        final data = existingDoc.data();
        if (data != null && data['syncedAt'] != null) {
          AppLogger.printMessage(
            "[OfflineSync] Debt record $operationId already exists. Skipping.",
          );
          return;
        }
      }
    } catch (_) {}

    final opRef = userRef.collection('operations').doc(operationId);

    // Fetch customer doc to check/update firstDate
    final customersCollection = userRef.collection('customers');
    final customerSnapshot = await customersCollection
        .where('name', isEqualTo: customerName.trim())
        .limit(1)
        .get();

    bool shouldUpdateFirstDate = false;
    DocumentReference? customerRef;

    if (customerSnapshot.docs.isNotEmpty) {
      customerRef = customerSnapshot.docs.first.reference;
      final data = customerSnapshot.docs.first.data();
      final existingFirstDate = data['firstDate'] != null
          ? (data['firstDate'] as Timestamp).toDate()
          : null;
      if (existingFirstDate == null) {
        shouldUpdateFirstDate = true;
      } else if (timestampDate.isBefore(existingFirstDate)) {
        shouldUpdateFirstDate = true;
      }
    }

    final batch = firestore.batch();

    payload['timestamp'] = timestamp;
    payload['lastUpdatedAt'] = FieldValue.serverTimestamp();
    payload['syncedAt'] = FieldValue.serverTimestamp();
    batch.set(debtRef, payload);

    if (shouldUpdateFirstDate && customerRef != null) {
      batch.update(customerRef, {
        'firstDate': timestamp,
      });
    }

    batch.set(opRef, {
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
    }, SetOptions(merge: true));

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

      if (AppStrings.isVaultEnabled()) {
        final vaultTxRef = userRef.collection('vault_transactions').doc('vault_tx_cust_${operationId}_payment');
        final vaultSummaryRef = userRef.collection('vault').doc('summary');

        batch.set(vaultTxRef, {
          'id': 'vault_tx_cust_${operationId}_payment',
          'uid': uid,
          'amount': paidAmount,
          'direction': 'in',
          'source': VaultTransactionSource.customerDebt.name,
          'type': remainingAmount <= 0 ? 'full_settlement' : 'partial_payment',
          'description': 'تحصيل دفعة من العميل (مزامنة): $customerName',
          'relatedEntityId': '${operationId}_payment',
          'relatedOperationId': operationId,
          'createdAt': Timestamp.fromDate(
            timestampDate.add(const Duration(milliseconds: 1)),
          ),
        });

        batch.set(
          vaultSummaryRef,
          {
            'currentBalance': FieldValue.increment(paidAmount),
            'totalIn': FieldValue.increment(paidAmount),
            'transactionCount': FieldValue.increment(1),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    // 5. Update Summaries
    final summaryKeys = SummaryHelper.getSummaryKeys(timestampDate);
    for (final key in summaryKeys) {
      final summaryRef = userRef.collection('summaries').doc(key);
      batch.set(summaryRef, {
        'totalDebts': FieldValue.increment(remainingAmount),
        'unpaidDebts': FieldValue.increment(remainingAmount),
        if (paidAmount > 0) 'totalCollected': FieldValue.increment(paidAmount),
        if (remainingAmount > 0) 'debtCustomersCount': FieldValue.increment(1),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> _syncCheckOutUpdate(
    OfflineRecord record,
    Map<String, dynamic> payload,
  ) async {
    final uid = payload['uid'] as String;
    final attendanceId = payload['attendanceId'] as String;
    final checkOutStr = payload['checkOut'] as String;
    final checkOut = Timestamp.fromDate(DateTime.parse(checkOutStr));
    final overtimeHours = (payload['overtimeHours'] as num).toDouble();
    final deductionHours = (payload['deductionHours'] as num).toDouble();
    final lateMinutes = (payload['lateMinutes'] as num).toInt();
    final status = payload['status'] as String;
    final notes = payload['notes'] as String;

    final docRef = firestore
        .collection('users')
        .doc(uid)
        .collection('attendances')
        .doc(attendanceId);

    await docRef.update({
      'checkOut': checkOut,
      'overtimeHours': overtimeHours,
      'deductionHours': deductionHours,
      'lateMinutes': lateMinutes,
      'status': status,
      'notes': notes,
    });
  }

  Future<void> _syncSimpleRecord(
    OfflineRecord record,
    Map<String, dynamic> payload,
  ) async {
    final collectionPath = record.collectionName;
    final docId = record.id;
    final docRef = firestore.doc('$collectionPath/$docId');

    // 0. IDEMPOTENCY CHECK
    try {
      final existingDoc = await docRef.get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (existingDoc.exists) {
        final data = existingDoc.data();
        if (data != null && data['syncedAt'] != null) {
          AppLogger.printMessage(
            "[OfflineSync] Simple record $docId already exists. Skipping.",
          );
          return;
        }
      }
    } catch (_) {
      // If reading fails (e.g. offline/network fluctuation), continue with the write batch
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
    if (payload['checkIn'] is String) {
      timestampDate = DateTime.parse(payload['checkIn']);
      payload['checkIn'] = Timestamp.fromDate(timestampDate);
    }
    if (payload['checkOut'] is String) {
      final checkOutDate = DateTime.parse(payload['checkOut']);
      payload['checkOut'] = Timestamp.fromDate(checkOutDate);
    }
    if (payload['paymentDate'] is String) {
      timestampDate = DateTime.parse(payload['paymentDate']);
      payload['paymentDate'] = Timestamp.fromDate(timestampDate);
    }
    if (payload['periodStart'] is String) {
      final periodStartDate = DateTime.parse(payload['periodStart']);
      payload['periodStart'] = Timestamp.fromDate(periodStartDate);
    }
    if (payload['periodEnd'] is String) {
      final periodEndDate = DateTime.parse(payload['periodEnd']);
      payload['periodEnd'] = Timestamp.fromDate(periodEndDate);
    }
    if (payload['date'] is String) {
      timestampDate = DateTime.parse(payload['date']);
      payload['date'] = Timestamp.fromDate(timestampDate);
    }
    if (payload['lastUpdatedAt'] is String) {
      payload['lastUpdatedAt'] = Timestamp.fromDate(DateTime.parse(payload['lastUpdatedAt']));
    }

    payload['syncedAt'] = FieldValue.serverTimestamp();

    final batch = firestore.batch();
    batch.set(docRef, payload, SetOptions(merge: true));

    // Handle Summary Updates for Operations, Expenses, Employees, and Payroll
    final uid = payload['uid'] as String?;
    if (uid != null && timestampDate != null) {
      final userRef = firestore.collection('users').doc(uid);
      final summaryKeys = SummaryHelper.getSummaryKeys(timestampDate);

      if (collectionPath.contains('operations')) {
        final totalAmount = (payload['totalAmount'] as num?)?.toDouble() ?? 0;
        final type = (payload['type'] as String?)?.toLowerCase() ?? '';
        final isShop = type == AppStrings.shop.toLowerCase() || type == 'cafe';
        final isPS =
            type == AppStrings.playStation.toLowerCase() ||
            type == 'playstation';

        for (final key in summaryKeys) {
          batch.set(userRef.collection('summaries').doc(key), {
            'totalIncome': FieldValue.increment(totalAmount),
            if (isShop) 'cafeIncome': FieldValue.increment(totalAmount),
            if (isPS) 'playstationIncome': FieldValue.increment(totalAmount),
            'transactionCount': FieldValue.increment(1),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } else if (collectionPath.contains('expenses')) {
        final amount = (payload['amount'] as num?)?.toDouble() ?? 0;
        for (final key in summaryKeys) {
          batch.set(userRef.collection('summaries').doc(key), {
            'totalExpenses': FieldValue.increment(amount),
            'transactionCount': FieldValue.increment(1),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        final bool isInternalSync =
            docId.startsWith('exp_pur_') || docId.startsWith('exp_pay_');

        if (!isInternalSync && AppStrings.isVaultEnabled() && amount > 0) {
          final vaultTxRef = userRef
              .collection('vault_transactions')
              .doc('vault_tx_$docId');
          final vaultSummaryRef = userRef.collection('vault').doc('summary');

          VaultTransactionSource vSource = VaultTransactionSource.expense;
          String vType = 'manual_expense';
          if (docId.startsWith('exp_emp_sal_')) {
            vSource = VaultTransactionSource.employee;
            vType = 'salary_payment';
          } else if (docId.startsWith('exp_emp_adv_')) {
            vSource = VaultTransactionSource.employee;
            vType = 'employee_advance';
          }

          final String description =
              (payload['description'] as String?)?.isNotEmpty == true
                  ? (payload['description'] as String)
                  : ((payload['category'] as String?)?.isNotEmpty == true
                      ? (payload['category'] as String)
                      : 'مصروف');

          batch.set(vaultTxRef, {
            'id': 'vault_tx_$docId',
            'uid': uid,
            'amount': amount,
            'direction': 'out',
            'source': vSource.name,
            'type': vType,
            'description': description,
            'relatedEntityId': docId,
            'createdAt': Timestamp.fromDate(timestampDate),
          });

          batch.set(
            vaultSummaryRef,
            {
              'currentBalance': FieldValue.increment(-amount),
              'totalOut': FieldValue.increment(amount),
              'transactionCount': FieldValue.increment(1),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      } else if (collectionPath.contains('employees')) {
        final allTimeRef = userRef.collection('summaries').doc('all_time');
        batch.set(allTimeRef, {
          'employeeCount': FieldValue.increment(1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (collectionPath.contains('payrolls')) {
        final netSalary = (payload['netSalary'] as num?)?.toDouble() ?? 0;
        final overtimeCompensation =
            (payload['overtimeCompensation'] as num?)?.toDouble() ?? 0;
        final monthKey = payload['monthKey'] as String? ?? '';

        final monthlyRef = userRef
            .collection('summaries')
            .doc('monthly_$monthKey');
        final allTimeRef = userRef.collection('summaries').doc('all_time');

        for (final ref in [monthlyRef, allTimeRef]) {
          batch.set(ref, {
            'totalSalariesPaid': FieldValue.increment(netSalary),
            'totalOvertimePaid': FieldValue.increment(overtimeCompensation),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } else if (collectionPath.contains('advances')) {
        final amount = (payload['amount'] as num?)?.toDouble() ?? 0;
        final date = timestampDate;
        final monthKey = DateFormat('yyyy-MM', 'en').format(date);

        final monthlyRef = userRef
            .collection('summaries')
            .doc('monthly_$monthKey');
        final allTimeRef = userRef.collection('summaries').doc('all_time');

        for (final ref in [monthlyRef, allTimeRef]) {
          batch.set(ref, {
            'totalSalariesPaid': FieldValue.increment(amount),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    }

    await batch.commit();
  }

  Future<void> _syncSettleAdvances(
    OfflineRecord record,
    Map<String, dynamic> payload,
  ) async {
    final uid = payload['uid'] as String;
    final List<String> advanceIds = List<String>.from(
      payload['advanceIds'] ?? [],
    );
    final payrollId = payload['payrollId'] as String;

    if (advanceIds.isEmpty) return;

    final userRef = firestore.collection('users').doc(uid);
    final batch = firestore.batch();

    for (final id in advanceIds) {
      final docRef = userRef.collection('advances').doc(id);
      batch.update(docRef, {'status': 'deducted', 'payrollId': payrollId});
    }

    await batch.commit();
  }

  Future<void> _syncPsSessionStart(
    OfflineRecord record,
    Map<String, dynamic> payload,
  ) async {
    final uid = payload['uid'] as String;
    final docRef = firestore
        .collection('users')
        .doc(uid)
        .collection('ps_sessions')
        .doc(record.id);

    // Idempotency check
    try {
      final docSnapshot = await docRef.get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['syncedAt'] != null) {
          AppLogger.printMessage(
            "[OfflineSync] Session ${record.id} already exists. Skipping.",
          );
          return;
        }
      }
    } catch (_) {}

    // Convert dates in payload from ISO8601 strings to Timestamp for Firestore
    if (payload['startTime'] is String) {
      payload['startTime'] = Timestamp.fromDate(
        DateTime.parse(payload['startTime']),
      );
    }
    if (payload['endTime'] is String) {
      payload['endTime'] = Timestamp.fromDate(
        DateTime.parse(payload['endTime']),
      );
    }
    if (payload['createdAt'] is String) {
      payload['createdAt'] = Timestamp.fromDate(
        DateTime.parse(payload['createdAt']),
      );
    }

    payload['syncedAt'] = FieldValue.serverTimestamp();

    await docRef.set(payload);
  }

  Future<void> _syncPsSessionEnd(
    OfflineRecord record,
    Map<String, dynamic> payload,
  ) async {
    final uid = payload['uid'] as String;
    final sessionId = payload['sessionId'] as String;
    final endTimeStr = payload['endTime'] as String;
    final endTime = DateTime.parse(endTimeStr);
    final totalAmount = (payload['totalAmount'] as num).toDouble();
    final paidAmount = (payload['paidAmount'] as num).toDouble();
    final turnCount = payload['turnCount'] as int?;

    final sessionRef = firestore
        .collection('users')
        .doc(uid)
        .collection('ps_sessions')
        .doc(sessionId);

    // Try Firestore first; if not there (ps_session_start still pending),
    // fall back to the session snapshot embedded inside the end payload.
    final sessionDoc = await sessionRef.get();
    Map<String, dynamic> sessionData;

    if (sessionDoc.exists) {
      sessionData = sessionDoc.data()!;
    } else {
      final snapshot = payload['sessionSnapshot'] as Map<String, dynamic>?;
      if (snapshot == null) {
        throw Exception(
          '[OfflineSync] Session not found and no snapshot available for: $sessionId',
        );
      }

      AppLogger.printMessage(
        '[OfflineSync] Session $sessionId not yet in Firestore – '
        'creating from embedded snapshot before ending it.',
      );

      // Rehydrate ISO8601 date strings to Firestore Timestamps
      final startPayload = Map<String, dynamic>.from(snapshot);
      if (startPayload['startTime'] is String) {
        startPayload['startTime'] = Timestamp.fromDate(
          DateTime.parse(startPayload['startTime']),
        );
      }
      if (startPayload['endTime'] is String) {
        startPayload['endTime'] = Timestamp.fromDate(
          DateTime.parse(startPayload['endTime']),
        );
      }
      if (startPayload['createdAt'] is String) {
        startPayload['createdAt'] = Timestamp.fromDate(
          DateTime.parse(startPayload['createdAt']),
        );
      }
      startPayload['syncedAt'] = FieldValue.serverTimestamp();
      await sessionRef.set(startPayload);
      sessionData = snapshot;
    }

    // Parse startTime (Firestore Timestamp or ISO8601 String)
    final startTimeVal = sessionData['startTime'];
    DateTime startTime;
    if (startTimeVal is Timestamp) {
      startTime = startTimeVal.toDate();
    } else {
      startTime = DateTime.parse(startTimeVal as String);
    }

    final subType = sessionData['subType'] ?? 'time';
    final rate = (sessionData['rate'] ?? 0).toDouble();
    final ledgerNumber = sessionData['ledgerNumber'] as String?;
    final remainingDebt = (totalAmount - paidAmount) > 0
        ? (totalAmount - paidAmount)
        : 0.0;

    final batch = firestore.batch();

    // 1. Mark session as completed
    batch.update(sessionRef, {
      'endTime': Timestamp.fromDate(endTime),
      'status': 'completed',
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingDebt': remainingDebt,
      if (turnCount != null) 'turnCount': turnCount,
    });

    // 2. Create operation record for billing and reporting
    final durationMinutes = endTime.difference(startTime).inMinutes;
    final operationPayload = {
      'uid': uid,
      'type': AppStrings.playStation,
      'subType': subType,
      'customerName': sessionData['customerName'],
      'phoneNumber': sessionData['phoneNumber'],
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingDebt': remainingDebt,
      'timestamp': Timestamp.fromDate(startTime),
      'lastUpdatedAt': Timestamp.fromDate(endTime),
      'durationMinutes': subType == 'time' ? durationMinutes : null,
      'turnCount': turnCount ?? sessionData['turnCount'],
      'rate': rate,
      'ledgerNumber': ledgerNumber,
      'syncedAt': FieldValue.serverTimestamp(),
    };

    final userRef = firestore.collection('users').doc(uid);
    // Use sessionId as the operation doc ID for idempotency on retry
    final operationRef = userRef.collection('operations').doc(sessionId);
    batch.set(operationRef, operationPayload, SetOptions(merge: true));

    // 3. Increment monthly and all-time summaries
    final summaryKeys = SummaryHelper.getSummaryKeys(startTime);
    for (final key in summaryKeys) {
      final summaryRef = userRef.collection('summaries').doc(key);
      batch.set(summaryRef, {
        'totalIncome': FieldValue.increment(totalAmount),
        'playstationIncome': FieldValue.increment(totalAmount),
        'transactionCount': FieldValue.increment(1),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}

// ignore_for_file: avoid_types_as_parameter_names, unused_element

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/firebase_error_handler.dart';
import '../../../../core/usecases/pagination_params.dart';
import '../../../../core/utils/summary_helper.dart';
import '../../domain/entities/payment_entity.dart';
import '../models/debt_model.dart';
import '../models/payment_model.dart';
import '../../domain/entities/monthly_collected_amount.dart';

abstract class DebtRemoteDataSource {
  Future<String> addDebt(DebtModel debt);
  Future<List<DebtModel>> getDebts(String uid, {bool forceRefresh = false});
  Future<List<DebtModel>> getCustomerDebts(
    String uid,
    String customerName, {
    bool forceRefresh = false,
  });
  Future<void> payDebt(DebtModel debt, PaymentModel payment);
  Future<void> payTotalDebt(String uid, String customerName, double amount);
  Future<void> markCustomerAsPaid(String uid, String customerName);
  Future<void> deleteCustomerDebts(String uid, String customerName);
  Future<void> deleteDebtItem(String uid, String debtId);
  Future<void> updatePayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required double newAmount,
    String? note,
  });
  Future<void> deletePayment({
    required String uid,
    required String debtId,
    required String paymentId,
  });
  Stream<List<PaymentModel>> getDebtTransactions(String uid, String debtId);
  Future<List<PaymentModel>> getDebtTransactionsFuture(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });
  Future<List<PaymentModel>> getCustomerAllPayments(
    String uid,
    String customerName,
  );
  Future<List<PaymentModel>> getAllUserPayments(String uid);
  Stream<List<DebtModel>> getDebtsStream(String uid);
  Future<DebtModel?> getDebtById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });

  Future<PaginatedResult<DebtModel>> getDebtsPaginated(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  });

  Future<PaginatedResult<PaymentModel>> getDebtTransactionsPaginated(
    String uid,
    String debtId, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
  });

  Future<PaginatedResult<PaymentModel>> getCustomerAllPaymentsPaginated(
    String uid,
    String customerName, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
  });

  Future<PaginatedResult<PaymentModel>> getAllUserPaymentsPaginated(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
    int? month,
    int? year,
  });

  Future<Map<String, dynamic>> getDebtSummary(String uid);
  Future<List<MonthlyCollectedAmount>> getMonthlyCollectedAmounts(String uid);
}

class DebtRemoteDataSourceImpl implements DebtRemoteDataSource {
  final FirebaseFirestore firestore;

  DebtRemoteDataSourceImpl({required this.firestore});

  @override
  Future<DebtModel?> getDebtById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .doc(debtId)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      if (doc.exists) {
        return DebtModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<List<MonthlyCollectedAmount>> getMonthlyCollectedAmounts(
    String uid,
  ) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('summaries')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'monthly_')
          .where(FieldPath.documentId, isLessThanOrEqualTo: 'monthly_\uf8ff')
          .get();

      final List<Future<MonthlyCollectedAmount?>> futures = snapshot.docs.map((doc) async {
        final data = doc.data();
        final docId = doc.id; // e.g. "monthly_2024-05"
        final parts = docId.split('_');
        if (parts.length < 2) return null;
        final dateParts = parts[1].split('-');
        if (dateParts.length < 2) return null;

        final year = int.tryParse(dateParts[0]) ?? 0;
        final month = int.tryParse(dateParts[1]) ?? 0;
        if (year == 0 || month == 0) return null;

        // Smart Caching with Self-Healing: check if cached totalCollected is available and already healed
        final now = DateTime.now();
        final isCurrentMonth = (now.year == year && now.month == month);
        
        final cachedVal = data.containsKey('totalCollected') && data['totalCollected'] != null
            ? (data['totalCollected'] as num).toDouble()
            : null;
        final isHealed = data['isHealed'] == true;

        double computedSum = 0.0;

        if (cachedVal != null && !isCurrentMonth && isHealed) {
          // For past months that are already healed, rely on the summary cache document directly
          computedSum = cachedVal;
        } else {
          // Perform accurate memory-based aggregation on the server data
          final startOfMonth = DateTime(year, month, 1);
          final endOfMonth = DateTime(
            year,
            month + 1,
            1,
          ).subtract(const Duration(milliseconds: 1));

          final paymentsQuery = firestore
              .collectionGroup('payments')
              .where('uid', isEqualTo: uid)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where(
                'createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
              );

          final snap = await paymentsQuery.get();
          for (var paymentDoc in snap.docs) {
            final type = paymentDoc.data()['type'] as String?;
            if (type == 'full' || type == 'partial' || type == 'settlement') {
              computedSum +=
                  (paymentDoc.data()['amountPaid'] as num?)?.toDouble() ??
                  0.0;
            }
          }

          // Heal summary document if missing, incorrect, or not yet marked as healed
          if (cachedVal != computedSum || !isHealed) {
            await doc.reference.set({
              'totalCollected': computedSum,
              'isHealed': true,
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }

        return MonthlyCollectedAmount(
          year: year,
          month: month,
          totalAmount: computedSum,
          payments: const [],
        );
      }).toList();

      final List<MonthlyCollectedAmount?> resultsWithNulls = await Future.wait(futures);
      final List<MonthlyCollectedAmount> results = resultsWithNulls
          .whereType<MonthlyCollectedAmount>()
          .toList();

      // Sort by date descending (latest month first)
      results.sort((a, b) {
        if (a.year != b.year) return b.year.compareTo(a.year);
        return b.month.compareTo(a.month);
      });

      return results;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to get monthly collected amounts: $e');
    }
  }

  @override
  Future<String> addDebt(DebtModel debt) async {
    try {
      final userRef = firestore.collection('users').doc(debt.uid);
      final customersCollection = userRef.collection('customers');

      // FETCH EXISTING CUSTOMER DATA to prevent data loss
      String? existingPhone = debt.phoneNumber;

      final customerSnapshot = await customersCollection
          .where('name', isEqualTo: debt.customerName?.trim())
          .limit(1)
          .get();

      if (customerSnapshot.docs.isNotEmpty) {
        final data = customerSnapshot.docs.first.data();
        existingPhone ??= data['phoneNumber'] as String?;
      }

      final debtRef = userRef.collection('debts').doc(debt.operationId);
      final opRef = userRef.collection('operations').doc(debt.operationId);

      final batch = firestore.batch();

      // Create a final JSON with the merged phone number
      final debtJson = debt.toJson();
      if (existingPhone != null) {
        debtJson['phoneNumber'] = existingPhone;
      }

      // 2. ONLY write to operations collection if this is a manual debt (not from Quick Add)
      // Quick Add operations are already written by OperationRepository.
      // We detect Quick Add operations by their ID prefix 'op_'.
      if (!debt.operationId.startsWith('op_')) {
        batch.set(opRef, {
          'uid': debt.uid,
          'type': debt.operationType,
          'customerName': debt.customerName,
          'productName': debt.productOrSessionDetails,
          'totalAmount': debt.totalAmount,
          'paidAmount': debt.paidAmount,
          'remainingDebt': debt.remainingAmount,
          'timestamp': FieldValue.serverTimestamp(),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
          'ledgerNumber': debt.ledgerNumber,
        });
      }

      // 3. Add to debts collection
      batch.set(debtRef, debtJson);

      // 4. Add initial transaction record to payments history
      final initialPaymentRef = debtRef
          .collection('payments')
          .doc('${debt.operationId}_initial');
      batch.set(initialPaymentRef, {
        'uid': debt.uid,
        'debtId': debt.operationId,
        'amountPaid': debt.totalAmount, // Debt amount
        'remainingAmount': debt.totalAmount, // Before payment applied
        'createdAt': debt.timestamp != null
            ? Timestamp.fromDate(debt.timestamp!)
            : FieldValue.serverTimestamp(),
        'type': PaymentType.debtAdded.name,
        'relatedTo': debt.customerName,
        'activityName': debt.productOrSessionDetails,
      });

      // 4. Add initial payment transaction if there was a payment
      if (debt.paidAmount > 0) {
        final actualPaymentRef = debtRef
            .collection('payments')
            .doc('${debt.operationId}_payment');
        batch.set(actualPaymentRef, {
          'uid': debt.uid,
          'debtId': debt.operationId,
          'amountPaid': debt.paidAmount,
          'remainingAmount': debt.remainingAmount,
          'createdAt': debt.timestamp != null
              ? Timestamp.fromDate(
                  debt.timestamp!.add(const Duration(milliseconds: 1)),
                )
              : FieldValue.serverTimestamp(),
          'type': debt.remainingAmount <= 0
              ? PaymentType.full.name
              : PaymentType.partial.name,
          'relatedTo': debt.customerName,
          'activityName': debt.productOrSessionDetails,
        });
      }

      // 5. Update Summaries
      final summaryKeys = SummaryHelper.getSummaryKeys(
        debt.timestamp ?? DateTime.now(),
      );

      // Check if this is the first unpaid debt for this customer to increment customer count
      final unpaidSnapshot = await userRef
          .collection('debts')
          .where('customerName', isEqualTo: debt.customerName)
          .where('isPaid', isEqualTo: false)
          .limit(1)
          .get();
      final bool isFirstUnpaid = unpaidSnapshot.docs.isEmpty;

      for (final key in summaryKeys) {
        final summaryRef = userRef.collection('summaries').doc(key);
        batch.set(summaryRef, {
          'totalDebts': FieldValue.increment(debt.remainingAmount),
          'unpaidDebts': FieldValue.increment(debt.remainingAmount),
          if (debt.paidAmount > 0)
            'totalCollected': FieldValue.increment(debt.paidAmount),
          if (isFirstUnpaid) 'debtCustomersCount': FieldValue.increment(1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      return debtRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to add debt: $e');
    }
  }

  @override
  Future<List<DebtModel>> getDebts(
    String uid, {
    bool forceRefresh = false,
  }) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .orderBy('timestamp', descending: true)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      return snapshot.docs
          .map((doc) => DebtModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch debts: $e');
    }
  }

  @override
  Future<List<DebtModel>> getCustomerDebts(
    String uid,
    String customerName, {
    bool forceRefresh = false,
  }) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .where('customerName', isEqualTo: customerName)
          .orderBy('lastUpdatedAt', descending: true)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      return snapshot.docs
          .map((doc) => DebtModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch customer debts: $e');
    }
  }

  @override
  Future<void> payDebt(DebtModel debt, PaymentModel payment) async {
    try {
      final uid = debt.uid;
      final userRef = firestore.collection('users').doc(uid);
      final debtRef = userRef.collection('debts').doc(debt.id);

      // Check if this was the last unpaid debt for this customer BEFORE the transaction
      final unpaidSnapshot = await userRef
          .collection('debts')
          .where('customerName', isEqualTo: debt.customerName)
          .where('isPaid', isEqualTo: false)
          .limit(2)
          .get();

      await firestore.runTransaction((transaction) async {
        // 1. ALL READS FIRST
        final debtSnap = await transaction.get(debtRef);
        if (!debtSnap.exists) {
          throw Exception("Debt document not found: ${debtRef.path}");
        }

        DocumentSnapshot? opSnap;
        final operationId = debt.operationId;
        if (operationId.isNotEmpty) {
          final opRef = userRef.collection('operations').doc(operationId);
          opSnap = await transaction.get(opRef);
        }

        // 2. ALL WRITES SECOND
        final debtData = debtSnap.data() as Map<String, dynamic>;
        final currentPaid = (debtData['paidAmount'] as num).toDouble();
        final currentTotal = (debtData['totalAmount'] as num).toDouble();

        final newPaidAmount = currentPaid + payment.amountPaid;
        final newRemainingAmount = currentTotal - newPaidAmount;
        final isPaid = newRemainingAmount <= 1e-9;

        // Update Debt document
        transaction.update(debtRef, {
          'paidAmount': newPaidAmount,
          'remainingAmount': newRemainingAmount,
          'isPaid': isPaid,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Update Linked Operation if it exists
        if (opSnap != null && opSnap.exists) {
          transaction.update(opSnap.reference, {
            'paidAmount': newPaidAmount,
            'remainingDebt': newRemainingAmount,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Record the payment in sub-collection
        final paymentRef = debtRef.collection('payments').doc();
        transaction.set(paymentRef, {
          'uid': uid,
          'debtId': debtRef.id,
          'amountPaid': payment.amountPaid,
          'remainingAmount': newRemainingAmount,
          'createdAt': FieldValue.serverTimestamp(),
          'type': isPaid ? PaymentType.full.name : PaymentType.partial.name,
          'relatedTo': debtData['customerName'],
          'activityName': debtData['productOrSessionDetails'],
        });

        // Check if customer became fully paid to decrement customer count
        // If they had only 1 unpaid debt before AND it's now paid
        final bool becameFullyPaid =
            isPaid &&
            unpaidSnapshot.docs.length == 1 &&
            unpaidSnapshot.docs.first.id == debt.id;

        // Update Summaries
        final Map<String, Map<String, double>> summaryAccumulator = {};

        void addSummaryIncrement(String key, String field, double value) {
          summaryAccumulator.putIfAbsent(key, () => {});
          summaryAccumulator[key]![field] = (summaryAccumulator[key]![field] ?? 0.0) + value;
        }

        // Debt metrics are grouped by debt creation date
        final debtKeys = SummaryHelper.getSummaryKeys(debt.timestamp ?? DateTime.now());
        for (final key in debtKeys) {
          addSummaryIncrement(key, 'totalDebts', -payment.amountPaid);
          addSummaryIncrement(key, 'unpaidDebts', -payment.amountPaid);
          if (isPaid) {
            addSummaryIncrement(key, 'paidDebts', currentTotal);
          }
        }

        // Customer status update is grouped by current timestamp
        if (becameFullyPaid) {
          final currentKeys = SummaryHelper.getSummaryKeys(DateTime.now());
          for (final key in currentKeys) {
            addSummaryIncrement(key, 'debtCustomersCount', -1.0);
          }
        }

        // Payment metrics (totalCollected) are grouped by actual payment transaction date (now)
        final paymentKeys = SummaryHelper.getSummaryKeys(DateTime.now());
        for (final key in paymentKeys) {
          addSummaryIncrement(key, 'totalCollected', payment.amountPaid);
        }

        // Write accumulated summaries to Firestore
        for (final entry in summaryAccumulator.entries) {
          final summaryRef = userRef.collection('summaries').doc(entry.key);
          final Map<String, dynamic> updateData = {};
          entry.value.forEach((field, val) {
            updateData[field] = FieldValue.increment(val);
          });
          updateData['lastUpdatedAt'] = FieldValue.serverTimestamp();

          transaction.set(summaryRef, updateData, SetOptions(merge: true));
        }
      });
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to process payment: $e');
    }
  }

  @override
  Future<void> payTotalDebt(
    String uid,
    String customerName,
    double amount,
  ) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .where('customerName', isEqualTo: customerName)
          .where('isPaid', isEqualTo: false)
          .orderBy('timestamp', descending: false) // FIFO
          .get();

      if (snapshot.docs.isEmpty) return;

      await firestore.runTransaction((transaction) async {
        // 1. ALL READS FIRST
        final Map<String, DocumentSnapshot> opSnaps = {};
        for (var doc in snapshot.docs) {
          final operationId = doc.data()['operationId'] as String?;
          if (operationId != null && operationId.isNotEmpty) {
            final opRef = firestore
                .collection('users')
                .doc(uid)
                .collection('operations')
                .doc(operationId);
            opSnaps[operationId] = await transaction.get(opRef);
          }
        }

        // 2. ALL WRITES SECOND
        double remainingToPay = amount;
        final Map<String, Map<String, double>> summaryAccumulator = {};

        void addSummaryIncrement(String key, String field, double value) {
          summaryAccumulator.putIfAbsent(key, () => {});
          summaryAccumulator[key]![field] = (summaryAccumulator[key]![field] ?? 0.0) + value;
        }

        for (var docSnap in snapshot.docs) {
          if (remainingToPay <= 0) break;

          final debtData = docSnap.data();
          // final debtId = docSnap.id;
          final operationId = debtData['operationId'] as String?;
          final currentTotal = (debtData['totalAmount'] as num).toDouble();
          final currentPaid = (debtData['paidAmount'] as num).toDouble();
          final currentRemaining = (debtData['remainingAmount'] as num)
              .toDouble();

          double paymentForThisItem = 0;
          if (remainingToPay >= currentRemaining) {
            paymentForThisItem = currentRemaining;
            remainingToPay -= currentRemaining;
          } else {
            paymentForThisItem = remainingToPay;
            remainingToPay = 0;
          }

          final newPaidAmount = currentPaid + paymentForThisItem;
          final newRemainingAmount = currentTotal - newPaidAmount;
          final isPaid = newRemainingAmount <= 1e-9;

          final debtRef = docSnap.reference;

          // Update debt record
          transaction.update(debtRef, {
            'paidAmount': newPaidAmount,
            'remainingAmount': newRemainingAmount,
            'isPaid': isPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });

          // Update the linked operation record if it exists and was read successfully
          if (operationId != null && opSnaps.containsKey(operationId)) {
            final opSnap = opSnaps[operationId]!;
            if (opSnap.exists) {
              transaction.update(opSnap.reference, {
                'paidAmount': newPaidAmount,
                'remainingDebt': newRemainingAmount,
                'lastUpdatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          // Add payment record
          final paymentRef = debtRef.collection('payments').doc();
          transaction.set(paymentRef, {
            'uid': uid,
            'debtId': debtRef.id,
            'amountPaid': paymentForThisItem,
            'remainingAmount': newRemainingAmount,
            'createdAt': FieldValue.serverTimestamp(),
            'type': isPaid ? PaymentType.full.name : PaymentType.partial.name,
            'relatedTo': debtData['customerName'],
            'activityName': debtData['productOrSessionDetails'],
          });

          // Accumulate summary updates:
          // 1. Debt metrics are grouped by debt creation date
          final debtTimestamp = (debtData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final debtKeys = SummaryHelper.getSummaryKeys(debtTimestamp);
          for (final key in debtKeys) {
            addSummaryIncrement(key, 'totalDebts', -paymentForThisItem);
            addSummaryIncrement(key, 'unpaidDebts', -paymentForThisItem);
            if (isPaid) {
              addSummaryIncrement(key, 'paidDebts', currentTotal);
            }
          }

          // 2. Payment metrics (totalCollected) are grouped by actual payment transaction date (now)
          final paymentKeys = SummaryHelper.getSummaryKeys(DateTime.now());
          for (final key in paymentKeys) {
            addSummaryIncrement(key, 'totalCollected', paymentForThisItem);
          }
        }

        // After processing all debts for this customer, check if they are now fully paid
        double totalUnpaidInSnapshot = snapshot.docs.fold(
          0.0,
          (sum, d) => sum + (d.data()['remainingAmount'] as num).toDouble(),
        );
        if (amount >= totalUnpaidInSnapshot - 1e-9) {
          final nowKeys = SummaryHelper.getSummaryKeys(DateTime.now());
          for (final key in nowKeys) {
            addSummaryIncrement(key, 'debtCustomersCount', -1.0);
          }
        }

        // Write all accumulated summaries to Firestore
        summaryAccumulator.forEach((key, fields) {
          final summaryRef = firestore
              .collection('users')
              .doc(uid)
              .collection('summaries')
              .doc(key);

          final Map<String, dynamic> updateData = {};
          fields.forEach((field, val) {
            updateData[field] = FieldValue.increment(val);
          });
          updateData['lastUpdatedAt'] = FieldValue.serverTimestamp();

          transaction.set(summaryRef, updateData, SetOptions(merge: true));
        });
      });
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to pay total debt: $e');
    }
  }

  @override
  Future<void> markCustomerAsPaid(String uid, String customerName) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .where('customerName', isEqualTo: customerName)
          .where('isPaid', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      await firestore.runTransaction((transaction) async {
        // 1. ALL READS FIRST
        final Map<String, DocumentSnapshot> opSnaps = {};
        for (var doc in snapshot.docs) {
          final operationId = doc.data()['operationId'] as String?;
          if (operationId != null && operationId.isNotEmpty) {
            final opRef = firestore
                .collection('users')
                .doc(uid)
                .collection('operations')
                .doc(operationId);
            opSnaps[operationId] = await transaction.get(opRef);
          }
        }

        // 2. ALL WRITES SECOND
        final Map<String, Map<String, double>> summaryAccumulator = {};

        void addSummaryIncrement(String key, String field, double value) {
          summaryAccumulator.putIfAbsent(key, () => {});
          summaryAccumulator[key]![field] = (summaryAccumulator[key]![field] ?? 0.0) + value;
        }

        for (var docSnap in snapshot.docs) {
          final debtData = docSnap.data();
          final debtId = docSnap.id;
          final operationId = debtData['operationId'] as String?;
          final currentTotal = (debtData['totalAmount'] as num).toDouble();
          final currentPaid = (debtData['paidAmount'] as num).toDouble();

          final debtRef = docSnap.reference;

          // Update debt record
          transaction.update(debtRef, {
            'paidAmount': currentTotal,
            'remainingAmount': 0.0,
            'isPaid': true,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });

          // Update the linked operation record if it exists and was read
          if (operationId != null && opSnaps.containsKey(operationId)) {
            final opSnap = opSnaps[operationId]!;
            if (opSnap.exists) {
              transaction.update(opSnap.reference, {
                'paidAmount': currentTotal,
                'remainingDebt': 0.0,
                'lastUpdatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          // Add payment record
          final paymentRef = debtRef.collection('payments').doc();
          final amountToPay = currentTotal - currentPaid;
          transaction.set(paymentRef, {
            'uid': uid,
            'debtId': debtId,
            'amountPaid': amountToPay,
            'remainingAmount': 0.0,
            'createdAt': FieldValue.serverTimestamp(),
            'type': PaymentType.settlement.name,
            'relatedTo': debtData['customerName'],
            'activityName': debtData['productOrSessionDetails'],
          });

          // Accumulate summary updates:
          // 1. Debt metrics are grouped by debt creation date
          final debtTimestamp = (debtData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final debtKeys = SummaryHelper.getSummaryKeys(debtTimestamp);
          for (final key in debtKeys) {
            addSummaryIncrement(key, 'totalDebts', -amountToPay);
            addSummaryIncrement(key, 'unpaidDebts', -amountToPay);
            addSummaryIncrement(key, 'paidDebts', currentTotal);
          }

          // 2. Payment metrics (totalCollected) are grouped by actual payment transaction date (now)
          final paymentKeys = SummaryHelper.getSummaryKeys(DateTime.now());
          for (final key in paymentKeys) {
            addSummaryIncrement(key, 'totalCollected', amountToPay);
          }
        }

        // Decrement debtCustomersCount in summaries since customer is now fully paid
        final nowKeys = SummaryHelper.getSummaryKeys(DateTime.now());
        for (final key in nowKeys) {
          addSummaryIncrement(key, 'debtCustomersCount', -1.0);
        }

        // Write all accumulated summaries to Firestore
        summaryAccumulator.forEach((key, fields) {
          final summaryRef = firestore
              .collection('users')
              .doc(uid)
              .collection('summaries')
              .doc(key);

          final Map<String, dynamic> updateData = {};
          fields.forEach((field, val) {
            updateData[field] = FieldValue.increment(val);
          });
          updateData['lastUpdatedAt'] = FieldValue.serverTimestamp();

          transaction.set(summaryRef, updateData, SetOptions(merge: true));
        });
      });
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to mark customer as paid: $e');
    }
  }

  @override
  Future<void> deleteCustomerDebts(String uid, String customerName) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .where('customerName', isEqualTo: customerName)
          .get();

      if (snapshot.docs.isEmpty) return;

      // Track summary updates and document references to delete
      final Map<String, Map<String, double>> summaryUpdates = {};
      final List<DocumentReference> allRefs = [];
      bool hadUnpaid = false;

      void addSummaryIncrement(String key, String field, double value) {
        summaryUpdates.putIfAbsent(key, () => {});
        summaryUpdates[key]![field] = (summaryUpdates[key]![field] ?? 0.0) + value;
      }

      // 1. Pre-calculate if there are any unpaid debts for this customer
      for (var doc in snapshot.docs) {
        if (!(doc.data()['isPaid'] as bool? ?? false)) {
          hadUnpaid = true;
          break;
        }
      }

      // 2. Process all documents to collect refs and summary deltas
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp =
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final remaining = (data['remainingAmount'] as num?)?.toDouble() ?? 0.0;
        final total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final isPaid = (data['isPaid'] as bool?) ?? false;

        // Debt metrics are decremented using the debt's original creation timestamp
        final debtKeys = SummaryHelper.getSummaryKeys(timestamp);
        for (final key in debtKeys) {
          addSummaryIncrement(key, 'totalDebts', -remaining);
          if (!isPaid) {
            addSummaryIncrement(key, 'unpaidDebts', -remaining);
          } else {
            addSummaryIncrement(key, 'paidDebts', -total);
          }
        }

        // Collect payment sub-collection docs
        final paymentsSnapshot = await doc.reference
            .collection('payments')
            .get();

        for (var paymentDoc in paymentsSnapshot.docs) {
          allRefs.add(paymentDoc.reference);

          final paymentData = paymentDoc.data();
          final type = paymentData['type'] as String?;
          final amountPaid = (paymentData['amountPaid'] as num?)?.toDouble() ?? 0.0;
          final paymentCreatedAt = (paymentData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

          // Decrement totalCollected using actual payment documents and their timestamps
          if (type == 'full' || type == 'partial' || type == 'settlement') {
            final paymentKeys = SummaryHelper.getSummaryKeys(paymentCreatedAt);
            for (final key in paymentKeys) {
              addSummaryIncrement(key, 'totalCollected', -amountPaid);
            }
          }
        }
        allRefs.add(doc.reference);
      }

      // Customer status decrement is grouped under current month
      if (hadUnpaid) {
        final nowKeys = SummaryHelper.getSummaryKeys(DateTime.now());
        for (final key in nowKeys) {
          addSummaryIncrement(key, 'debtCustomersCount', -1.0);
        }
      }

      // 3. Batch commit in chunks of 500
      for (var i = 0; i < allRefs.length; i += 500) {
        final chunk = allRefs.sublist(
          i,
          i + 500 > allRefs.length ? allRefs.length : i + 500,
        );
        final batch = firestore.batch();
        for (var ref in chunk) {
          batch.delete(ref);
        }

        // Only add summary updates to the FIRST batch
        if (i == 0) {
          summaryUpdates.forEach((key, fields) {
            final summaryRef = firestore
                .collection('users')
                .doc(uid)
                .collection('summaries')
                .doc(key);

            final Map<String, dynamic> updateData = {};
            fields.forEach((field, val) {
              updateData[field] = FieldValue.increment(val);
            });
            updateData['lastUpdatedAt'] = FieldValue.serverTimestamp();

            batch.set(summaryRef, updateData, SetOptions(merge: true));
          });
        }

        await batch.commit();
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to delete customer debts: $e');
    }
  }

  @override
  Future<void> deleteDebtItem(String uid, String debtId) async {
    try {
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .doc(debtId);

      // 1. Get associated operation ID first
      final debtDoc = await debtRef.get();
      if (!debtDoc.exists) return;

      final operationId = debtDoc.data()?['operationId'] as String?;

      // 2. Fetch all payment references
      final paymentsSnapshot = await debtRef.collection('payments').get();

      final List<DocumentReference> allRefs = [];
      for (var doc in paymentsSnapshot.docs) {
        allRefs.add(doc.reference);
      }

      final batch = firestore.batch();

      // 3. Delete payments
      for (var ref in allRefs) {
        batch.delete(ref);
      }

      // 4. Delete operation record if it exists
      if (operationId != null && operationId.isNotEmpty) {
        final opRef = firestore
            .collection('users')
            .doc(uid)
            .collection('operations')
            .doc(operationId);
        batch.delete(opRef);
      }

      // 5. Delete debt document
      batch.delete(debtRef);

      // 6. Update Summaries (Decrement)
      final timestamp =
          (debtDoc.data()?['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now();
      final remainingAmount =
          (debtDoc.data()?['remainingAmount'] as num?)?.toDouble() ?? 0.0;
      final totalAmount =
          (debtDoc.data()?['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final isPaid = (debtDoc.data()?['isPaid'] as bool?) ?? false;

      // Check if this was the last unpaid debt for this customer BEFORE the loop
      bool shouldDecrementCustomerCount = false;
      if (!isPaid) {
        final otherUnpaid = await firestore
            .collection('users')
            .doc(uid)
            .collection('debts')
            .where('customerName', isEqualTo: debtDoc.data()?['customerName'])
            .where('isPaid', isEqualTo: false)
            .limit(2)
            .get();
        // If length is 1, it's just this one (which is about to be deleted)
        if (otherUnpaid.docs.length <= 1) {
          shouldDecrementCustomerCount = true;
        }
      }

      // Build accumulator for grouped summary updates
      final Map<String, Map<String, double>> summaryAccumulator = {};

      void addSummaryIncrement(String key, String field, double value) {
        summaryAccumulator.putIfAbsent(key, () => {});
        summaryAccumulator[key]![field] = (summaryAccumulator[key]![field] ?? 0.0) + value;
      }

      // Debt metrics are decremented using the debt's original creation timestamp
      final debtKeys = SummaryHelper.getSummaryKeys(timestamp);
      for (final key in debtKeys) {
        addSummaryIncrement(key, 'totalDebts', -remainingAmount);
        if (!isPaid) {
          addSummaryIncrement(key, 'unpaidDebts', -remainingAmount);
        } else {
          addSummaryIncrement(key, 'paidDebts', -totalAmount);
        }
      }

      // Decrement totalCollected using actual payment documents and their timestamps
      for (var paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final type = paymentData['type'] as String?;
        final amountPaid = (paymentData['amountPaid'] as num?)?.toDouble() ?? 0.0;
        final paymentCreatedAt = (paymentData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        if (type == 'full' || type == 'partial' || type == 'settlement') {
          final paymentKeys = SummaryHelper.getSummaryKeys(paymentCreatedAt);
          for (final key in paymentKeys) {
            addSummaryIncrement(key, 'totalCollected', -amountPaid);
          }
        }
      }

      // Customer status decrement is grouped under current month
      if (shouldDecrementCustomerCount) {
        final nowKeys = SummaryHelper.getSummaryKeys(DateTime.now());
        for (final key in nowKeys) {
          addSummaryIncrement(key, 'debtCustomersCount', -1.0);
        }
      }

      // Write all accumulated summaries to the batch
      summaryAccumulator.forEach((key, fields) {
        final summaryRef = firestore
            .collection('users')
            .doc(uid)
            .collection('summaries')
            .doc(key);

        final Map<String, dynamic> updateData = {};
        fields.forEach((field, val) {
          updateData[field] = FieldValue.increment(val);
        });
        updateData['lastUpdatedAt'] = FieldValue.serverTimestamp();

        batch.set(summaryRef, updateData, SetOptions(merge: true));
      });

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to delete debt item: $e');
    }
  }

  @override
  Stream<List<PaymentModel>> getDebtTransactions(String uid, String debtId) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('debts')
        .doc(debtId)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<List<PaymentModel>> getDebtTransactionsFuture(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .doc(debtId)
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getCustomerAllPayments(
    String uid,
    String customerName,
  ) async {
    try {
      // 1. Fetch all debts for this customer
      final debtsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .where('customerName', isEqualTo: customerName)
          .get();

      List<PaymentModel> allPayments = [];

      for (var debtDoc in debtsSnapshot.docs) {
        final debtData = debtDoc.data();
        final activityName = debtData['operationType'] as String;

        // 2. Fetch payments for this specific debt
        final paymentsSnapshot = await debtDoc.reference
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .get();

        for (var paymentDoc in paymentsSnapshot.docs) {
          final paymentData = paymentDoc.data();
          // Inject activityName from parent debt
          paymentData['activityName'] = activityName;

          allPayments.add(PaymentModel.fromJson(paymentData, paymentDoc.id));
        }
      }

      // Note: Sorting and calculations will be handled by the Isolate in the presentation layer/Cubit
      return allPayments;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch customer payments: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getAllUserPayments(String uid) async {
    try {
      final snapshot = await firestore
          .collectionGroup('payments')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch all user payments: $e');
    }
  }

  @override
  Stream<List<DebtModel>> getDebtsStream(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('debts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DebtModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<void> updatePayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required double newAmount,
    String? note,
  }) async {
    try {
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .doc(debtId);
      final paymentRef = debtRef.collection('payments').doc(paymentId);

      final debtDoc = await debtRef.get();
      if (!debtDoc.exists) throw Exception('Debt not found');

      final debtData = debtDoc.data() as Map<String, dynamic>;
      final customerName = debtData['customerName'] as String?;

      bool wasCustomerFullyPaid = false;
      int unpaidDebtsCount = 0;
      bool isThisDebtInUnpaidList = false;

      if (customerName != null && customerName.isNotEmpty) {
        final unpaidSnapshot = await firestore
            .collection('users')
            .doc(uid)
            .collection('debts')
            .where('customerName', isEqualTo: customerName)
            .where('isPaid', isEqualTo: false)
            .get();
        unpaidDebtsCount = unpaidSnapshot.docs.length;
        wasCustomerFullyPaid = unpaidSnapshot.docs.isEmpty;
        isThisDebtInUnpaidList = unpaidSnapshot.docs.any((doc) => doc.id == debtId);
      }

      await firestore.runTransaction((transaction) async {
        final debtSnap = await transaction.get(debtRef);
        if (!debtSnap.exists) throw Exception('Debt not found');

        // Fetch all payments to recompute and validate
        final paymentsSnapshot = await debtRef
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .get();
        final allPayments = paymentsSnapshot.docs
            .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
            .toList();

        final targetPayment = allPayments.firstWhere((p) => p.id == paymentId);

        final String relatedTo = targetPayment.type == PaymentType.debtAdded
            ? 'debt'
            : 'payment';

        // RULE 3 validation for debtAdded
        if (targetPayment.type == PaymentType.debtAdded) {
          final paymentsAfter = allPayments
              .where(
                (p) =>
                    (p.type == PaymentType.partial ||
                        p.type == PaymentType.full ||
                        p.type == PaymentType.settlement) &&
                    p.createdAt!.isAfter(targetPayment.createdAt!),
              )
              .toList();

          if (paymentsAfter.isNotEmpty) {
            final nearestPayment = paymentsAfter.last;
            if (newAmount < nearestPayment.amountPaid) {
              throw Exception('invalid_amount');
            }
          }
        }

        final delta = newAmount - targetPayment.amountPaid;
        if (delta == 0) return;

        // Direct Mutation: Update the same item
        transaction.update(paymentRef, {
          'amountPaid': newAmount,
          'activityName': note ?? targetPayment.activityName,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Compute new values
        final currentTotal = (debtData['totalAmount'] as num).toDouble();
        final currentPaid = (debtData['paidAmount'] as num).toDouble();
        final currentRemaining = (debtData['remainingAmount'] as num).toDouble();
        final originalIsPaid = (debtData['isPaid'] as bool?) ?? false;

        double newTotalAmount = currentTotal;
        double newPaidAmount = currentPaid;
        double newRemainingAmount = currentRemaining;

        if (relatedTo == 'debt') {
          newTotalAmount = currentTotal + delta;
          newRemainingAmount = currentRemaining + delta;
        } else {
          newPaidAmount = currentPaid + delta;
          newRemainingAmount = currentRemaining - delta;
        }

        final bool newIsPaid = newRemainingAmount <= 1e-9;

        // Update stored totals and isPaid
        if (relatedTo == 'debt') {
          transaction.update(debtRef, {
            'totalAmount': newTotalAmount,
            'remainingAmount': newRemainingAmount,
            'isPaid': newIsPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(debtRef, {
            'paidAmount': newPaidAmount,
            'remainingAmount': newRemainingAmount,
            'isPaid': newIsPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update operation if it exists
        final operationId = debtSnap.data()?['operationId'] as String?;
        if (operationId != null && operationId.isNotEmpty) {
          final opRef = firestore
              .collection('users')
              .doc(uid)
              .collection('operations')
              .doc(operationId);
          if (relatedTo == 'debt') {
            transaction.update(opRef, {
              'totalAmount': newTotalAmount,
              'remainingDebt': newRemainingAmount,
            });
          } else {
            transaction.update(opRef, {
              'paidAmount': newPaidAmount,
              'remainingDebt': newRemainingAmount,
            });
          }
        }

        // Update Summaries using decoupled accumulator pattern
        final Map<String, Map<String, double>> summaryAccumulator = {};

        void addSummaryIncrement(String key, String field, double value) {
          summaryAccumulator.putIfAbsent(key, () => {});
          summaryAccumulator[key]![field] = (summaryAccumulator[key]![field] ?? 0.0) + value;
        }

        final double summaryDelta = relatedTo == 'debt' ? delta : -delta;

        // Debt metrics are grouped by debt creation date
        final debtTimestamp = (debtSnap.data()?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final debtKeys = SummaryHelper.getSummaryKeys(debtTimestamp);
        for (final key in debtKeys) {
          addSummaryIncrement(key, 'totalDebts', summaryDelta);
          addSummaryIncrement(key, 'unpaidDebts', summaryDelta);

          if (originalIsPaid && !newIsPaid) {
            // Paid to unpaid: decrement paidDebts by total amount
            addSummaryIncrement(key, 'paidDebts', -currentTotal);
          } else if (!originalIsPaid && newIsPaid) {
            // Unpaid to paid: increment paidDebts by new total amount
            addSummaryIncrement(key, 'paidDebts', newTotalAmount);
          }
        }

        // Customer count and status updates
        if (originalIsPaid && !newIsPaid && wasCustomerFullyPaid) {
          // Customer went from fully paid to unpaid: increment customer count (grouped by current time)
          final nowKeys = SummaryHelper.getSummaryKeys(DateTime.now());
          for (final key in nowKeys) {
            addSummaryIncrement(key, 'debtCustomersCount', 1.0);
          }
        } else if (!originalIsPaid && newIsPaid) {
          // Unpaid to paid: check if customer became fully paid
          final bool becameFullyPaid = unpaidDebtsCount == 1 && isThisDebtInUnpaidList;
          if (becameFullyPaid) {
            final nowKeys = SummaryHelper.getSummaryKeys(DateTime.now());
            for (final key in nowKeys) {
              addSummaryIncrement(key, 'debtCustomersCount', -1.0);
            }
          }
        }

        // Payment metrics (totalCollected) are grouped by the payment's own createdAt date
        if (relatedTo == 'payment') {
          final paymentTimestamp = targetPayment.createdAt ?? DateTime.now();
          final paymentKeys = SummaryHelper.getSummaryKeys(paymentTimestamp);
          for (final key in paymentKeys) {
            addSummaryIncrement(key, 'totalCollected', delta);
          }
        }

        // Write all accumulated summaries
        for (final entry in summaryAccumulator.entries) {
          final summaryRef = firestore
              .collection('users')
              .doc(uid)
              .collection('summaries')
              .doc(entry.key);

          final Map<String, dynamic> updateData = {};
          entry.value.forEach((field, val) {
            updateData[field] = FieldValue.increment(val);
          });
          updateData['lastUpdatedAt'] = FieldValue.serverTimestamp();

          transaction.set(summaryRef, updateData, SetOptions(merge: true));
        }
      });
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> deletePayment({
    required String uid,
    required String debtId,
    required String paymentId,
  }) async {
    try {
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .doc(debtId);
      final paymentRef = debtRef.collection('payments').doc(paymentId);

      final debtDoc = await debtRef.get();
      if (!debtDoc.exists) throw Exception('Debt not found');

      final debtData = debtDoc.data() as Map<String, dynamic>;
      final customerName = debtData['customerName'] as String?;

      bool wasCustomerFullyPaid = false;
      if (customerName != null && customerName.isNotEmpty) {
        final unpaidSnapshot = await firestore
            .collection('users')
            .doc(uid)
            .collection('debts')
            .where('customerName', isEqualTo: customerName)
            .where('isPaid', isEqualTo: false)
            .limit(1)
            .get();
        wasCustomerFullyPaid = unpaidSnapshot.docs.isEmpty;
      }

      await firestore.runTransaction((transaction) async {
        final debtSnap = await transaction.get(debtRef);
        if (!debtSnap.exists) throw Exception('Debt not found');

        final paymentsSnapshot = await debtRef
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .get();
        final allPayments = paymentsSnapshot.docs
            .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
            .toList();

        final targetPayment = allPayments.firstWhere((p) => p.id == paymentId);
        final String relatedTo = targetPayment.type == PaymentType.debtAdded
            ? 'debt'
            : 'payment';

        if (targetPayment.type == PaymentType.debtAdded) {
          // RULE 2: Check for newer payments
          final hasNewerPayments = allPayments.any(
            (p) =>
                (p.type == PaymentType.partial ||
                    p.type == PaymentType.full ||
                    p.type == PaymentType.settlement) &&
                p.createdAt!.isAfter(targetPayment.createdAt!),
          );
          if (hasNewerPayments) {
            throw Exception('delete_not_allowed');
          }
        }

        // Direct Mutation: Delete the same item
        transaction.delete(paymentRef);

        // Calculate new values
        final currentTotal = (debtData['totalAmount'] as num).toDouble();
        final currentPaid = (debtData['paidAmount'] as num).toDouble();
        final currentRemaining = (debtData['remainingAmount'] as num).toDouble();
        final originalIsPaid = (debtData['isPaid'] as bool?) ?? false;
        final amountToDelete = targetPayment.amountPaid;

        double newTotalAmount = currentTotal;
        double newPaidAmount = currentPaid;
        double newRemainingAmount = currentRemaining;

        if (relatedTo == 'debt') {
          newTotalAmount = currentTotal - amountToDelete;
          newRemainingAmount = currentRemaining - amountToDelete;
        } else {
          newPaidAmount = currentPaid - amountToDelete;
          newRemainingAmount = currentRemaining + amountToDelete;
        }

        final bool newIsPaid = newRemainingAmount <= 1e-9;

        // Update stored totals and isPaid
        if (relatedTo == 'debt') {
          transaction.update(debtRef, {
            'totalAmount': newTotalAmount,
            'remainingAmount': newRemainingAmount,
            'isPaid': newIsPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(debtRef, {
            'paidAmount': newPaidAmount,
            'remainingAmount': newRemainingAmount,
            'isPaid': newIsPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update operation if it exists
        final operationId = debtSnap.data()?['operationId'] as String?;
        if (operationId != null && operationId.isNotEmpty) {
          final opRef = firestore
              .collection('users')
              .doc(uid)
              .collection('operations')
              .doc(operationId);
          if (relatedTo == 'debt') {
            transaction.update(opRef, {
              'totalAmount': newTotalAmount,
              'remainingDebt': newRemainingAmount,
            });
          } else {
            transaction.update(opRef, {
              'paidAmount': newPaidAmount,
              'remainingDebt': newRemainingAmount,
            });
          }
        }

        // Update Summaries using decoupled accumulator pattern
        final Map<String, Map<String, double>> summaryAccumulator = {};

        void addSummaryIncrement(String key, String field, double value) {
          summaryAccumulator.putIfAbsent(key, () => {});
          summaryAccumulator[key]![field] = (summaryAccumulator[key]![field] ?? 0.0) + value;
        }

        final double summaryDelta = relatedTo == 'debt'
            ? -amountToDelete
            : amountToDelete;

        // Debt metrics are grouped by debt creation date
        final debtTimestamp = (debtSnap.data()?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final debtKeys = SummaryHelper.getSummaryKeys(debtTimestamp);
        for (final key in debtKeys) {
          addSummaryIncrement(key, 'totalDebts', summaryDelta);
          addSummaryIncrement(key, 'unpaidDebts', summaryDelta);

          if (originalIsPaid && !newIsPaid) {
            // Paid to unpaid: decrement paidDebts by total amount
            addSummaryIncrement(key, 'paidDebts', -currentTotal);
          }
        }

        // Customer status update
        if (originalIsPaid && !newIsPaid && wasCustomerFullyPaid) {
          // Customer went from fully paid to unpaid: increment customer count (grouped by current time)
          final nowKeys = SummaryHelper.getSummaryKeys(DateTime.now());
          for (final key in nowKeys) {
            addSummaryIncrement(key, 'debtCustomersCount', 1.0);
          }
        }

        // Payment metrics (totalCollected) reversal uses the payment's own createdAt date
        if (relatedTo == 'payment') {
          final paymentTimestamp = targetPayment.createdAt ?? DateTime.now();
          final paymentKeys = SummaryHelper.getSummaryKeys(paymentTimestamp);
          for (final key in paymentKeys) {
            addSummaryIncrement(key, 'totalCollected', -amountToDelete);
          }
        }

        // Write all accumulated summaries
        for (final entry in summaryAccumulator.entries) {
          final summaryRef = firestore
              .collection('users')
              .doc(uid)
              .collection('summaries')
              .doc(entry.key);

          final Map<String, dynamic> updateData = {};
          entry.value.forEach((field, val) {
            updateData[field] = FieldValue.increment(val);
          });
          updateData['lastUpdatedAt'] = FieldValue.serverTimestamp();

          transaction.set(summaryRef, updateData, SetOptions(merge: true));
        }
      });
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  /// Private helper to get a Debt reference with fallback
  DocumentReference _getDebtRef(String uid, String? id, String? operationId) {
    final debtsCollection = firestore
        .collection('users')
        .doc(uid)
        .collection('debts');

    if (id != null && id.isNotEmpty) {
      return debtsCollection.doc(id);
    } else if (operationId != null && operationId.isNotEmpty) {
      return debtsCollection.doc(operationId);
    } else {
      throw Exception(
        "Cannot resolve Debt reference: Both id and operationId are empty.",
      );
    }
  }

  @override
  Future<PaginatedResult<DebtModel>> getDebtsPaginated(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  }) async {
    try {
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .orderBy('lastUpdatedAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get(
        GetOptions(
          source: forceRefresh ? Source.server : Source.serverAndCache,
        ),
      );

      final items = snapshot.docs
          .map((doc) => DebtModel.fromJson(doc.data(), doc.id))
          .toList();

      return PaginatedResult(
        items: items,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: items.length == limit,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch paginated debts: $e');
    }
  }

  @override
  Future<PaginatedResult<PaymentModel>> getDebtTransactionsPaginated(
    String uid,
    String debtId, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Use direct path instead of collectionGroup for better reliability with old records
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .doc(debtId)
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final items = snapshot.docs
          .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
          .toList();

      return PaginatedResult(
        items: items,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: items.length == limit,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch paginated transactions: $e');
    }
  }

  @override
  Future<PaginatedResult<PaymentModel>> getCustomerAllPaymentsPaginated(
    String uid,
    String customerName, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // NOTE: Because payments are in sub-collections of debts,
      // and a customer can have many debts, we have two options:
      // 1. Fetch debt IDs for this customer to support legacy records missing 'relatedTo'
      // This is efficient as it only fetches IDs from the user's debts sub-collection.
      final debtsSnap = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .where('customerName', isEqualTo: customerName)
          .get();

      final debtIds = debtsSnap.docs.map((doc) => doc.id).toList();

      if (debtIds.isEmpty) {
        return const PaginatedResult(
          items: [],
          lastDocument: null,
          hasMore: false,
        );
      }

      // 2. Query payments using collectionGroup.
      // We prioritize 'relatedTo' for efficiency, but fallback to 'debtId' for legacy data.
      // Since we want pagination, we use a single query where possible.

      Query<Map<String, dynamic>> query;

      // If we have many debts, we rely on 'relatedTo' which should be on modern records.
      // For legacy records, we hope they are among the recent debts if there are many.
      if (debtIds.length > 10) {
        // Use relatedTo filter (Modern approach)
        // Note: Old records missing this field will unfortunately be missed if there are > 10 debts,
        // but this is an extreme case and 'relatedTo' is now set on all new records.
        query = firestore
            .collectionGroup('payments')
            .where('relatedTo', isEqualTo: customerName)
            .orderBy('createdAt', descending: true);
      } else {
        // Use debtId whereIn (Universal approach for up to 10 debts)
        query = firestore
            .collectionGroup('payments')
            .where('debtId', whereIn: debtIds)
            .orderBy('createdAt', descending: true);
      }

      query = query.limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final items = snapshot.docs
          .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
          .toList();

      return PaginatedResult(
        items: items,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: items.length == limit,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch paginated customer payments: $e');
    }
  }

  @override
  Future<PaginatedResult<PaymentModel>> getAllUserPaymentsPaginated(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
    int? month,
    int? year,
  }) async {
    try {
      var query = firestore
          .collectionGroup('payments')
          .where('uid', isEqualTo: uid);

      if (month != null && year != null) {
        final startOfMonth = DateTime(year, month, 1);
        final endOfMonth = DateTime(
          year,
          month + 1,
          1,
        ).subtract(const Duration(milliseconds: 1));
        query = query
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            )
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
            );
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final items = snapshot.docs
          .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
          .toList();

      return PaginatedResult(
        items: items,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: items.length == limit,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch paginated user payments: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDebtSummary(String uid) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('summaries')
          .doc(SummaryHelper.getAllTimeKey())
          .get();

      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        // final double unpaidDebts = (data['unpaidDebts'] ?? 0.0).toDouble();
        final int debtCustomersCount = (data['debtCustomersCount'] ?? 0)
            .toInt();

        if (debtCustomersCount <= 0) {
          // Heal: recalculate active customers count and update Firestore
          final activeDebts = await firestore
              .collection('users')
              .doc(uid)
              .collection('debts')
              .where('isPaid', isEqualTo: false)
              .get();

          final uniqueCustomers = activeDebts.docs
              .map((doc) => doc.data()['customerName'] as String?)
              .whereType<String>()
              .map((name) => name.trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .length;

          await firestore
              .collection('users')
              .doc(uid)
              .collection('summaries')
              .doc(SummaryHelper.getAllTimeKey())
              .update({'debtCustomersCount': uniqueCustomers});

          data['debtCustomersCount'] = uniqueCustomers;
        }
        return data;
      } else {
        // If the summary document doesn't exist, check if there are unpaid debts to calculate from
        final activeDebts = await firestore
            .collection('users')
            .doc(uid)
            .collection('debts')
            .where('isPaid', isEqualTo: false)
            .get();

        if (activeDebts.docs.isNotEmpty) {
          final uniqueCustomers = activeDebts.docs
              .map((doc) => doc.data()['customerName'] as String?)
              .whereType<String>()
              .map((name) => name.trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .length;

          double unpaidTotal = 0.0;
          for (var doc in activeDebts.docs) {
            unpaidTotal += (doc.data()['remainingAmount'] ?? 0.0).toDouble();
          }

          final summaryData = {
            'totalDebts': unpaidTotal,
            'unpaidDebts': unpaidTotal,
            'debtCustomersCount': uniqueCustomers,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          };

          await firestore
              .collection('users')
              .doc(uid)
              .collection('summaries')
              .doc(SummaryHelper.getAllTimeKey())
              .set(summaryData, SetOptions(merge: true));

          return summaryData;
        }

        return {'totalDebts': 0.0, 'unpaidDebts': 0.0, 'debtCustomersCount': 0};
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch debt summary: $e');
    }
  }
}

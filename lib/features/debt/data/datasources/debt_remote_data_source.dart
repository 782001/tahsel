import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../models/debt_model.dart';
import '../models/payment_model.dart';
import '../../domain/entities/payment_entity.dart';

abstract class DebtRemoteDataSource {
  Future<String> addDebt(DebtModel debt);
  Future<List<DebtModel>> getDebts(String uid);
  Future<void> payDebt(DebtModel debt, PaymentModel payment);
  Future<void> payTotalDebt(String uid, String customerName, double amount);
  Future<void> markCustomerAsPaid(String uid, String customerName);
  Future<void> deleteCustomerDebts(String uid, String customerName);
  Future<void> deleteDebtItem(String uid, String debtId);
  Stream<List<PaymentModel>> getDebtTransactions(String debtId);
  Future<List<PaymentModel>> getDebtTransactionsFuture(String debtId);
  Future<List<PaymentModel>> getCustomerAllPayments(String uid, String customerName);
  Stream<List<DebtModel>> getDebtsStream(String uid);
}

class DebtRemoteDataSourceImpl implements DebtRemoteDataSource {
  final FirebaseFirestore firestore;

  DebtRemoteDataSourceImpl({required this.firestore});

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
      final initialPaymentRef = debtRef.collection('payments').doc('${debt.operationId}_initial');
      batch.set(initialPaymentRef, {
        'debtId': debt.operationId,
        'amountPaid': debt.totalAmount, // Debt amount
        'remainingAmount': debt.totalAmount, // Before payment applied
        'createdAt': debt.timestamp != null 
            ? Timestamp.fromDate(debt.timestamp!) 
            : FieldValue.serverTimestamp(),
        'type': PaymentType.debtAdded.name,
      });

      // 4. Add initial payment transaction if there was a payment
      if (debt.paidAmount > 0) {
        final actualPaymentRef = debtRef.collection('payments').doc('${debt.operationId}_payment');
        batch.set(actualPaymentRef, {
          'debtId': debt.operationId,
          'amountPaid': debt.paidAmount,
          'remainingAmount': debt.remainingAmount,
          'createdAt': debt.timestamp != null 
              ? Timestamp.fromDate(debt.timestamp!.add(const Duration(milliseconds: 1))) 
              : FieldValue.serverTimestamp(),
          'type': debt.remainingAmount <= 0 ? PaymentType.full.name : PaymentType.partial.name,
        });
      }

      await batch.commit();
      return debtRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to add debt: $e');
    }
  }

  @override
  Future<List<DebtModel>> getDebts(String uid) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => DebtModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch debts: $e');
    }
  }

  @override
  Future<void> payDebt(DebtModel debt, PaymentModel payment) async {
    try {
      final uid = debt.uid;
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .doc(debt.id);

      final paymentRef = debtRef.collection('payments').doc();

      final batch = firestore.batch();

      var debtData = debt.toJson();
      debtData['lastUpdatedAt'] = FieldValue.serverTimestamp();
      batch.update(debtRef, debtData);
      batch.set(paymentRef, payment.toJson());

      // Update the operation record to keep reports consistent
      if (debt.operationId.isNotEmpty) {
        final opRef = firestore
            .collection('users')
            .doc(uid)
            .collection('operations')
            .doc(debt.operationId);
        batch.update(opRef, {
          'paidAmount': debt.paidAmount,
          'remainingDebt': debt.remainingAmount, 
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to record payment: $e');
    }
  }

  @override
  Future<void> payTotalDebt(String uid, String customerName, double amount) async {
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

      final batch = firestore.batch();
      double remainingToPay = amount;

      for (var doc in snapshot.docs) {
        if (remainingToPay <= 0) break;

        final debtData = doc.data();
        final debtId = doc.id;
        final operationId = debtData['operationId'] as String?;
        final currentTotal = (debtData['totalAmount'] as num).toDouble();
        final currentPaid = (debtData['paidAmount'] as num).toDouble();
        final currentRemaining = (debtData['remainingAmount'] as num).toDouble();

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
        final isPaid = newRemainingAmount <= 0;

        final debtRef = firestore
            .collection('users')
            .doc(uid)
            .collection('debts')
            .doc(debtId);

        batch.update(debtRef, {
          'paidAmount': newPaidAmount,
          'remainingAmount': newRemainingAmount,
          'isPaid': isPaid,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Also update the linked operation record for real-time consistency in Reports
        if (operationId != null && operationId.isNotEmpty) {
          batch.update(
            firestore.collection('users').doc(uid).collection('operations').doc(operationId),
            {
              'paidAmount': newPaidAmount,
              'remainingDebt': newRemainingAmount, 
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
          );
        }

        // Add payment record to sub-collection
        final paymentRef = debtRef.collection('payments').doc();
        batch.set(paymentRef, {
          'debtId': debtId,
          'amountPaid': paymentForThisItem,
          'remainingAmount': newRemainingAmount,
          'createdAt': FieldValue.serverTimestamp(),
          'type': isPaid ? PaymentType.full.name : PaymentType.partial.name,
        });
      }

      await batch.commit();
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

      final batch = firestore.batch();

      for (var doc in snapshot.docs) {
        final debtData = doc.data();
        final debtId = doc.id;
        final operationId = debtData['operationId'] as String?;
        final currentTotal = (debtData['totalAmount'] as num).toDouble();

        final debtRef = firestore
            .collection('users')
            .doc(uid)
            .collection('debts')
            .doc(debtId);

        batch.update(debtRef, {
          'paidAmount': currentTotal,
          'remainingAmount': 0.0,
          'isPaid': true,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Sync with operations for Report accuracy
        if (operationId != null && operationId.isNotEmpty) {
          batch.update(
            firestore.collection('users').doc(uid).collection('operations').doc(operationId),
            {
              'paidAmount': currentTotal,
              'remainingDebt': 0.0, 
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
          );
        }

        // Add payment record to sub-collection
        final paymentRef = debtRef.collection('payments').doc();
        batch.set(paymentRef, {
          'debtId': debtId,
          'amountPaid': currentTotal - (debtData['paidAmount'] as num).toDouble(),
          'remainingAmount': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'type': PaymentType.settlement.name,
        });
      }

      await batch.commit();
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

      // Firestore batch limit is 500 writes, so we chunk
      final List<DocumentReference> allRefs = [];

      for (var doc in snapshot.docs) {
        // Collect payment sub-collection docs
        final paymentsSnapshot =
            await doc.reference.collection('payments').get();
        for (var paymentDoc in paymentsSnapshot.docs) {
          allRefs.add(paymentDoc.reference);
        }
        // Add the debt doc itself
        allRefs.add(doc.reference);
      }

      // Batch delete in chunks of 500
      for (var i = 0; i < allRefs.length; i += 500) {
        final chunk = allRefs.sublist(
          i,
          i + 500 > allRefs.length ? allRefs.length : i + 500,
        );
        final batch = firestore.batch();
        for (var ref in chunk) {
          batch.delete(ref);
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

      final paymentsSnapshot = await debtRef.collection('payments').get();
      
      final List<DocumentReference> allRefs = [];
      for (var paymentDoc in paymentsSnapshot.docs) {
        allRefs.add(paymentDoc.reference);
      }
      allRefs.add(debtRef);

      // Batch delete in chunks of 500
      for (var i = 0; i < allRefs.length; i += 500) {
        final chunk = allRefs.sublist(
          i,
          i + 500 > allRefs.length ? allRefs.length : i + 500,
        );
        final batch = firestore.batch();
        for (var ref in chunk) {
          batch.delete(ref);
        }
        await batch.commit();
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to delete debt item: $e');
    }
  }

  @override
  Stream<List<PaymentModel>> getDebtTransactions(String debtId) {
    // This is more complex because we need the UID to find the debt
    // But usually we can find it by searching all users or by passing the UID
    // However, looking at the structure, debts are under users/{uid}/debts/{debtId}
    // We need to know which user this debt belongs to.
    // Let's assume we can use a collectionGroup or pass the path.
    // For now, I'll use collectionGroup for 'payments' and filter by 'debtId'
    // which is safe if debtId is unique (which doc().id is).
    
    return firestore
        .collectionGroup('payments')
        .where('debtId', isEqualTo: debtId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<PaymentModel>> getDebtTransactionsFuture(String debtId) async {
    try {
      final snapshot = await firestore
          .collectionGroup('payments')
          .where('debtId', isEqualTo: debtId)
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
  Future<List<PaymentModel>> getCustomerAllPayments(String uid, String customerName) async {
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
  Stream<List<DebtModel>> getDebtsStream(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('debts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DebtModel.fromJson(doc.data(), doc.id))
            .toList());
  }
}

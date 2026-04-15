import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../models/debt_model.dart';
import '../models/payment_model.dart';

abstract class DebtRemoteDataSource {
  Future<String> addDebt(DebtModel debt);
  Future<List<DebtModel>> getDebts(String uid);
  Future<void> payDebt(DebtModel debt, PaymentModel payment);
  Future<void> payTotalDebt(String uid, String customerName, double amount);
  Future<void> markCustomerAsPaid(String uid, String customerName);
  Future<void> deleteCustomerDebts(String uid, String customerName);
}

class DebtRemoteDataSourceImpl implements DebtRemoteDataSource {
  final FirebaseFirestore firestore;

  DebtRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String> addDebt(DebtModel debt) async {
    try {
      final docRef = firestore
          .collection('users')
          .doc(debt.uid)
          .collection('debts')
          .doc();
          
      await docRef.set(debt.toJson());
      return docRef.id;
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
      final debtRef = firestore
          .collection('users')
          .doc(debt.uid)
          .collection('debts')
          .doc(debt.id);

      final paymentRef = debtRef.collection('payments').doc();

      final batch = firestore.batch();

      batch.update(debtRef, debt.toJson());
      batch.set(paymentRef, payment.toJson());

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
        });

        // Add payment record to sub-collection
        final paymentRef = debtRef.collection('payments').doc();
        batch.set(paymentRef, {
          'debtId': debtId,
          'amountPaid': paymentForThisItem,
          'remainingAfterPayment': newRemainingAmount,
          'paymentDate': FieldValue.serverTimestamp(),
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
        });

        // Add payment record to sub-collection
        final paymentRef = debtRef.collection('payments').doc();
        batch.set(paymentRef, {
          'debtId': debtId,
          'amountPaid': currentTotal - (debtData['paidAmount'] as num).toDouble(),
          'remainingAfterPayment': 0.0,
          'paymentDate': FieldValue.serverTimestamp(),
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

      // Also delete linked operations
      final operationIds = snapshot.docs
          .map((doc) => doc.data()['operationId'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      for (var opId in operationIds) {
        final opRef = firestore
            .collection('users')
            .doc(uid)
            .collection('operations')
            .doc(opId);
        allRefs.add(opRef);
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
}

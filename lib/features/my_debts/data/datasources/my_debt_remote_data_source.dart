import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_model.dart';

abstract class MyDebtRemoteDataSource {
  Future<List<MyDebtModel>> getMyDebts();
  Future<void> addMyDebt(MyDebtModel debt, MyDebtTransactionModel transaction);
  Future<void> addMyDebtTransaction(MyDebtTransactionModel transaction);
  Future<List<MyDebtTransactionModel>> getMyDebtTransactions(String debtId);
  Future<void> deleteMyDebt(String debtId);
  Future<void> updateMyDebt(MyDebtModel debt);
}

class MyDebtRemoteDataSourceImpl implements MyDebtRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  MyDebtRemoteDataSourceImpl({required this.firestore, required this.auth});

  String get userId => auth.currentUser?.uid ?? '';
  CollectionReference get myDebtsCollection =>
      firestore.collection('users').doc(userId).collection('my_debts');

  @override
  Future<List<MyDebtModel>> getMyDebts() async {
    final snapshot = await myDebtsCollection.orderBy('lastTransactionDate', descending: true).get();
    return snapshot.docs.map((doc) => MyDebtModel.fromSnapshot(doc)).toList();
  }

  @override
  Future<void> addMyDebt(MyDebtModel debt, MyDebtTransactionModel transaction) async {
    final batch = firestore.batch();
    
    final debtDoc = myDebtsCollection.doc(debt.id);
    batch.set(debtDoc, debt.toMap());
    
    final transactionDoc = debtDoc.collection('transactions').doc(transaction.id);
    batch.set(transactionDoc, transaction.toMap());
    
    if (debt.paidAmount > 0) {
      final paymentDoc = debtDoc.collection('transactions').doc();
      final paymentTransaction = MyDebtTransactionModel(
        id: paymentDoc.id,
        debtId: debt.id,
        amount: debt.paidAmount,
        type: 'payment',
        note: 'Initial payment',
        date: transaction.date.add(const Duration(milliseconds: 1)),
      );
      batch.set(paymentDoc, paymentTransaction.toMap());
    }
    
    await batch.commit();
  }

  @override
  Future<void> addMyDebtTransaction(MyDebtTransactionModel transaction) async {
    final batch = firestore.batch();
    
    final debtDoc = myDebtsCollection.doc(transaction.debtId);
    final transactionDoc = debtDoc.collection('transactions').doc();
    
    batch.set(transactionDoc, transaction.toMap());
    
    // Update main debt document
    final debtSnapshot = await debtDoc.get();
    if (debtSnapshot.exists) {
      final data = debtSnapshot.data() as Map<String, dynamic>;
      double totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
      double paidAmount = (data['paidAmount'] ?? 0.0).toDouble();
      
      if (transaction.type == 'payment') {
        paidAmount += transaction.amount;
      } else {
        totalAmount += transaction.amount;
      }
      
      batch.update(debtDoc, {
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingDebt': totalAmount - paidAmount,
        'lastTransactionDate': Timestamp.fromDate(transaction.date),
      });
    }
    
    await batch.commit();
  }

  @override
  Future<List<MyDebtTransactionModel>> getMyDebtTransactions(String debtId) async {
    final snapshot = await myDebtsCollection
        .doc(debtId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => MyDebtTransactionModel.fromSnapshot(doc)).toList();
  }

  @override
  Future<void> deleteMyDebt(String debtId) async {
    await myDebtsCollection.doc(debtId).delete();
  }

  @override
  Future<void> updateMyDebt(MyDebtModel debt) async {
    await myDebtsCollection.doc(debt.id).update(debt.toMap());
  }
}

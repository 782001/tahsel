import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';

abstract class DebtRemoteDataSource {
  Future<String> addDebt(DebtModel debt);
  Future<List<DebtModel>> getDebts(String uid);
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
      throw Exception('Failed to fetch debts: $e');
    }
  }
}

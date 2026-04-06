import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';

abstract class DebtRemoteDataSource {
  Future<String> addDebt(DebtModel debt);
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
}

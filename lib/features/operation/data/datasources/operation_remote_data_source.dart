import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/operation_model.dart';

abstract class OperationRemoteDataSource {
  Future<void> addOperation(OperationModel operation);
}

class OperationRemoteDataSourceImpl implements OperationRemoteDataSource {
  final FirebaseFirestore firestore;

  OperationRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> addOperation(OperationModel operation) async {
    try {
      final docRef = firestore
          .collection('users')
          .doc(operation.uid)
          .collection('operations')
          .doc();
      
      await docRef.set(operation.toJson());
    } catch (e) {
      throw Exception('Failed to add operation: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../models/operation_model.dart';

abstract class OperationRemoteDataSource {
  Future<String> addOperation(OperationModel operation);
}

class OperationRemoteDataSourceImpl implements OperationRemoteDataSource {
  final FirebaseFirestore firestore;

  OperationRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String> addOperation(OperationModel operation) async {
    try {
      final collectionRef = firestore
          .collection('users')
          .doc(operation.uid)
          .collection('operations');

      final docRef = (operation.id != null && operation.id!.isNotEmpty)
          ? collectionRef.doc(operation.id)
          : collectionRef.doc();

      await docRef.set(operation.toJson());
      return docRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to add operation: $e');
    }
  }
}

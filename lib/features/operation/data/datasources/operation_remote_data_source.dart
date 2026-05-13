import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/summary_helper.dart';
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
      final userRef = firestore.collection('users').doc(operation.uid);
      final collectionRef = userRef.collection('operations');

      final docRef = (operation.id != null && operation.id!.isNotEmpty)
          ? collectionRef.doc(operation.id)
          : collectionRef.doc();

      final batch = firestore.batch();

      // 1. Set the operation document
      batch.set(docRef, operation.toJson());

      // 2. Update Summaries (Daily, Weekly, Monthly, All-Time)
      final timestamp = operation.timestamp ?? DateTime.now();
      final summaryKeys = SummaryHelper.getSummaryKeys(timestamp);

      final type = operation.type.toLowerCase();
      final isShop = type == AppStrings.shop.toLowerCase();
      final isPS = type == AppStrings.playStation.toLowerCase();

      for (final key in summaryKeys) {
        final summaryRef = userRef.collection('summaries').doc(key);
        batch.set(
          summaryRef,
          {
            'totalIncome': FieldValue.increment(operation.totalAmount),
            if (isShop) 'cafeIncome': FieldValue.increment(operation.totalAmount),
            if (isPS)
              'playstationIncome': FieldValue.increment(operation.totalAmount),
            'transactionCount': FieldValue.increment(1),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      return docRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to add operation: $e');
    }
  }
}

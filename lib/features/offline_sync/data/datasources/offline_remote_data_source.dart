import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/offline_record.dart';

abstract class OfflineRemoteDataSource {
  Future<void> syncRecord(OfflineRecord record);
}

class OfflineRemoteDataSourceImpl implements OfflineRemoteDataSource {
  final FirebaseFirestore firestore;

  OfflineRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> syncRecord(OfflineRecord record) async {
    final collectionRef = firestore.collection(record.collectionName);
    
    // Parse the stored JSON payload
    final payload = jsonDecode(record.payloadJson) as Map<String, dynamic>;
    
    // Timestamp adjustment since Hive stores it as string/number usually, standard Firebase uses FieldValue.serverTimestamp()
    // It's safer to use server timestamps correctly for consistency
    if (payload.containsKey('timestamp')) {
       payload['timestamp'] = FieldValue.serverTimestamp();
    }
    if (payload.containsKey('createdAt')) {
       payload['createdAt'] = FieldValue.serverTimestamp();
    }

    // Attempt to upload without replacing id (we generate on device, so we use it as document id)
    await collectionRef.doc(record.id).set(payload, SetOptions(merge: true));
  }
}

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
    
    // Convert string dates back to Timestamps for Firestore
    if (payload['createdAt'] is String) {
       payload['createdAt'] = Timestamp.fromDate(DateTime.parse(payload['createdAt']));
    }
    
    // Use server timestamp only for system-level tracking if needed (optional)
    // but keep original transaction date as createdAt
    payload['syncedAt'] = FieldValue.serverTimestamp();

    // Attempt to upload without replacing id (we generate on device, so we use it as document id)
    await collectionRef.doc(record.id).set(payload, SetOptions(merge: true));
  }
}

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
    // This Handles both 'expenses' (createdAt) and 'operations' (timestamp)
    if (payload['createdAt'] is String) {
      payload['createdAt'] =
          Timestamp.fromDate(DateTime.parse(payload['createdAt']));
    }

    if (payload['timestamp'] is String) {
      payload['timestamp'] =
          Timestamp.fromDate(DateTime.parse(payload['timestamp']));
    } else if (payload['timestamp'] == null) {
      // If timestamp was explicitly nulled for sync-time generation
      payload['timestamp'] = FieldValue.serverTimestamp();
    }

    // Add sync metadata
    payload['syncedAt'] = FieldValue.serverTimestamp();

    // Attempt to upload using the device-generated ID
    await collectionRef.doc(record.id).set(payload, SetOptions(merge: true));
  }
}

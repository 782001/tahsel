import 'package:hive/hive.dart';

part 'offline_record.g.dart';

@HiveType(typeId: 0)
class OfflineRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String customerName;

  @HiveField(4)
  final String type; // "cafe", "playstation", "expense"

  @HiveField(5)
  bool isSynced;

  @HiveField(6)
  final String payloadJson; // Full JSON payload to send to Firebase

  @HiveField(7)
  final String collectionName; // Target Firestore collection

  OfflineRecord({
    required this.id,
    required this.amount,
    required this.date,
    required this.customerName,
    required this.type,
    this.isSynced = false,
    required this.payloadJson,
    required this.collectionName,
  });
}

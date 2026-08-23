import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vault_summary_entity.dart';

class VaultSummaryModel extends VaultSummaryEntity {
  const VaultSummaryModel({
    required super.currentBalance,
    super.totalIn = 0.0,
    super.totalOut = 0.0,
    super.transactionCount = 0,
    super.lastUpdatedAt,
  });

  factory VaultSummaryModel.fromMap(Map<String, dynamic> map) {
    DateTime? lastUpdated;
    final rawDate = map['lastUpdatedAt'];
    if (rawDate is Timestamp) {
      lastUpdated = rawDate.toDate();
    } else if (rawDate is int) {
      lastUpdated = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    return VaultSummaryModel(
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      totalIn: (map['totalIn'] as num?)?.toDouble() ?? 0.0,
      totalOut: (map['totalOut'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (map['transactionCount'] as num?)?.toInt() ?? 0,
      lastUpdatedAt: lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentBalance': currentBalance,
      'totalIn': totalIn,
      'totalOut': totalOut,
      'transactionCount': transactionCount,
      'lastUpdatedAt': lastUpdatedAt != null
          ? Timestamp.fromDate(lastUpdatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class SummaryModel {
  final double totalIncome;
  final double cafeIncome;
  final double playstationIncome;
  final double totalExpenses;
  final double totalDebts;
  final double paidDebts;
  final double unpaidDebts;
  final int transactionCount;
  final int cafeCount;
  final int playstationCount;
  final int debtCustomersCount;
  final bool isSynced;
  final DateTime lastUpdatedAt;

  SummaryModel({
    required this.totalIncome,
    required this.cafeIncome,
    required this.playstationIncome,
    required this.totalExpenses,
    required this.totalDebts,
    required this.paidDebts,
    required this.unpaidDebts,
    required this.transactionCount,
    this.cafeCount = 0,
    this.playstationCount = 0,
    this.debtCustomersCount = 0,
    this.isSynced = false,
    required this.lastUpdatedAt,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      cafeIncome: (json['cafeIncome'] ?? 0).toDouble(),
      playstationIncome: (json['playstationIncome'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      totalDebts: (json['totalDebts'] ?? 0).toDouble(),
      paidDebts: (json['paidDebts'] ?? 0).toDouble(),
      unpaidDebts: (json['unpaidDebts'] ?? 0).toDouble(),
      transactionCount: (json['transactionCount'] ?? 0).toInt(),
      cafeCount: (json['cafeCount'] ?? 0).toInt(),
      playstationCount: (json['playstationCount'] ?? 0).toInt(),
      debtCustomersCount: (json['debtCustomersCount'] ?? 0).toInt(),
      isSynced: json['isSynced'] as bool? ?? false,
      lastUpdatedAt:
          (json['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory SummaryModel.empty([String? key]) {
    return SummaryModel(
      totalIncome: 0,
      cafeIncome: 0,
      playstationIncome: 0,
      totalExpenses: 0,
      totalDebts: 0,
      paidDebts: 0,
      unpaidDebts: 0,
      transactionCount: 0,
      cafeCount: 0,
      playstationCount: 0,
      debtCustomersCount: 0,
      isSynced: false,
      lastUpdatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'cafeIncome': cafeIncome,
      'playstationIncome': playstationIncome,
      'totalExpenses': totalExpenses,
      'totalDebts': totalDebts,
      'paidDebts': paidDebts,
      'unpaidDebts': unpaidDebts,
      'transactionCount': transactionCount,
      'cafeCount': cafeCount,
      'playstationCount': playstationCount,
      'debtCustomersCount': debtCustomersCount,
      'isSynced': isSynced,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  SummaryModel copyWith({
    double? totalIncome,
    double? cafeIncome,
    double? playstationIncome,
    double? totalExpenses,
    double? totalDebts,
    double? paidDebts,
    double? unpaidDebts,
    int? transactionCount,
    int? cafeCount,
    int? playstationCount,
    bool? isSynced,
    DateTime? lastUpdatedAt,
  }) {
    return SummaryModel(
      totalIncome: totalIncome ?? this.totalIncome,
      cafeIncome: cafeIncome ?? this.cafeIncome,
      playstationIncome: playstationIncome ?? this.playstationIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalDebts: totalDebts ?? this.totalDebts,
      paidDebts: paidDebts ?? this.paidDebts,
      unpaidDebts: unpaidDebts ?? this.unpaidDebts,
      transactionCount: transactionCount ?? this.transactionCount,
      cafeCount: cafeCount ?? this.cafeCount,
      playstationCount: playstationCount ?? this.playstationCount,
      debtCustomersCount: debtCustomersCount,
      isSynced: isSynced ?? this.isSynced,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

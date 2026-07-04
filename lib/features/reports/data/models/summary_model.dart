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

  // New: Invoice fields
  final int invoiceCount;
  final double invoiceValue;
  final double invoiceCollected;
  final double invoiceRemaining;
  final int invoicePaidCount;
  final int invoicePartialCount;
  final int invoiceUnpaidCount;

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
    this.invoiceCount = 0,
    this.invoiceValue = 0,
    this.invoiceCollected = 0,
    this.invoiceRemaining = 0,
    this.invoicePaidCount = 0,
    this.invoicePartialCount = 0,
    this.invoiceUnpaidCount = 0,
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
      invoiceCount: (json['invoiceCount'] ?? 0).toInt(),
      invoiceValue: (json['invoiceValue'] ?? 0).toDouble(),
      invoiceCollected: (json['invoiceCollected'] ?? 0).toDouble(),
      invoiceRemaining: (json['invoiceRemaining'] ?? 0).toDouble(),
      invoicePaidCount: (json['invoicePaidCount'] ?? 0).toInt(),
      invoicePartialCount: (json['invoicePartialCount'] ?? 0).toInt(),
      invoiceUnpaidCount: (json['invoiceUnpaidCount'] ?? 0).toInt(),
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
      invoiceCount: 0,
      invoiceValue: 0,
      invoiceCollected: 0,
      invoiceRemaining: 0,
      invoicePaidCount: 0,
      invoicePartialCount: 0,
      invoiceUnpaidCount: 0,
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
      'invoiceCount': invoiceCount,
      'invoiceValue': invoiceValue,
      'invoiceCollected': invoiceCollected,
      'invoiceRemaining': invoiceRemaining,
      'invoicePaidCount': invoicePaidCount,
      'invoicePartialCount': invoicePartialCount,
      'invoiceUnpaidCount': invoiceUnpaidCount,
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
    int? invoiceCount,
    double? invoiceValue,
    double? invoiceCollected,
    double? invoiceRemaining,
    int? invoicePaidCount,
    int? invoicePartialCount,
    int? invoiceUnpaidCount,
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
      invoiceCount: invoiceCount ?? this.invoiceCount,
      invoiceValue: invoiceValue ?? this.invoiceValue,
      invoiceCollected: invoiceCollected ?? this.invoiceCollected,
      invoiceRemaining: invoiceRemaining ?? this.invoiceRemaining,
      invoicePaidCount: invoicePaidCount ?? this.invoicePaidCount,
      invoicePartialCount: invoicePartialCount ?? this.invoicePartialCount,
      invoiceUnpaidCount: invoiceUnpaidCount ?? this.invoiceUnpaidCount,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/summary_helper.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../models/summary_model.dart';

abstract class ReportsRemoteDataSource {
  Future<Map<String, double>> getPeriodData(
    DateTime start,
    DateTime end,
    String periodKey,
  );
  Future<Map<String, double>> getAllTimeData();
  Future<List<Map<String, dynamic>>> getIncomeDetails(
    DateTime start,
    DateTime end, {
    String? type,
  });
  Future<int> cleanupOldReports();
  Future<SummaryModel> getSummary(String uid, String key);
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final FirebaseFirestore firestore;

  ReportsRemoteDataSourceImpl(this.firestore);

  @override
  Future<SummaryModel> getSummary(String uid, String key) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('summaries')
          .doc(key)
          .get();

      if (doc.exists) {
        return SummaryModel.fromJson(doc.data()!);
      } else {
        return SummaryModel.empty(key);
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch summary: $e');
    }
  }

  @override
  Future<Map<String, double>> getPeriodData(
    DateTime start,
    DateTime end,
    String periodKey,
  ) async {
    try {
      final uid = AppStrings.userToken;
      if (uid.isEmpty) return {};

      // 1. Try to get from summaries first
      final summaryKey = _getSummaryKey(periodKey, start);
      final summary = await getSummary(uid, summaryKey);

      // If summary has data, return it
      if (summary.transactionCount > 0 || summary.totalExpenses > 0) {
        return {
          'totalIncome': summary.totalIncome,
          'cafeIncome': summary.cafeIncome,
          'playstationIncome': summary.playstationIncome,
          'totalExpenses': summary.totalExpenses,
          'totalDebts': summary.totalDebts,
          'paidDebts': summary.paidDebts,
          'unpaidDebts': summary.unpaidDebts,
        };
      }

      // 2. Fallback to old calculation if no summary found (e.g. legacy data)
      final startTimestamp = Timestamp.fromDate(start);
      final endTimestamp = Timestamp.fromDate(end);

      // Fetch Operations
      final operationsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('operations')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThan: endTimestamp)
          .get();

      double totalIncome = 0;
      double cafeIncome = 0;
      double playstationIncome = 0;

      for (var doc in operationsSnapshot.docs) {
        final data = doc.data();
        final double totalAmount = (data['totalAmount'] ?? 0).toDouble();
        final type = (data['type'] ?? '').toString().toLowerCase();

        totalIncome += totalAmount;
        if (type == AppStrings.shop.toLowerCase() || type == 'cafe') {
          cafeIncome += totalAmount;
        } else if (type == AppStrings.playStation.toLowerCase() || type == 'playstation') {
          playstationIncome += totalAmount;
        }
      }

      // Fetch Expenses
      final expensesSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThan: endTimestamp)
          .get();

      double totalExpenses = 0;
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        totalExpenses += (data['amount'] ?? 0).toDouble();
      }

      // Fetch Debts
      final debtsSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThan: endTimestamp)
          .get();

      double totalDebts = 0;
      double paidDebts = 0;
      double unpaidDebts = 0;

      for (var doc in debtsSnapshot.docs) {
        final data = doc.data();
        final double remaining = (data['remainingAmount'] ?? 0).toDouble();
        final double total = (data['totalAmount'] ?? 0).toDouble();

        totalDebts += remaining;
        if (remaining == 0) {
          paidDebts += total;
        } else {
          unpaidDebts += remaining;
        }
      }

      final result = {
        'totalIncome': totalIncome,
        'cafeIncome': cafeIncome,
        'playstationIncome': playstationIncome,
        'totalExpenses': totalExpenses,
        'totalDebts': totalDebts,
        'paidDebts': paidDebts,
        'unpaidDebts': unpaidDebts,
      };

      // 3. AUTO-CACHE: Save the calculated summary to Firestore for future O(1) access
      // This migrates legacy data on-the-fly to the optimized format
      try {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('summaries')
            .doc(summaryKey)
            .set({
          ...result,
          'transactionCount':
              operationsSnapshot.docs.length + expensesSnapshot.docs.length,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Log error but don't fail the report view
        AppLogger.printMessage('Failed to auto-cache summary: $e');
      }

      return result;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch period data: $e');
    }
  }

  @override
  Future<Map<String, double>> getAllTimeData() async {
    try {
      final uid = AppStrings.userToken;
      if (uid.isEmpty) return {};

      // Try summary first
      final summary = await getSummary(uid, SummaryHelper.getAllTimeKey());
      if (summary.transactionCount > 0 || summary.totalExpenses > 0) {
        return {
          'totalIncome': summary.totalIncome,
          'cafeIncome': summary.cafeIncome,
          'playstationIncome': summary.playstationIncome,
          'totalExpenses': summary.totalExpenses,
          'totalDebts': summary.totalDebts,
          'paidDebts': summary.paidDebts,
          'unpaidDebts': summary.unpaidDebts,
        };
      }

      // Fallback (expensive!)
      // For brevity, I'll just use a very wide range or just sum all docs
      // But in production, we should really have the all_time summary.
      // I'll implement a basic fallback by calling getPeriodData with a wide range
      return getPeriodData(
        DateTime(2020, 1, 1),
        DateTime(2100, 1, 1),
        'all_time',
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch all-time data: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getIncomeDetails(
    DateTime start,
    DateTime end, {
    String? type,
  }) async {
    try {
      final uid = AppStrings.userToken;
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('operations')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch income details: $e');
    }
  }

  @override
  Future<int> cleanupOldReports() async {
    // Implementation not required for this optimization
    return 0;
  }

  String _getSummaryKey(String period, DateTime date) {
    switch (period.toLowerCase()) {
      case 'daily':
        return SummaryHelper.getDailyKey(date);
      case 'weekly':
        return SummaryHelper.getWeeklyKey(date);
      case 'monthly':
        return SummaryHelper.getMonthlyKey(date);
      case 'alltime':
      case 'all_time':
        return SummaryHelper.getAllTimeKey();
      default:
        return SummaryHelper.getDailyKey(date);
    }
  }
}

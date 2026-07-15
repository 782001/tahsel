import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/summary_helper.dart';

import '../../../../core/error/firebase_error_handler.dart';
import '../models/summary_model.dart';

abstract class ReportsRemoteDataSource {
  Future<Map<String, dynamic>> getPeriodData(
    DateTime start,
    DateTime end,
    String periodKey, {
    bool forceRefresh = false,
  });
  Future<Map<String, dynamic>> getAllTimeData({bool forceRefresh = false});
  Future<List<Map<String, dynamic>>> getIncomeDetails(
    DateTime start,
    DateTime end, {
    String? type,
    int limit = 15,
    DocumentSnapshot? lastDoc,
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
  Future<Map<String, dynamic>> getPeriodData(
    DateTime start,
    DateTime end,
    String periodKey, {
    bool forceRefresh = false,
  }) async {
    try {
      final uid = AppStrings.userToken;
      if (uid.isEmpty) return {};

      final summaryKey = _getSummaryKey(periodKey, start);

      // We only use the summary if the requested start date aligns with the period start
      bool isPeriodStart = false;
      if (periodKey == 'daily') {
        isPeriodStart = start.hour == 0 && start.minute == 0;
      } else if (periodKey == 'monthly') {
        isPeriodStart = start.day == 1;
      } else if (periodKey == 'weekly') {
        isPeriodStart = true;
      } else if (periodKey == 'all_time' || periodKey == 'allTime') {
        isPeriodStart = true;
      }

      // 1. Try Optimized Summary Cache First
      if (isPeriodStart && !forceRefresh) {
        final summary = await getSummary(uid, summaryKey);

        // If summary has been fully synced/calculated, return it
        if (summary.isSynced) {
          return {
            'totalIncome': summary.totalIncome,
            'cafeIncome': summary.cafeIncome,
            'playstationIncome': summary.playstationIncome,
            'totalExpenses': summary.totalExpenses,
            'totalDebts': summary.totalDebts,
            'paidDebts': summary.paidDebts,
            'unpaidDebts': summary.unpaidDebts,
            'totalCount': summary.transactionCount.toDouble(),
            'cafeCount': summary.cafeCount.toDouble(),
            'playstationCount': summary.playstationCount.toDouble(),
            'debtCustomersCount': summary.debtCustomersCount.toDouble(),
            'invoiceCount': summary.invoiceCount,
            'invoiceValue': summary.invoiceValue,
            'invoiceCollected': summary.invoiceCollected,
            'invoiceRemaining': summary.invoiceRemaining,
            'invoicePaidCount': summary.invoicePaidCount,
            'invoicePartialCount': summary.invoicePartialCount,
            'invoiceUnpaidCount': summary.invoiceUnpaidCount,
          };
        }
      }

      // 2. Fallback to manual calculation if no summary found or forceRefresh is true
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
      int totalCount = 0;
      int cafeCount = 0;
      int playstationCount = 0;

      for (var doc in operationsSnapshot.docs) {
        final data = doc.data();
        final double totalAmount = (data['totalAmount'] ?? 0).toDouble();
        final type = (data['type'] ?? '').toString().toLowerCase();

        // Skip invoice-linked debt operations — their financials are already
        // aggregated from the authoritative `invoices` collection below.
        // Counting them here would double the reported income and inflate
        // the transaction count.
        if (type == 'invoice_debt') continue;

        totalCount++;
        totalIncome += totalAmount;
        if (type == AppStrings.shop.toLowerCase() || type == 'cafe') {
          cafeIncome += totalAmount;
          cafeCount++;
        } else if (type == AppStrings.playStation.toLowerCase() ||
            type == 'playstation') {
          playstationIncome += totalAmount;
          playstationCount++;
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

      // Fetch Invoices
      final invoicesSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('invoices')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThan: endTimestamp)
          .get();

      double invoiceIncome = 0;
      double invoiceTotalDebts = 0;
      double invoicePaidDebts = 0;
      double invoiceUnpaidDebts = 0;
      int invoiceCount = invoicesSnapshot.docs.length;

      double invoiceValue = 0;
      double invoiceCollected = 0;
      double invoiceRemaining = 0;
      int invoicePaidCount = 0;
      int invoicePartialCount = 0;
      int invoiceUnpaidCount = 0;

      for (var doc in invoicesSnapshot.docs) {
        final data = doc.data();
        final statusStr = data['status'] as String? ?? 'pending';
        if (statusStr == 'voided') {
          invoiceCount--;
          continue;
        }

        // Parse payments
        final payments = data['payments'] as List<dynamic>? ?? [];
        final double totalPaid = payments.fold<double>(
          0.0,
          (acc, p) => acc + (p['amount'] as num? ?? 0).toDouble(),
        );

        // Parse items to calculate total amount
        final items = data['items'] as List<dynamic>? ?? [];
        final double totalAmount = items.fold<double>(0.0, (acc, i) {
          final double unitPrice = (i['unitPrice'] as num? ?? 0).toDouble();
          final double quantity = (i['quantity'] as num? ?? 0).toDouble();
          final double taxRate = (i['taxRate'] as num? ?? 0).toDouble();
          final double discountRate = (i['discountRate'] as num? ?? 0)
              .toDouble();
          final double subtotal = unitPrice * quantity;
          final double discountAmount = subtotal * discountRate;
          final double taxAmount = (subtotal - discountAmount) * taxRate;
          return acc + (subtotal - discountAmount + taxAmount);
        });

        final double remaining = totalAmount - totalPaid;
        final double finalRemaining = remaining > 0 ? remaining : 0.0;

        invoiceIncome += totalAmount;
        invoiceTotalDebts += finalRemaining;

        invoiceValue += totalAmount;
        invoiceCollected += totalPaid;
        invoiceRemaining += finalRemaining;

        if (statusStr == 'paid' || finalRemaining == 0) {
          invoicePaidDebts += totalAmount;
          invoicePaidCount++;
        } else if (statusStr == 'partiallyPaid' ||
            (totalPaid > 0 && finalRemaining > 0)) {
          invoiceUnpaidDebts += finalRemaining;
          invoicePartialCount++;
        } else {
          invoiceUnpaidDebts += finalRemaining;
          invoiceUnpaidCount++;
        }
      }

      totalIncome += invoiceIncome;
      totalCount += invoiceCount;
      totalDebts += invoiceTotalDebts;
      paidDebts += invoicePaidDebts;
      unpaidDebts += invoiceUnpaidDebts;

      final result = {
        'totalIncome': totalIncome,
        'cafeIncome': cafeIncome,
        'playstationIncome': playstationIncome,
        'totalExpenses': totalExpenses,
        'totalDebts': totalDebts,
        'paidDebts': paidDebts,
        'unpaidDebts': unpaidDebts,
        'totalCount': totalCount.toDouble(),
        'cafeCount': cafeCount.toDouble(),
        'playstationCount': playstationCount.toDouble(),
        'invoiceCount': invoiceCount,
        'invoiceValue': invoiceValue,
        'invoiceCollected': invoiceCollected,
        'invoiceRemaining': invoiceRemaining,
        'invoicePaidCount': invoicePaidCount,
        'invoicePartialCount': invoicePartialCount,
        'invoiceUnpaidCount': invoiceUnpaidCount,
      };

      // 3. AUTO-CACHE: Save the calculated summary to Firestore for future O(1) access
      if (isPeriodStart) {
        try {
          await firestore
              .collection('users')
              .doc(uid)
              .collection('summaries')
              .doc(summaryKey)
              .set({
                ...result,
                'transactionCount': totalCount,
                'cafeCount': cafeCount,
                'playstationCount': playstationCount,
                'isSynced': true,
                'lastUpdatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } catch (e) {
          AppLogger.printMessage('Failed to auto-cache summary: $e');
        }
      }

      return result;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch period data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAllTimeData({
    bool forceRefresh = false,
  }) async {
    try {
      final uid = AppStrings.userToken;
      if (uid.isEmpty) return {};

      // Try summary first
      if (!forceRefresh) {
        final summary = await getSummary(uid, SummaryHelper.getAllTimeKey());
        if (summary.isSynced) {
          return {
            'totalIncome': summary.totalIncome,
            'cafeIncome': summary.cafeIncome,
            'playstationIncome': summary.playstationIncome,
            'totalExpenses': summary.totalExpenses,
            'totalDebts': summary.totalDebts,
            'paidDebts': summary.paidDebts,
            'unpaidDebts': summary.unpaidDebts,
            'totalCount': summary.transactionCount.toDouble(),
            'cafeCount': summary.cafeCount.toDouble(),
            'playstationCount': summary.playstationCount.toDouble(),
            'invoiceCount': summary.invoiceCount,
            'invoiceValue': summary.invoiceValue,
            'invoiceCollected': summary.invoiceCollected,
            'invoiceRemaining': summary.invoiceRemaining,
            'invoicePaidCount': summary.invoicePaidCount,
            'invoicePartialCount': summary.invoicePartialCount,
            'invoiceUnpaidCount': summary.invoiceUnpaidCount,
          };
        }
      }

      // Fallback
      return await getPeriodData(
        DateTime.parse(AppStrings.creationDate),
        DateTime(2100, 1, 1),
        'all_time',
        forceRefresh: forceRefresh,
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
    int limit = 15,
    DocumentSnapshot? lastDoc,
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

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Also attach the actual document snapshot to the data map so repository can extract it
        // Note: Repository will need to handle this to get the lastDoc
        return {'data': data, 'snapshot': doc};
      }).toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch income details: $e');
    }
  }

  @override
  Future<int> cleanupOldReports() async {
    try {
      final uid = AppStrings.userToken;
      if (uid.isEmpty) return 0;

      final now = DateTime.now();
      // Sliding window: exactly 60 days back from today
      final thresholdDate = now.subtract(const Duration(days: 60));
      AppLogger.printMessage('Threshold date: $thresholdDate');
      final thresholdTimestamp = Timestamp.fromDate(thresholdDate);

      final querySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('operations')
          .where('timestamp', isLessThan: thresholdTimestamp)
          .get();

      int deletedCount = 0;
      WriteBatch batch = firestore.batch();
      int currentBatchCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final remainingDebt = (data['remainingDebt'] ?? 0).toDouble();

        // Safety check: Only delete if no remaining debt
        if (remainingDebt <= 0) {
          batch.delete(doc.reference);
          deletedCount++;
          currentBatchCount++;

          // Firestore batch limit is 500
          if (currentBatchCount >= 500) {
            await batch.commit();
            batch = firestore.batch();
            currentBatchCount = 0;
          }
        }
      }

      if (currentBatchCount > 0) {
        await batch.commit();
      }

      return deletedCount;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
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

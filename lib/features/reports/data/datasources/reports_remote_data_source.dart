import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/utils/app_strings.dart';

abstract class ReportsRemoteDataSource {
  Future<Map<String, double>> getPeriodData(DateTime start, DateTime end);
  Future<List<Map<String, dynamic>>> getIncomeDetails(
      DateTime start, DateTime end,
      {String? type});
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final FirebaseFirestore firestore;

  ReportsRemoteDataSourceImpl(this.firestore);

  @override
  Future<Map<String, double>> getPeriodData(DateTime start, DateTime end) async {
    final uid = AppStrings.userToken;
    if (uid.isEmpty) return {};

    // Convert to Timestamp for Firestore
    final startTimestamp = Timestamp.fromDate(start);
    final endTimestamp = Timestamp.fromDate(end);

    // 1. Fetch Operations Income (Revenue)
    // We fetch all operations in period and sum their totalAmount (Revenue)
    final operationsQuery = await firestore
        .collection('users')
        .doc(uid)
        .collection('operations')
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .where('timestamp', isLessThanOrEqualTo: endTimestamp)
        .get();

    double totalIncome = 0;
    double cafeIncome = 0;
    double playstationIncome = 0;

    for (var doc in operationsQuery.docs) {
      final data = doc.data();
      final double totalAmount = (data['totalAmount'] ?? 0).toDouble();
      final type = (data['type'] ?? '').toString().toLowerCase();

      totalIncome += totalAmount;
      
      // Breakdown by type (shop mapping to cafe report)
      if (type == AppStrings.shop.toLowerCase()) {
        cafeIncome += totalAmount;
      } else if (type == AppStrings.playStation.toLowerCase()) {
        playstationIncome += totalAmount;
      }
    }

    // 2. Fetch Expenses
    final expensesQuery = await firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('createdAt', isLessThanOrEqualTo: endTimestamp)
        .get();

    double totalExpenses = 0;
    for (var doc in expensesQuery.docs) {
      final double amount = (doc.data()['amount'] ?? 0).toDouble();
      totalExpenses += amount;
    }

    // 3. Fetch Debts (Global state - what customers owe CURRENTLY)
    // We fetch all unpaid or partially paid debts to show current business health
    final debtsQuery = await firestore
        .collection('users')
        .doc(uid)
        .collection('debts')
        .get();

    double totalDebts = 0;
    double paidDebtsSum = 0;
    double unpaidDebtsSum = 0;

    for (var doc in debtsQuery.docs) {
      final data = doc.data();
      totalDebts += (data['totalAmount'] ?? 0).toDouble();
      paidDebtsSum += (data['paidAmount'] ?? 0).toDouble();
      unpaidDebtsSum += (data['remainingAmount'] ?? 0).toDouble();
    }

    return {
      'income': totalIncome,
      'cafeIncome': cafeIncome,
      'playstationIncome': playstationIncome,
      'expenses': totalExpenses,
      'totalDebts': totalDebts,
      'paidDebts': paidDebtsSum,
      'unpaidDebts': unpaidDebtsSum,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getIncomeDetails(
      DateTime start, DateTime end,
      {String? type}) async {
    final uid = AppStrings.userToken;
    if (uid.isEmpty) return [];

    final startTimestamp = Timestamp.fromDate(start);
    final endTimestamp = Timestamp.fromDate(end);

    Query<Map<String, dynamic>> query = firestore
        .collection('users')
        .doc(uid)
        .collection('operations')
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .where('timestamp', isLessThanOrEqualTo: endTimestamp);

    // Note: We might need to filter locally if we don't have composite indexes, 
    // but typically filtering by time + ordering works if equality is first. 
    // To be safe and simple, we'll fetch all in range and filter locally if type is provided, 
    // since operations in a period shouldn't be massive for a single user.
    final snapshot = await query.get();

    List<Map<String, dynamic>> results = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id; // Inject document ID
      
      if (type != null && type.isNotEmpty) {
        if ((data['type'] ?? '').toString().toLowerCase() == type.toLowerCase()) {
          results.add(data);
        }
      } else {
        results.add(data);
      }
    }
    
    // Sort descending by timestamp
    results.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    return results;
  }
}

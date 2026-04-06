import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/operation/data/models/operation_model.dart';
import 'package:tahsel/features/expenses/data/models/expense_model.dart';
import 'package:tahsel/features/debt/data/models/debt_model.dart';

abstract class ReportsRemoteDataSource {
  Future<Map<String, double>> getPeriodData(DateTime start, DateTime end);
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final FirebaseFirestore firestore;

  ReportsRemoteDataSourceImpl(this.firestore);

  @override
  Future<Map<String, double>> getPeriodData(DateTime start, DateTime end) async {
    final uid = AppStrings.userToken;
    
    // Convert to Timestamp for Firestore
    final startTimestamp = Timestamp.fromDate(start);
    final endTimestamp = Timestamp.fromDate(end);

    // 1. Fetch Operations Income
    final operationsQuery = await firestore
        .collection('users')
        .doc(uid)
        .collection('operations')
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .where('timestamp', isLessThanOrEqualTo: endTimestamp)
        .get();

    double income = 0;
    for (var doc in operationsQuery.docs) {
      final model = OperationModel.fromJson(doc.data(), doc.id);
      income += model.paidAmount;
    }

    // 2. Fetch Expenses
    final expensesQuery = await firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('createdAt', isLessThanOrEqualTo: endTimestamp)
        .get();

    double expenses = 0;
    for (var doc in expensesQuery.docs) {
      final model = ExpenseModel.fromJson(doc.data(), doc.id);
      expenses += model.amount;
    }

    // 3. Fetch Debts (for total debts and paid debts in this period)
    final debtsQuery = await firestore
        .collection('users')
        .doc(uid)
        .collection('debts')
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .where('timestamp', isLessThanOrEqualTo: endTimestamp)
        .get();

    double totalDebts = 0;
    double paidDebtsSum = 0;
    double unpaidDebtsSum = 0;

    for (var doc in debtsQuery.docs) {
      final model = DebtModel.fromJson(doc.data(), doc.id);
      totalDebts += model.totalAmount;
      paidDebtsSum += model.paidAmount;
      unpaidDebtsSum += model.remainingAmount;
    }

    // Also need to account for session categories if needed manually,
    // but the models cover the basics.

    return {
      'income': income,
      'expenses': expenses,
      'totalDebts': totalDebts,
      'paidDebts': paidDebtsSum,
      'unpaidDebts': unpaidDebtsSum,
    };
  }
}

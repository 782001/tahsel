import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense_entity.dart';
import '../models/expense_model.dart';
import 'package:tahsel/core/utils/date_formatter.dart';

abstract class ExpenseRemoteDataSource {
  Future<String> addExpense(ExpenseModel expense);
  Future<List<ExpenseModel>> getExpenses(String uid);
  Future<List<MonthlyExpenseGroup>> getMonthlyAggregates(String uid, List<String> monthKeys);
  Future<List<ExpenseModel>> getExpensesByMonth(String uid, String monthKey);
  Future<void> deleteExpense(String uid, String expenseId);
  Future<void> deleteMonthExpenses(String uid, String monthKey);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore firestore;

  ExpenseRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String> addExpense(ExpenseModel expense) async {
    try {
      final docRef = await firestore
          .collection('users')
          .doc(expense.uid)
          .collection('expenses')
          .add(expense.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  @override
  Future<List<ExpenseModel>> getExpenses(String uid) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  @override
  Future<List<MonthlyExpenseGroup>> getMonthlyAggregates(String uid, List<String> monthKeys) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();

      final Map<String, MonthlyExpenseGroup> grouped = {};
      for (final doc in snapshot.docs) {
        final expense = ExpenseModel.fromJson(doc.data(), doc.id);
        final amount = expense.amount;
        final monthKey = expense.monthKey;
        
        if (grouped.containsKey(monthKey)) {
          final existing = grouped[monthKey]!;
          grouped[monthKey] = MonthlyExpenseGroup(
            monthKey: monthKey,
            monthName: existing.monthName,
            totalAmount: existing.totalAmount + amount,
            transactionCount: existing.transactionCount + 1,
          );
        } else {
          final date = DateTime(expense.createdAt.year, expense.createdAt.month);
          final monthName = DateFormatter.formatNumericMonth(date);
          grouped[monthKey] = MonthlyExpenseGroup(
            monthKey: monthKey,
            monthName: monthName,
            totalAmount: amount,
            transactionCount: 1,
          );
        }
      }

      final List<MonthlyExpenseGroup> results = grouped.values.toList();
      results.sort((a, b) => b.monthKey.compareTo(a.monthKey));
      
      return results;
    } catch (e) {
      throw Exception('Failed to fetch monthly aggregates: $e');
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesByMonth(String uid, String monthKey) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where('monthKey', isEqualTo: monthKey)
          .get();

      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data(), doc.id))
          .toList();
          
      // Sort manually to avoid needing a composite index
      expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return expenses;
    } catch (e) {
      throw Exception('Failed to fetch expenses by month: $e');
    }
  }

  @override
  Future<void> deleteExpense(String uid, String expenseId) async {
    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  @override
  Future<void> deleteMonthExpenses(String uid, String monthKey) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where('monthKey', isEqualTo: monthKey)
          .get();

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete month expenses: $e');
    }
  }
}

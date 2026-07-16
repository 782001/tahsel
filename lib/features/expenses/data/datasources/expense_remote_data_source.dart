import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/core/utils/summary_helper.dart';

import '../../../../core/error/firebase_error_handler.dart';
import '../../domain/entities/expense_entity.dart';
import '../models/expense_model.dart';

class MonthlyPaginationResult {
  final List<MonthlyExpenseGroup> months;
  final DocumentSnapshot? lastDoc;

  MonthlyPaginationResult({required this.months, this.lastDoc});
}

class ExpensePaginationResult {
  final List<ExpenseModel> expenses;
  final DocumentSnapshot? lastDoc;

  ExpensePaginationResult({required this.expenses, this.lastDoc});
}

abstract class ExpenseRemoteDataSource {
  Future<String> addExpense(ExpenseModel expense);
  Future<List<ExpenseModel>> getExpenses(String uid);
  Future<MonthlyPaginationResult> getMonthlyAggregates(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
  Future<ExpensePaginationResult> getExpensesByMonth(
    String uid,
    String monthKey, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
  Future<void> deleteExpense(String uid, String expenseId);
  Future<void> deleteMonthExpenses(String uid, String monthKey);
  // Future<void> repairMissingSummaries(String uid);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore firestore;

  ExpenseRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String> addExpense(ExpenseModel expense) async {
    try {
      final userRef = firestore.collection('users').doc(expense.uid);
      final collectionRef = userRef.collection('expenses');

      final docRef = (expense.id != null && expense.id!.isNotEmpty)
          ? collectionRef.doc(expense.id)
          : collectionRef.doc();

      final batch = firestore.batch();

      // 1. Set the expense document
      batch.set(docRef, expense.toJson());

      // 2. Update Summaries
      final summaryKeys = SummaryHelper.getSummaryKeys(expense.createdAt);
      for (final key in summaryKeys) {
        final summaryRef = userRef.collection('summaries').doc(key);
        batch.set(summaryRef, {
          'totalExpenses': FieldValue.increment(expense.amount),
          'transactionCount': FieldValue.increment(1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      return docRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
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
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  @override
  Future<MonthlyPaginationResult> getMonthlyAggregates(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final userRef = firestore.collection('users').doc(uid);

      // if (lastDoc == null) {
      //   // Run repair in background to fix any legacy missing summaries
      //   repairMissingSummaries(uid);
      // }

      // Query summaries collection for monthly docs
      // Doc IDs are like 'monthly_2026-05'
      var query = userRef
          .collection('summaries')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'monthly_')
          .where(FieldPath.documentId, isLessThanOrEqualTo: 'monthly_\uf8ff')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final List<MonthlyExpenseGroup> results = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final monthKey = doc.id.replaceFirst('monthly_', '');

        final totalExpenses = (data['totalExpenses'] ?? 0).toDouble();
        var count = (data['transactionCount'] ?? 0).toInt();

        // PROACTIVE REPAIR: Ensure transaction count is accurate
        // We verify the summary count against actual records once if the month has expenses.
        if (totalExpenses > 0) {
          // 1. Try counting by monthKey first (Fast)
          final oldKey = monthKey.replaceAll('-', '/');
          final countQuery = await userRef
              .collection('expenses')
              .where('monthKey', whereIn: [monthKey, oldKey])
              .count()
              .get();

          var actualCount = countQuery.count ?? 0;

          // 2. Fallback: Check by Date Range if monthKey count is 0 (For legacy data)
          if (actualCount == 0) {
            try {
              final parts = monthKey.split(monthKey.contains('-') ? '-' : '/');
              if (parts.length == 2) {
                final year = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final start = DateTime(year, month, 1);
                final end = DateTime(year, month + 1, 1);

                final rangeCount = await userRef
                    .collection('expenses')
                    .where(
                      'createdAt',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(start),
                    )
                    .where('createdAt', isLessThan: Timestamp.fromDate(end))
                    .count()
                    .get();
                actualCount = rangeCount.count ?? 0;
              }
            } catch (_) {}
          }

          // Idempotent Update: Only write if the count is actually different
          if (actualCount != count) {
            count = actualCount;
            userRef
                .collection('summaries')
                .doc(doc.id)
                .update({
                  'transactionCount': count,
                  'lastUpdatedAt': FieldValue.serverTimestamp(),
                })
                .catchError((_) {});
          }
        }

        if (totalExpenses > 0 || count > 0) {
          String formattedName = monthKey;
          try {
            final parts = monthKey.split(monthKey.contains('-') ? '-' : '/');
            if (parts.length == 2) {
              final year = int.parse(parts[0]);
              final monthValue = int.parse(parts[1]);
              final date = DateTime(year, monthValue);
              formattedName = DateFormatter.formatArabicMonthYear(date);
            }
          } catch (_) {}

          results.add(
            MonthlyExpenseGroup(
              monthKey: monthKey,
              monthName: formattedName,
              totalAmount: totalExpenses,
              transactionCount: count,
            ),
          );
        }
      }

      return MonthlyPaginationResult(
        months: results,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch monthly aggregates: $e');
    }
  }

  @override
  Future<ExpensePaginationResult> getExpensesByMonth(
    String uid,
    String monthKey, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final monthKeyOld = monthKey.replaceAll('-', '/');
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where('monthKey', whereIn: [monthKey, monthKeyOld])
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data(), doc.id))
          .toList();

      return ExpensePaginationResult(
        expenses: expenses,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch expenses by month: $e');
    }
  }

  @override
  Future<void> deleteExpense(String uid, String expenseId) async {
    try {
      final userRef = firestore.collection('users').doc(uid);
      final expenseRef = userRef.collection('expenses').doc(expenseId);

      final expenseDoc = await expenseRef.get();
      if (!expenseDoc.exists) return;

      final expense = ExpenseModel.fromJson(expenseDoc.data()!, expenseId);
      final batch = firestore.batch();

      // 1. Delete document
      batch.delete(expenseRef);

      // 2. Update Summaries (Decrement)
      final summaryKeys = SummaryHelper.getSummaryKeys(expense.createdAt);
      for (final key in summaryKeys) {
        final summaryRef = userRef.collection('summaries').doc(key);
        batch.set(summaryRef, {
          'totalExpenses': FieldValue.increment(-expense.amount),
          'transactionCount': FieldValue.increment(-1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to delete expense: $e');
    }
  }

  @override
  Future<void> deleteMonthExpenses(String uid, String monthKey) async {
    try {
      final userRef = firestore.collection('users').doc(uid);
      final snapshot = await userRef
          .collection('expenses')
          .where('monthKey', isEqualTo: monthKey)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = firestore.batch();
      double totalAmountRemoved = 0;
      Map<String, Map<String, double>> dailyWeeklyAmounts = {};

      for (final doc in snapshot.docs) {
        final expense = ExpenseModel.fromJson(doc.data(), doc.id);
        totalAmountRemoved += expense.amount;

        // Track per-day/per-week for summary updates
        final keys = SummaryHelper.getSummaryKeys(expense.createdAt);
        for (final key in keys) {
          // We exclude monthly and all_time from this loop to handle them once at the end
          if (key.startsWith('daily_') || key.startsWith('weekly_')) {
            if (!dailyWeeklyAmounts.containsKey(key)) {
              dailyWeeklyAmounts[key] = {'amount': 0, 'count': 0};
            }
            dailyWeeklyAmounts[key]!['amount'] =
                dailyWeeklyAmounts[key]!['amount']! + expense.amount;
            dailyWeeklyAmounts[key]!['count'] =
                dailyWeeklyAmounts[key]!['count']! + 1;
          }
        }

        batch.delete(doc.reference);
      }

      // Update Daily & Weekly Summaries
      dailyWeeklyAmounts.forEach((key, data) {
        final summaryRef = userRef.collection('summaries').doc(key);
        batch.set(summaryRef, {
          'totalExpenses': FieldValue.increment(-data['amount']!),
          'transactionCount': FieldValue.increment(-(data['count']!).toInt()),
        }, SetOptions(merge: true));
      });

      // Update Monthly Summary
      final monthlyRef = userRef
          .collection('summaries')
          .doc('monthly_$monthKey');
      batch.set(monthlyRef, {
        'totalExpenses': FieldValue.increment(-totalAmountRemoved),
        'transactionCount': FieldValue.increment(-snapshot.docs.length),
      }, SetOptions(merge: true));

      // Update All-Time Summary
      final allTimeRef = userRef
          .collection('summaries')
          .doc(SummaryHelper.getAllTimeKey());
      batch.set(allTimeRef, {
        'totalExpenses': FieldValue.increment(-totalAmountRemoved),
        'transactionCount': FieldValue.increment(-snapshot.docs.length),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to delete month expenses: $e');
    }
  }

  // @override
  // Future<void> repairMissingSummaries(String uid) async {
  //   try {
  //     final userRef = firestore.collection('users').doc(uid);
  //     final expensesSnapshot = await userRef.collection('expenses').get();

  //     Map<String, Map<String, dynamic>> monthAggregates = {};
  //     double totalExpenses = 0;
  //     int totalCount = 0;

  //     for (var doc in expensesSnapshot.docs) {
  //       final data = doc.data();
  //       final amount = (data['amount'] ?? 0).toDouble();

  //       // Ensure monthKey format
  //       String monthKey = data['monthKey'] ?? '';
  //       if (monthKey.isEmpty) {
  //         final createdAt = data['createdAt'] as Timestamp?;
  //         if (createdAt != null) {
  //           final date = createdAt.toDate();
  //           // Fallback if DateFormatter is not available here, but we can just format it:
  //           monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";
  //         }
  //       }
  //       monthKey = monthKey.replaceAll('/', '-');

  //       if (monthKey.isNotEmpty) {
  //         if (!monthAggregates.containsKey(monthKey)) {
  //           monthAggregates[monthKey] = {'amount': 0.0, 'count': 0};
  //         }
  //         monthAggregates[monthKey]!['amount'] += amount;
  //         monthAggregates[monthKey]!['count'] += 1;
  //       }

  //       totalExpenses += amount;
  //       totalCount += 1;
  //     }

  //     final batch = firestore.batch();

  //     // Update monthly summaries
  //     monthAggregates.forEach((month, data) {
  //       final summaryRef = userRef
  //           .collection('summaries')
  //           .doc('monthly_$month');
  //       batch.set(summaryRef, {
  //         'totalExpenses': data['amount'],
  //         'transactionCount': data['count'],
  //         'lastUpdatedAt': FieldValue.serverTimestamp(),
  //       }, SetOptions(merge: true));
  //     });

  //     // Update All-time summary
  //     final allTimeRef = userRef
  //         .collection('summaries')
  //         .doc(SummaryHelper.getAllTimeKey());
  //     batch.set(allTimeRef, {
  //       'totalExpenses': totalExpenses,
  //       'transactionCount': totalCount,
  //       'lastUpdatedAt': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));

  //     await batch.commit();
  //   } catch (e) {
  //     // Silently fail in background
  //   }
  // }
}

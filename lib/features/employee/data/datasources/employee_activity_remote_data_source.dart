import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tahsel/core/error/exceptions.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import '../models/employee_activity_model.dart';

class EmployeeActivityResult {
  final List<EmployeeActivityModel> activities;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const EmployeeActivityResult({
    required this.activities,
    this.lastDocument,
    required this.hasMore,
  });
}

class EmployeeActivityStats {
  final int totalCount;
  final int salesCount;
  final int invoicesCount;
  final int debtsCount;
  final int expensesCount;
  final int vaultCount;
  final int inventoryCount;
  final int employeesCount;
  final int reportsCount;
  final int settingsCount;
  final double totalSalesAmount;
  final double totalExpensesAmount;

  const EmployeeActivityStats({
    this.totalCount = 0,
    this.salesCount = 0,
    this.invoicesCount = 0,
    this.debtsCount = 0,
    this.expensesCount = 0,
    this.vaultCount = 0,
    this.inventoryCount = 0,
    this.employeesCount = 0,
    this.reportsCount = 0,
    this.settingsCount = 0,
    this.totalSalesAmount = 0.0,
    this.totalExpensesAmount = 0.0,
  });
}

abstract class EmployeeActivityRemoteDataSource {
  Future<EmployeeActivityResult> getActivitiesPaginated({
    required String ownerUid,
    required String employeeUid,
    String category = 'all',
    DateTimeRange? dateRange,
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });

  Future<EmployeeActivityStats> getEmployeeStats({
    required String ownerUid,
    required String employeeUid,
    bool forceRefresh = false,
  });

  Future<List<EmployeeActivityModel>> getAllActivitiesForExport({
    required String ownerUid,
    required String employeeUid,
    String category = 'all',
    DateTimeRange? dateRange,
    int limit = 1000,
  });
}

class EmployeeActivityRemoteDataSourceImpl implements EmployeeActivityRemoteDataSource {
  final FirebaseFirestore firestore;

  EmployeeActivityRemoteDataSourceImpl({required this.firestore});

  @override
  Future<EmployeeActivityResult> getActivitiesPaginated({
    required String ownerUid,
    required String employeeUid,
    String category = 'all',
    DateTimeRange? dateRange,
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    final cleanOwner = ownerUid.trim();
    final cleanEmp = employeeUid.trim();
    if (cleanOwner.isEmpty) {
      return const EmployeeActivityResult(
        activities: [],
        lastDocument: null,
        hasMore: false,
      );
    }

    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('users')
          .doc(cleanOwner)
          .collection('employee_activities');

      if (cleanEmp.isNotEmpty && cleanEmp != 'all') {
        query = query.where('employeeUid', isEqualTo: cleanEmp);
      }

      if (category != 'all') {
        query = query.where('actionCategory', isEqualTo: category);
      }

      if (dateRange != null) {
        final startOfDay = DateTime(
          dateRange.start.year,
          dateRange.start.month,
          dateRange.start.day,
        );
        final endOfDay = DateTime(
          dateRange.end.year,
          dateRange.end.month,
          dateRange.end.day,
          23,
          59,
          59,
          999,
        );
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.get();
      final activities = querySnapshot.docs.map((doc) {
        return EmployeeActivityModel.fromMap(doc.data(), doc.id);
      }).toList();

      final newLastDoc = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      final hasMore = activities.length == limit;

      return EmployeeActivityResult(
        activities: activities,
        lastDocument: newLastDoc,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      AppLogger.printMessage('[EmployeeActivityRemoteDataSource] FirebaseException: $e');
      // If a composite index is missing or building, fallback gracefully to in-memory filter
      if (e.code == 'failed-precondition' || (e.message != null && e.message!.contains('index'))) {
        return _fallbackGetActivities(
          ownerUid: cleanOwner,
          employeeUid: cleanEmp,
          category: category,
          dateRange: dateRange,
          limit: limit,
          lastDoc: lastDoc,
        );
      }
      throw ServerException(e.toString());
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityRemoteDataSource] Error: $e');
      throw ServerException(e.toString());
    }
  }

  Future<EmployeeActivityResult> _fallbackGetActivities({
    required String ownerUid,
    required String employeeUid,
    String category = 'all',
    DateTimeRange? dateRange,
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      // Use Firestore built-in single field index on timestamp to ensure exact chronological order
      Query<Map<String, dynamic>> query = firestore
          .collection('users')
          .doc(ownerUid)
          .collection('employee_activities')
          .orderBy('timestamp', descending: true);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final fetchLimit = limit > 50 ? limit : limit * 4;
      final querySnapshot = await query.limit(fetchLimit).get();
      final docs = querySnapshot.docs;

      var activities = docs.map((doc) {
        return EmployeeActivityModel.fromMap(doc.data(), doc.id);
      }).toList();

      final cleanEmp = employeeUid.trim();
      if (cleanEmp.isNotEmpty && cleanEmp != 'all') {
        activities = activities.where((a) => a.employeeUid == cleanEmp).toList();
      }

      if (category != 'all') {
        activities = activities.where((a) => a.actionCategory == category).toList();
      }

      if (dateRange != null) {
        final start = dateRange.start;
        final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59, 999);
        activities = activities.where((a) => !a.timestamp.isBefore(start) && !a.timestamp.isAfter(end)).toList();
      }

      final hasReachedEnd = docs.length < fetchLimit;
      final hasMore = !hasReachedEnd && activities.isNotEmpty;
      final newLastDoc = docs.isNotEmpty ? docs.last : null;

      if (activities.length > limit) {
        activities = activities.sublist(0, limit);
      }

      return EmployeeActivityResult(
        activities: activities,
        lastDocument: newLastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityRemoteDataSource] Fallback error: $e');
      return const EmployeeActivityResult(
        activities: [],
        lastDocument: null,
        hasMore: false,
      );
    }
  }

  @override
  Future<List<EmployeeActivityModel>> getAllActivitiesForExport({
    required String ownerUid,
    required String employeeUid,
    String category = 'all',
    DateTimeRange? dateRange,
    int limit = 1000,
  }) async {
    final cleanOwner = ownerUid.trim();
    final cleanEmp = employeeUid.trim();
    if (cleanOwner.isEmpty) return [];

    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('users')
          .doc(cleanOwner)
          .collection('employee_activities');

      if (cleanEmp.isNotEmpty && cleanEmp != 'all') {
        query = query.where('employeeUid', isEqualTo: cleanEmp);
      }

      if (category != 'all') {
        query = query.where('actionCategory', isEqualTo: category);
      }

      if (dateRange != null) {
        final startOfDay = DateTime(
          dateRange.start.year,
          dateRange.start.month,
          dateRange.start.day,
        );
        final endOfDay = DateTime(
          dateRange.end.year,
          dateRange.end.month,
          dateRange.end.day,
          23,
          59,
          59,
          999,
        );
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => EmployeeActivityModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.printMessage('[EmployeeActivityRemoteDataSource] getAllActivitiesForExport FirebaseException: $e');
      if (e.code == 'failed-precondition' || (e.message != null && e.message!.contains('index'))) {
        final fallback = await _fallbackGetActivities(
          ownerUid: cleanOwner,
          employeeUid: cleanEmp,
          category: category,
          dateRange: dateRange,
          limit: limit,
        );
        return fallback.activities;
      }
      return [];
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityRemoteDataSource] getAllActivitiesForExport error: $e');
      return [];
    }
  }

  final Map<String, _CachedActivityStats> _statsCache = {};

  @override
  Future<EmployeeActivityStats> getEmployeeStats({
    required String ownerUid,
    required String employeeUid,
    bool forceRefresh = false,
  }) async {
    final cleanOwner = ownerUid.trim();
    final cleanEmp = employeeUid.trim();
    if (cleanOwner.isEmpty) {
      return const EmployeeActivityStats();
    }

    final cacheKey = '${cleanOwner}_$cleanEmp';
    if (!forceRefresh && _statsCache.containsKey(cacheKey)) {
      final cached = _statsCache[cacheKey]!;
      if (DateTime.now().difference(cached.cachedAt) < const Duration(minutes: 3)) {
        return cached.stats;
      }
    }

    try {
      Query<Map<String, dynamic>> baseQuery = firestore
          .collection('users')
          .doc(cleanOwner)
          .collection('employee_activities');

      if (cleanEmp.isNotEmpty && cleanEmp != 'all') {
        baseQuery = baseQuery.where('employeeUid', isEqualTo: cleanEmp);
      }

      final countSnapshot = await baseQuery.count().get();
      final totalCount = countSnapshot.count ?? 0;

      // If no activities exist at all, return empty stats immediately without reading recentDocs!
      if (totalCount == 0) {
        const emptyStats = EmployeeActivityStats();
        _statsCache[cacheKey] = _CachedActivityStats(emptyStats, DateTime.now());
        return emptyStats;
      }

      int salesCount = 0;
      int invoicesCount = 0;
      int debtsCount = 0;
      int expensesCount = 0;
      int vaultCount = 0;
      int inventoryCount = 0;
      int employeesCount = 0;
      int reportsCount = 0;
      int settingsCount = 0;
      double totalSales = 0.0;
      double totalExpenses = 0.0;

      // 1. Efficient & 100% Accurate Aggregation Query across ALL historical documents
      // Firestore aggregate queries cost only 1 read per 1,000 index keys and do NOT download documents!
      try {
        final salesFuture = baseQuery
            .where('actionCategory', isEqualTo: 'sales')
            .aggregate(count(), sum('amount'))
            .get();

        final expensesFuture = baseQuery
            .where('actionCategory', isEqualTo: 'expenses')
            .aggregate(count(), sum('amount'))
            .get();

        final debtsFuture = baseQuery
            .where('actionCategory', isEqualTo: 'debts')
            .count()
            .get();

        final aggResults = await Future.wait([
          salesFuture,
          expensesFuture,
          debtsFuture,
        ]);

        final salesAgg = aggResults[0];
        final expensesAgg = aggResults[1];
        final debtsAgg = aggResults[2];

        salesCount = salesAgg.count ?? 0;
        totalSales = salesAgg.getSum('amount') ?? 0.0;

        expensesCount = expensesAgg.count ?? 0;
        totalExpenses = expensesAgg.getSum('amount') ?? 0.0;

        debtsCount = debtsAgg.count ?? 0;
      } catch (aggError) {
        AppLogger.printMessage('[EmployeeActivityRemoteDataSource] Aggregate query fallback: $aggError');
        // Fallback: If aggregation fails, sample recent documents
        final recentDocs = await baseQuery
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();

        for (var doc in recentDocs.docs) {
          final data = doc.data();
          final cat = data['actionCategory']?.toString() ?? '';
          final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;

          if (cat == 'sales') {
            salesCount++;
            totalSales += amt;
          } else if (cat == 'expenses') {
            expensesCount++;
            totalExpenses += amt;
          } else if (cat == 'debts') {
            debtsCount++;
          }
        }
      }

      final stats = EmployeeActivityStats(
        totalCount: totalCount,
        salesCount: salesCount,
        invoicesCount: invoicesCount,
        debtsCount: debtsCount,
        expensesCount: expensesCount,
        vaultCount: vaultCount,
        inventoryCount: inventoryCount,
        employeesCount: employeesCount,
        reportsCount: reportsCount,
        settingsCount: settingsCount,
        totalSalesAmount: totalSales,
        totalExpensesAmount: totalExpenses,
      );

      _statsCache[cacheKey] = _CachedActivityStats(stats, DateTime.now());
      return stats;
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityRemoteDataSource] Stats error: $e');
      return const EmployeeActivityStats();
    }
  }
}

class _CachedActivityStats {
  final EmployeeActivityStats stats;
  final DateTime cachedAt;
  const _CachedActivityStats(this.stats, this.cachedAt);
}

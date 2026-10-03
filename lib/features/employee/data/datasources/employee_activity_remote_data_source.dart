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
      Query<Map<String, dynamic>> query = firestore
          .collection('users')
          .doc(ownerUid)
          .collection('employee_activities');

      if (employeeUid.trim().isNotEmpty && employeeUid.trim() != 'all') {
        query = query.where('employeeUid', isEqualTo: employeeUid.trim());
      }

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.limit(limit * 4).get();
      var activities = querySnapshot.docs.map((doc) {
        return EmployeeActivityModel.fromMap(doc.data(), doc.id);
      }).toList();

      if (category != 'all') {
        activities = activities.where((a) => a.actionCategory == category).toList();
      }

      if (dateRange != null) {
        final start = dateRange.start;
        final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59, 999);
        activities = activities.where((a) => !a.timestamp.isBefore(start) && !a.timestamp.isAfter(end)).toList();
      }

      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (activities.length > limit) {
        activities = activities.sublist(0, limit);
      }

      return EmployeeActivityResult(
        activities: activities,
        lastDocument: querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null,
        hasMore: querySnapshot.docs.length >= limit,
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

      // Read at most 40 recent docs (down from 100) to compute recent KPI breakdown, saving 60% Firestore read cost
      final recentDocs = await baseQuery
          .orderBy('timestamp', descending: true)
          .limit(40)
          .get();

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

      for (var doc in recentDocs.docs) {
        final data = doc.data();
        final cat = data['actionCategory']?.toString() ?? '';
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;

        if (cat == 'sales') {
          salesCount++;
          totalSales += amt;
        } else if (cat == 'invoices') {
          invoicesCount++;
        } else if (cat == 'debts') {
          debtsCount++;
        } else if (cat == 'expenses') {
          expensesCount++;
          totalExpenses += amt;
        } else if (cat == 'vault') {
          vaultCount++;
        } else if (cat == 'inventory') {
          inventoryCount++;
        } else if (cat == 'employees') {
          employeesCount++;
        } else if (cat == 'reports') {
          reportsCount++;
        } else if (cat == 'settings') {
          settingsCount++;
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

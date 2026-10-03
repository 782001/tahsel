import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import '../../data/datasources/employee_activity_remote_data_source.dart';
import 'employee_activity_state.dart';

class EmployeeActivityCubit extends Cubit<EmployeeActivityState> {
  final EmployeeActivityRemoteDataSource remoteDataSource;

  String? _ownerUid;
  String? _employeeUid;

  EmployeeActivityCubit({required this.remoteDataSource})
      : super(const EmployeeActivityInitial());

  String? get currentOwnerUid => _ownerUid;
  String? get currentEmployeeUid => _employeeUid;

  Future<void> loadInitialActivities({
    required String ownerUid,
    String employeeUid = 'all',
  }) async {
    _ownerUid = ownerUid;
    _employeeUid = employeeUid;

    emit(const EmployeeActivityLoading());

    try {
      final statsFuture = remoteDataSource.getEmployeeStats(
        ownerUid: ownerUid,
        employeeUid: employeeUid,
      );

      final activitiesFuture = remoteDataSource.getActivitiesPaginated(
        ownerUid: ownerUid,
        employeeUid: employeeUid,
        category: 'all',
        dateRange: null,
        limit: 15,
      );

      final results = await Future.wait([statsFuture, activitiesFuture]);
      final stats = results[0] as EmployeeActivityStats;
      final actResult = results[1] as EmployeeActivityResult;

      emit(
        EmployeeActivityLoaded(
          activities: actResult.activities,
          lastDocument: actResult.lastDocument,
          hasMore: actResult.hasMore,
          stats: stats,
          selectedCategory: 'all',
          selectedEmployeeUid: employeeUid,
          selectedDateRange: null,
        ),
      );
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityCubit] loadInitialActivities error: $e');
      emit(EmployeeActivityError(message: e.toString()));
    }
  }

  Future<void> changeCategory(String category) async {
    if (_ownerUid == null || _employeeUid == null) return;
    if (state is! EmployeeActivityLoaded) return;

    final currentState = state as EmployeeActivityLoaded;
    if (currentState.selectedCategory == category) return;

    // Show loading state for list while preserving stats
    emit(currentState.copyWith(
      selectedCategory: category,
      activities: [],
      hasMore: false,
      isLoadingMore: false,
    ));

    try {
      final result = await remoteDataSource.getActivitiesPaginated(
        ownerUid: _ownerUid!,
        employeeUid: _employeeUid!,
        category: category,
        dateRange: currentState.selectedDateRange,
        limit: 15,
      );

      emit(currentState.copyWith(
        selectedCategory: category,
        activities: result.activities,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityCubit] changeCategory error: $e');
      emit(currentState.copyWith(
        selectedCategory: category,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> changeDateRange(DateTimeRange? range) async {
    if (_ownerUid == null || _employeeUid == null) return;
    if (state is! EmployeeActivityLoaded) return;

    final currentState = state as EmployeeActivityLoaded;

    emit(currentState.copyWith(
      selectedDateRange: range,
      clearDateRange: range == null,
      activities: [],
      hasMore: false,
      isLoadingMore: false,
    ));

    try {
      final result = await remoteDataSource.getActivitiesPaginated(
        ownerUid: _ownerUid!,
        employeeUid: _employeeUid!,
        category: currentState.selectedCategory,
        dateRange: range,
        limit: 15,
      );

      emit(currentState.copyWith(
        selectedDateRange: range,
        clearDateRange: range == null,
        activities: result.activities,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityCubit] changeDateRange error: $e');
      emit(currentState.copyWith(
        selectedDateRange: range,
        clearDateRange: range == null,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadMore() async {
    if (_ownerUid == null || _employeeUid == null) return;
    if (state is! EmployeeActivityLoaded) return;

    final currentState = state as EmployeeActivityLoaded;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await remoteDataSource.getActivitiesPaginated(
        ownerUid: _ownerUid!,
        employeeUid: _employeeUid!,
        category: currentState.selectedCategory,
        dateRange: currentState.selectedDateRange,
        limit: 15,
        lastDoc: currentState.lastDocument,
      );

      final updatedActivities = List.of(currentState.activities)
        ..addAll(result.activities);

      emit(currentState.copyWith(
        activities: updatedActivities,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityCubit] loadMore error: $e');
      emit(currentState.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> changeEmployee(String employeeUid) async {
    if (_ownerUid == null) return;
    if (state is! EmployeeActivityLoaded) return;

    final currentState = state as EmployeeActivityLoaded;
    if (currentState.selectedEmployeeUid == employeeUid && _employeeUid == employeeUid) return;

    _employeeUid = employeeUid;

    emit(currentState.copyWith(
      selectedEmployeeUid: employeeUid,
      activities: [],
      hasMore: false,
      isLoadingMore: false,
    ));

    try {
      final statsFuture = remoteDataSource.getEmployeeStats(
        ownerUid: _ownerUid!,
        employeeUid: employeeUid,
      );

      final activitiesFuture = remoteDataSource.getActivitiesPaginated(
        ownerUid: _ownerUid!,
        employeeUid: employeeUid,
        category: currentState.selectedCategory,
        dateRange: currentState.selectedDateRange,
        limit: 15,
      );

      final results = await Future.wait([statsFuture, activitiesFuture]);
      final stats = results[0] as EmployeeActivityStats;
      final actResult = results[1] as EmployeeActivityResult;

      emit(currentState.copyWith(
        selectedEmployeeUid: employeeUid,
        activities: actResult.activities,
        lastDocument: actResult.lastDocument,
        hasMore: actResult.hasMore,
        stats: stats,
        isLoadingMore: false,
      ));
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityCubit] changeEmployee error: $e');
      emit(currentState.copyWith(
        selectedEmployeeUid: employeeUid,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refresh() async {
    if (_ownerUid == null || _employeeUid == null) return;

    final currentCategory =
        state is EmployeeActivityLoaded ? (state as EmployeeActivityLoaded).selectedCategory : 'all';
    final currentEmp =
        state is EmployeeActivityLoaded ? (state as EmployeeActivityLoaded).selectedEmployeeUid : (_employeeUid ?? 'all');
    final currentDateRange =
        state is EmployeeActivityLoaded ? (state as EmployeeActivityLoaded).selectedDateRange : null;

    try {
      final statsFuture = remoteDataSource.getEmployeeStats(
        ownerUid: _ownerUid!,
        employeeUid: currentEmp,
        forceRefresh: true,
      );

      final activitiesFuture = remoteDataSource.getActivitiesPaginated(
        ownerUid: _ownerUid!,
        employeeUid: currentEmp,
        category: currentCategory,
        dateRange: currentDateRange,
        limit: 15,
      );

      final results = await Future.wait([statsFuture, activitiesFuture]);
      final stats = results[0] as EmployeeActivityStats;
      final actResult = results[1] as EmployeeActivityResult;

      emit(
        EmployeeActivityLoaded(
          activities: actResult.activities,
          lastDocument: actResult.lastDocument,
          hasMore: actResult.hasMore,
          stats: stats,
          selectedCategory: currentCategory,
          selectedEmployeeUid: currentEmp,
          selectedDateRange: currentDateRange,
        ),
      );
    } catch (e) {
      AppLogger.printMessage('[EmployeeActivityCubit] refresh error: $e');
      if (state is EmployeeActivityLoaded) {
        emit((state as EmployeeActivityLoaded).copyWith(errorMessage: e.toString()));
      }
    }
  }
}

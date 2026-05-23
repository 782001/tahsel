import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/reports_entity.dart';
import '../../../domain/usecases/generate_insights_usecase.dart';
import '../../../domain/usecases/get_all_time_reports_usecase.dart';
import '../../../domain/usecases/get_reports_usecase.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final GetReportsUseCase getReportsUseCase;
  final GenerateInsightsUseCase generateInsightsUseCase;
  final GetAllTimeReportsUseCase getAllTimeReportsUseCase;

  // Cache to store reports for each period
  final Map<String, ReportsSuccess> _cache = {};

  ReportsCubit({
    required this.getReportsUseCase,
    required this.generateInsightsUseCase,
    required this.getAllTimeReportsUseCase,
  }) : super(ReportsInitial());

  Future<void> fetchReports({
    required DateTime startDate,
    required DateTime endDate,
    required ReportPeriod period,
    bool forceRefresh = false,
  }) async {
    final cacheKey = period.toString();

    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      emit(_cache[cacheKey]!);
      return;
    }

    emit(ReportsLoading());

    final result = await getReportsUseCase(
      GetReportsParams(
        startDate: startDate,
        endDate: endDate,
        periodKey: period.name,
        forceRefresh: forceRefresh,
      ),
    );

    result.fold((failure) => emit(ReportsError(failure.message)), (
      reports,
    ) async {
      final insightsResult = await generateInsightsUseCase(
        GenerateInsightsParams(reports: reports, period: period),
      );
      insightsResult.fold((failure) => emit(ReportsError(failure.message)), (
        insights,
      ) {
        final successState = ReportsSuccess(reports, insights, period);
        _cache[cacheKey] = successState;
        emit(successState);
      });
    });
  }

  void fetchToday({bool forceRefresh = false}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    fetchReports(
      startDate: start,
      endDate: end,
      period: ReportPeriod.daily,
      forceRefresh: forceRefresh,
    );
  }

  void fetchYesterday({bool forceRefresh = false}) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final end = DateTime(yesterday.year, yesterday.month, yesterday.day + 1);
    fetchReports(
      startDate: start,
      endDate: end,
      period: ReportPeriod.daily,
      forceRefresh: forceRefresh,
    );
  }

  void fetchCurrentWeek({bool forceRefresh = false}) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday % 7));
    final startDate = DateTime(start.year, start.month, start.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    fetchReports(
      startDate: startDate,
      endDate: end,
      period: ReportPeriod.weekly,
      forceRefresh: forceRefresh,
    );
  }

  void fetchCurrentMonth({bool forceRefresh = false}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day + 1);
    fetchReports(
      startDate: start,
      endDate: end,
      period: ReportPeriod.monthly,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> fetchAllTime({bool forceRefresh = false}) async {
    const cacheKey = 'allTime';

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      emit(_cache[cacheKey]!);
      return;
    }

    emit(ReportsLoading());

    final result = await getAllTimeReportsUseCase(
      GetAllTimeReportsParams(forceRefresh: forceRefresh),
    );

    result.fold((failure) => emit(ReportsError(failure.message)), (reports) {
      final successState = ReportsSuccess(
        reports,
        const [],
        ReportPeriod.allTime,
      );
      _cache[cacheKey] = successState;
      emit(successState);
    });
  }

  /// Clears the cache, useful on logout or when global state changes significantly
  void clearCache() {
    _cache.clear();
  }
}

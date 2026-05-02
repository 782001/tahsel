import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';

import '../../../domain/entities/reports_entity.dart';
import '../../../domain/usecases/generate_insights_usecase.dart';
import '../../../domain/usecases/get_all_time_reports_usecase.dart';
import '../../../domain/usecases/get_reports_usecase.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final GetReportsUseCase getReportsUseCase;
  final GenerateInsightsUseCase generateInsightsUseCase;
  final GetAllTimeReportsUseCase getAllTimeReportsUseCase;

  ReportsCubit({
    required this.getReportsUseCase,
    required this.generateInsightsUseCase,
    required this.getAllTimeReportsUseCase,
  }) : super(ReportsInitial());

  Future<void> fetchReports({
    required DateTime startDate,
    required DateTime endDate,
    required ReportPeriod period,
  }) async {
    emit(ReportsLoading());

    final result = await getReportsUseCase(
      GetReportsParams(startDate: startDate, endDate: endDate),
    );

    result.fold((failure) => emit(ReportsError(failure.message)), (
      reports,
    ) async {
      final insightsResult = await generateInsightsUseCase(
        GenerateInsightsParams(reports: reports, period: period),
      );
      insightsResult.fold(
        (failure) => emit(ReportsError(failure.message)),
        (insights) => emit(ReportsSuccess(reports, insights)),
      );
    });
  }

  void fetchToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    fetchReports(startDate: start, endDate: end, period: ReportPeriod.daily);
  }

  void fetchYesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final end = DateTime(yesterday.year, yesterday.month, yesterday.day + 1);
    fetchReports(startDate: start, endDate: end, period: ReportPeriod.daily);
  }

  void fetchCurrentWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday % 7));
    final startDate = DateTime(start.year, start.month, start.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    fetchReports(
      startDate: startDate,
      endDate: end,
      period: ReportPeriod.weekly,
    );
  }

  void fetchCurrentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day + 1);
    fetchReports(startDate: start, endDate: end, period: ReportPeriod.monthly);
  }

  Future<void> fetchAllTime() async {
    emit(ReportsLoading());

    final result = await getAllTimeReportsUseCase(NoParams());

    result.fold(
      (failure) => emit(ReportsError(failure.message)),
      (reports) =>
          emit(ReportsSuccess(reports, [])), // Pure aggregation, no insights
    );
  }
}

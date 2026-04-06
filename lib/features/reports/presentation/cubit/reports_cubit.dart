import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reports_entity.dart';
import '../../domain/usecases/get_reports_usecase.dart';
import '../../domain/usecases/generate_insights_usecase.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final GetReportsUseCase getReportsUseCase;
  final GenerateInsightsUseCase generateInsightsUseCase;

  ReportsCubit({
    required this.getReportsUseCase,
    required this.generateInsightsUseCase,
  }) : super(ReportsInitial());

  Future<void> fetchReports({
    required DateTime startDate,
    required DateTime endDate,
    required ReportPeriod period,
  }) async {
    emit(ReportsLoading());

    final result = await getReportsUseCase(startDate, endDate);

    result.fold(
      (error) => emit(ReportsError(error)),
      (reports) {
        final insights = generateInsightsUseCase(reports, period);
        emit(ReportsSuccess(reports, insights));
      },
    );
  }

  void fetchToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    fetchReports(startDate: start, endDate: end, period: ReportPeriod.daily);
  }

  void fetchYesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final end =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    fetchReports(startDate: start, endDate: end, period: ReportPeriod.daily);
  }

  void fetchCurrentWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday % 7));
    final startDate = DateTime(start.year, start.month, start.day);
    final end = now;
    fetchReports(
        startDate: startDate, endDate: end, period: ReportPeriod.weekly);
  }

  void fetchCurrentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = now;
    fetchReports(
        startDate: start, endDate: end, period: ReportPeriod.monthly);
  }
}

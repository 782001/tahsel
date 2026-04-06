import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_reports_usecase.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final GetReportsUseCase getReportsUseCase;

  ReportsCubit({required this.getReportsUseCase}) : super(ReportsInitial());

  Future<void> fetchReports({required DateTime startDate, required DateTime endDate}) async {
    emit(ReportsLoading());
    
    final result = await getReportsUseCase(startDate, endDate);
    
    result.fold(
      (error) => emit(ReportsError(error)),
      (reports) => emit(ReportsSuccess(reports)),
    );
  }

  void fetchToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    fetchReports(startDate: start, endDate: end);
  }

  void fetchYesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    fetchReports(startDate: start, endDate: end);
  }

  void fetchCurrentWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday % 7));
    final startDate = DateTime(start.year, start.month, start.day);
    final end = now;
    fetchReports(startDate: startDate, endDate: end);
  }

  void fetchCurrentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = now;
    fetchReports(startDate: start, endDate: end);
  }
}

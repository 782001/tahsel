import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_summary_usecase.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_summary_state.dart';

class MyDebtsSummaryCubit extends Cubit<MyDebtsSummaryState> {
  final GetMyDebtSummaryUseCase getMyDebtSummaryUseCase;

  MyDebtsSummaryCubit({
    required this.getMyDebtSummaryUseCase,
  }) : super(MyDebtsSummaryInitial());

  Future<void> loadSummary(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && state is MyDebtsSummaryLoaded) {
      return;
    }

    emit(MyDebtsSummaryLoading());

    final result = await getMyDebtSummaryUseCase(uid);

    result.fold(
      (failure) => emit(MyDebtsSummaryError(failure.message)),
      (summary) {
        if (!isClosed) {
          emit(
            MyDebtsSummaryLoaded(
              totalOwed: summary.totalRemainingDebt,
              totalPaid: summary.totalPaid,
              totalPeople: summary.peopleCount,
            ),
          );
        }
      },
    );
  }

  /// Called after any mutation (add debt, pay, etc.) to refresh the summary.
  Future<void> refreshSummary(String uid) async {
    await loadSummary(uid, forceRefresh: true);
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/debt/domain/usecases/get_debt_summary_usecase.dart';
// Removed redundant import

import 'total_debts_state.dart';

class TotalDebtsCubit extends Cubit<TotalDebtsState> {
  final GetDebtSummaryUseCase getDebtSummaryUseCase;

  TotalDebtsCubit({required this.getDebtSummaryUseCase})
    : super(TotalDebtsInitial());

  Future<void> getTotalDebts(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && state is TotalDebtsLoaded) {
      return;
    }

    emit(TotalDebtsLoading());

    final result = await getDebtSummaryUseCase(uid);
    if (isClosed) return;

    result.fold(
      (failure) => emit(TotalDebtsError(failure.message)),
      (summary) => emit(
        TotalDebtsLoaded(
          totalAmount: summary.totalAmount,
          customerCount: summary.customerCount,
        ),
      ),
    );
  }

  @override
  void emit(TotalDebtsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  /// Called when DebtCubit refreshes the debts list after any mutation.
  /// Fetches the latest global summary from Firestore.
  Future<void> updateFromDebts(String uid) async {
    await getTotalDebts(uid, forceRefresh: true);
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../debt/domain/usecases/get_debts_usecase.dart';
import '../../../domain/usecases/calculate_total_debts_usecase.dart';
import 'total_debts_state.dart';

class TotalDebtsCubit extends Cubit<TotalDebtsState> {
  final GetDebtsUseCase getDebtsUseCase;
  final CalculateTotalDebtsUseCase calculateTotalDebtsUseCase;

  TotalDebtsCubit({
    required this.getDebtsUseCase,
    required this.calculateTotalDebtsUseCase,
  }) : super(TotalDebtsInitial());

  Future<void> getTotalDebts(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && state is TotalDebtsLoaded) {
      return;
    }

    emit(TotalDebtsLoading());
    
    final result = await getDebtsUseCase(GetDebtsParams(uid: uid));
    
    await result.fold(
      (failure) async => emit(TotalDebtsError(failure.message)),
      (debts) async {
        try {
          final totalResult = await calculateTotalDebtsUseCase(debts);
          if (!isClosed) {
            emit(TotalDebtsLoaded(
              totalAmount: totalResult.totalAmount,
              customerCount: totalResult.customerCount,
            ));
          }
        } catch (e) {
          if (!isClosed) {
            emit(TotalDebtsError(e.toString()));
          }
        }
      },
    );
  }
}

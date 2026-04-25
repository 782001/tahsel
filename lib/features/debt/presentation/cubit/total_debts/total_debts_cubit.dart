import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_debts_stream_usecase.dart';
import '../../../domain/usecases/calculate_total_debts_usecase.dart';
import 'total_debts_state.dart';

class TotalDebtsCubit extends Cubit<TotalDebtsState> {
  final GetDebtsStreamUseCase getDebtsStreamUseCase;
  final CalculateTotalDebtsUseCase calculateTotalDebtsUseCase;
  StreamSubscription? _debtsSubscription;

  TotalDebtsCubit({
    required this.getDebtsStreamUseCase,
    required this.calculateTotalDebtsUseCase,
  }) : super(TotalDebtsInitial());

  void init(String uid) {
    emit(TotalDebtsLoading());
    _debtsSubscription?.cancel();
    _debtsSubscription = getDebtsStreamUseCase(uid).listen(
      (debts) async {
        try {
          final result = await calculateTotalDebtsUseCase(debts);
          if (!isClosed) {
            emit(TotalDebtsLoaded(
              totalAmount: result.totalAmount,
              customerCount: result.customerCount,
            ));
          }
        } catch (e) {
          if (!isClosed) {
            emit(TotalDebtsError(e.toString()));
          }
        }
      },
      onError: (e) {
        if (!isClosed) {
          emit(TotalDebtsError(e.toString()));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _debtsSubscription?.cancel();
    return super.close();
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/debt/domain/usecases/get_monthly_collected_amounts_usecase.dart';
import 'monthly_collected_state.dart';

class MonthlyCollectedCubit extends Cubit<MonthlyCollectedState> {
  final GetMonthlyCollectedAmountsUseCase getMonthlyCollectedAmountsUseCase;

  MonthlyCollectedCubit({
    required this.getMonthlyCollectedAmountsUseCase,
  }) : super(MonthlyCollectedInitial());

  Future<void> loadMonthlyData(String uid) async {
    emit(MonthlyCollectedLoading());

    final result = await getMonthlyCollectedAmountsUseCase(uid);

    result.fold(
      (failure) => emit(MonthlyCollectedError(failure.message)),
      (data) => emit(MonthlyCollectedSuccess(data)),
    );
  }
}

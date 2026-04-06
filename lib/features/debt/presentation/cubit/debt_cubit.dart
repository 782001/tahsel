import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/usecases/add_debt_usecase.dart';
import '../../domain/usecases/get_debts_usecase.dart';
import 'debt_state.dart';

class DebtCubit extends Cubit<DebtState> {
  final AddDebtUseCase addDebtUseCase;
  final GetDebtsUseCase getDebtsUseCase;

  DebtCubit({
    required this.addDebtUseCase,
    required this.getDebtsUseCase,
  }) : super(DebtInitial());

  Future<void> addDebt(DebtEntity debt) async {
    emit(DebtLoading());
    final result = await addDebtUseCase(AddDebtParams(debt: debt));
    result.fold(
      (failure) => emit(DebtFailure(message: failure.toString())),
      (debtId) => emit(DebtAddSuccess(debtId: debtId)),
    );
  }

  Future<void> getDebts(String uid) async {
    emit(DebtLoading());
    final result = await getDebtsUseCase(GetDebtsParams(uid: uid));
    result.fold(
      (failure) => emit(DebtFailure(message: failure.toString())),
      (debts) => emit(DebtsFetchSuccess(debts: debts)),
    );
  }
}

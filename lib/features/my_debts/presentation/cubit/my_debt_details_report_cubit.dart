import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_item_payments_usecase.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_state.dart';

class MyDebtDetailsReportCubit extends Cubit<MyDebtDetailsReportState> {
  final GetMyDebtItemPaymentsUseCase getMyDebtItemPaymentsUseCase;

  MyDebtDetailsReportCubit({required this.getMyDebtItemPaymentsUseCase,}) : super(MyDebtDetailsReportLoading());

  Future<void> loadTransactions(String uid, String debtId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      emit(MyDebtDetailsReportLoading());
    }
    
    final result = await getMyDebtItemPaymentsUseCase(uid, debtId);
    
    result.fold(
      (failure) => emit(MyDebtDetailsReportError(message: failure.message)),
      (transactions) => emit(MyDebtDetailsReportLoaded(transactions: transactions)),
    );
  }
}

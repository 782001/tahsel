import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../operation/domain/entities/operation_entity.dart';
import '../../domain/usecases/get_income_details_usecase.dart';

part 'income_details_state.dart';

class IncomeDetailsCubit extends Cubit<IncomeDetailsState> {
  final GetIncomeDetailsUseCase getIncomeDetailsUseCase;

  IncomeDetailsCubit({required this.getIncomeDetailsUseCase}) : super(IncomeDetailsInitial());

  Future<void> fetchIncomeDetails(DateTime startDate, DateTime endDate, {String? type}) async {
    emit(IncomeDetailsLoading());

    final result = await getIncomeDetailsUseCase(startDate, endDate, type: type);

    result.fold(
      (failure) => emit(IncomeDetailsError(message: failure)),
      (operations) => emit(IncomeDetailsLoaded(operations: operations)),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../operation/domain/entities/operation_entity.dart';
import '../../../domain/usecases/get_income_details_usecase.dart';

part 'income_details_state.dart';

class IncomeDetailsCubit extends Cubit<IncomeDetailsState> {
  final GetIncomeDetailsUseCase getIncomeDetailsUseCase;

  IncomeDetailsCubit({required this.getIncomeDetailsUseCase})
    : super(IncomeDetailsInitial());

  Future<void> fetchIncomeDetails(
    DateTime startDate,
    DateTime endDate, {
    String? type,
    bool isRefresh = false,
  }) async {
    // If not refreshing and we already have data, don't fetch again (Caching)
    if (!isRefresh && state is IncomeDetailsLoaded) {
      return;
    }

    emit(IncomeDetailsLoading());

    final result = await getIncomeDetailsUseCase(
      GetIncomeDetailsParams(
        startDate: startDate,
        endDate: endDate,
        type: type,
        limit: 15,
      ),
    );

    result.fold(
      (failure) => emit(IncomeDetailsError(message: failure.message)),
      (data) {
        final operations = data.$1;
        final lastDoc = data.$2;
        emit(
          IncomeDetailsLoaded(
            operations: operations,
            hasReachedMax: operations.length < 15,
            lastDoc: lastDoc,
          ),
        );
      },
    );
  }

  Future<void> loadMoreIncomeDetails(
    DateTime startDate,
    DateTime endDate, {
    String? type,
  }) async {
    final currentState = state;
    if (currentState is! IncomeDetailsLoaded || currentState.hasReachedMax) {
      return;
    }

    final result = await getIncomeDetailsUseCase(
      GetIncomeDetailsParams(
        startDate: startDate,
        endDate: endDate,
        type: type,
        limit: 15,
        lastDoc: currentState.lastDoc,
      ),
    );

    result.fold(
      (failure) => emit(IncomeDetailsError(message: failure.message)),
      (data) {
        final newOperations = data.$1;
        final lastDoc = data.$2;

        if (newOperations.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(
            currentState.copyWith(
              operations: List.of(currentState.operations)
                ..addAll(newOperations),
              hasReachedMax: newOperations.length < 15,
              lastDoc: lastDoc,
            ),
          );
        }
      },
    );
  }
}

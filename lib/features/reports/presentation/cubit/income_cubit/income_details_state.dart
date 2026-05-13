part of 'income_details_cubit.dart';

abstract class IncomeDetailsState extends Equatable {
  const IncomeDetailsState();

  @override
  List<Object?> get props => [];
}

class IncomeDetailsInitial extends IncomeDetailsState {}

class IncomeDetailsLoading extends IncomeDetailsState {}

class IncomeDetailsLoaded extends IncomeDetailsState {
  final List<OperationEntity> operations;
  final bool hasReachedMax;
  final DocumentSnapshot? lastDoc;

  const IncomeDetailsLoaded({
    required this.operations,
    this.hasReachedMax = false,
    this.lastDoc,
  });

  IncomeDetailsLoaded copyWith({
    List<OperationEntity>? operations,
    bool? hasReachedMax,
    DocumentSnapshot? lastDoc,
  }) {
    return IncomeDetailsLoaded(
      operations: operations ?? this.operations,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }

  @override
  List<Object?> get props => [operations, hasReachedMax, lastDoc];
}

class IncomeDetailsError extends IncomeDetailsState {
  final String message;

  const IncomeDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

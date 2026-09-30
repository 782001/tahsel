import 'package:equatable/equatable.dart';
import '../../domain/entities/custody_entity.dart';

abstract class CustodyState extends Equatable {
  const CustodyState();

  @override
  List<Object?> get props => [];
}

class CustodyInitial extends CustodyState {}

class CustodyLoading extends CustodyState {}

class CustodyLoaded extends CustodyState {
  final List<CustodyEntity> custodies;

  const CustodyLoaded(this.custodies);

  List<CustodyEntity> get activeCustodies =>
      custodies.where((c) => c.isActive).toList();

  List<CustodyEntity> get settledCustodies =>
      custodies.where((c) => c.isSettled).toList();

  double get totalGiven =>
      activeCustodies.fold(0.0, (sum, c) => sum + c.initialAmount);

  double get totalSpent =>
      activeCustodies.fold(0.0, (sum, c) => sum + c.spentAmount);

  double get totalRemaining =>
      activeCustodies.fold(0.0, (sum, c) => sum + c.remainingAmount);

  @override
  List<Object?> get props => [custodies];
}

class CustodyActionSuccess extends CustodyState {
  final String message;

  const CustodyActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CustodyFailure extends CustodyState {
  final String message;

  const CustodyFailure(this.message);

  @override
  List<Object?> get props => [message];
}

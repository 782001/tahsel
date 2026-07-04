import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice_history_entity.dart';

abstract class InvoiceHistoryState extends Equatable {
  const InvoiceHistoryState();
  @override
  List<Object?> get props => [];
}

class InvoiceHistoryInitial extends InvoiceHistoryState {}

class InvoiceHistoryLoading extends InvoiceHistoryState {}

class InvoiceHistoryLoaded extends InvoiceHistoryState {
  final List<InvoiceHistoryEntity> entries;
  const InvoiceHistoryLoaded(this.entries);

  @override
  List<Object?> get props => [entries];
}

class InvoiceHistoryEmpty extends InvoiceHistoryState {}

class InvoiceHistoryFailure extends InvoiceHistoryState {
  final String message;
  const InvoiceHistoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';

enum MyDebtDetailsStatus { initial, loading, loaded, error }

class MyDebtDetailsState extends Equatable {
  final MyDebtDetailsStatus status;
  final List<MyDebtItemEntity> items;
  final List<MyDebtOperationEntity> operations;
  final double totalOwed;
  final double totalPaid;
  final double remainingAmount;
  final String? message;
  final double? lastPaymentAmount;
  final double? lastPaymentRemaining;
  final String? lastPaymentNote;

  const MyDebtDetailsState({
    this.status = MyDebtDetailsStatus.initial,
    this.items = const [],
    this.operations = const [],
    this.totalOwed = 0.0,
    this.totalPaid = 0.0,
    this.remainingAmount = 0.0,
    this.message,
    this.lastPaymentAmount,
    this.lastPaymentRemaining,
    this.lastPaymentNote,
  });

  MyDebtDetailsState copyWith({
    MyDebtDetailsStatus? status,
    List<MyDebtItemEntity>? items,
    List<MyDebtOperationEntity>? operations,
    double? totalOwed,
    double? totalPaid,
    double? remainingAmount,
    String? message,
    double? lastPaymentAmount,
    double? lastPaymentRemaining,
    String? lastPaymentNote,
    bool clearPayment = false,
    bool? paymentCompleted,
  }) {
    return MyDebtDetailsState(
      status: status ?? this.status,
      items: items ?? this.items,
      operations: operations ?? this.operations,
      totalOwed: totalOwed ?? this.totalOwed,
      totalPaid: totalPaid ?? this.totalPaid,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      message: message ?? this.message,
      lastPaymentAmount: clearPayment
          ? null
          : (lastPaymentAmount ?? this.lastPaymentAmount),
      lastPaymentRemaining: clearPayment
          ? null
          : (lastPaymentRemaining ?? this.lastPaymentRemaining),
      lastPaymentNote: clearPayment
          ? null
          : (lastPaymentNote ?? this.lastPaymentNote),
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    operations,
    totalOwed,
    totalPaid,
    remainingAmount,
    message,
    lastPaymentAmount,
    lastPaymentRemaining,
    lastPaymentNote,
  ];
}

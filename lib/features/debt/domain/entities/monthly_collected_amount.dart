import 'package:equatable/equatable.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';

class MonthlyCollectedAmount extends Equatable {
  final int month;
  final int year;
  final double totalAmount;
  final List<PaymentEntity> payments;

  const MonthlyCollectedAmount({
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.payments,
  });

  @override
  List<Object?> get props => [month, year, totalAmount, payments];
}

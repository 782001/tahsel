import 'package:equatable/equatable.dart';

enum ProfitInsightStatus { increase, loss, same, none }

class ProfitInsight extends Equatable {
  final String messageKey;
  final double currentValue;
  final double previousValue;
  final double difference;
  final double
  netProfit; // Keep for backward compatibility if needed, but netProfit is usually currentValue
  final ProfitInsightStatus status;

  const ProfitInsight({
    required this.messageKey,
    required this.currentValue,
    required this.previousValue,
    required this.difference,
    required this.netProfit,
    required this.status,
  });

  @override
  List<Object?> get props => [
    messageKey,
    currentValue,
    previousValue,
    difference,
    netProfit,
    status,
  ];
}

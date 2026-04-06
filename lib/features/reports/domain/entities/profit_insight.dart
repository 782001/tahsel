import 'package:equatable/equatable.dart';

enum ProfitInsightStatus { increase, loss, same, none }

class ProfitInsight extends Equatable {
  final String messageKey;
  final double difference;
  final double netProfit;
  final ProfitInsightStatus status;

  const ProfitInsight({
    required this.messageKey,
    required this.difference,
    required this.netProfit,
    required this.status,
  });

  @override
  List<Object?> get props => [messageKey, difference, netProfit, status];
}

import 'package:equatable/equatable.dart';

class OperationEntity extends Equatable {
  final String? id;
  final String uid;
  final String type; // 'shop' or 'playStation'
  final String? subType; // 'time' or 'turn'
  final String? customerName;
  final String? productName;
  final double totalAmount;
  final double paidAmount;
  final double remainingDebt;
  final DateTime? timestamp;
  final int? durationMinutes;
  final int? turnCount;
  final double? rate;

  const OperationEntity({
    this.id,
    required this.uid,
    required this.type,
    this.subType,
    this.customerName,
    this.productName,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingDebt,
    this.timestamp,
    this.durationMinutes,
    this.turnCount,
    this.rate,
  });

  @override
  List<Object?> get props => [
        id,
        uid,
        type,
        subType,
        customerName,
        productName,
        totalAmount,
        paidAmount,
        remainingDebt,
        timestamp,
        durationMinutes,
        turnCount,
        rate,
      ];
}

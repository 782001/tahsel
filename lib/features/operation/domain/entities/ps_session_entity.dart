import 'package:equatable/equatable.dart';

/// Represents the lifecycle status of a PlayStation session.
enum PsSessionStatus { active, completed }

/// Domain entity for a PlayStation session.
///
/// A session is created when the operator presses "Start Session" and
/// completed when they press "End Session". Duration and billing are
/// calculated automatically from [startTime] and [endTime].
class PsSessionEntity extends Equatable {
  final String? id;
  final String uid;
  final String? customerName;
  final String? phoneNumber;
  final String? deviceId; // e.g. "PS5-01"
  final String? roomId; // e.g. "Room A"
  final String? operatorName;
  final String subType; // 'time' or 'turn'
  final double rate; // hourly rate (time) or per-turn rate (turn)
  final DateTime startTime;
  final DateTime? endTime;
  final PsSessionStatus status;
  final double totalAmount;
  final double paidAmount;
  final double remainingDebt;
  final int? turnCount; // only for 'turn' sub-type
  final String? ledgerNumber;
  final DateTime createdAt;

  const PsSessionEntity({
    this.id,
    required this.uid,
    this.customerName,
    this.phoneNumber,
    this.deviceId,
    this.roomId,
    this.operatorName,
    required this.subType,
    required this.rate,
    required this.startTime,
    this.endTime,
    this.status = PsSessionStatus.active,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.remainingDebt = 0.0,
    this.turnCount,
    this.ledgerNumber,
    required this.createdAt,
  });

  /// Elapsed duration since the session started (live or final).
  Duration get elapsed {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Elapsed duration in whole minutes.
  int get elapsedMinutes => elapsed.inMinutes;

  /// Calculates the current price based on elapsed time and hourly rate.
  /// For 'turn' sub-type, uses turnCount * rate instead.
  double get calculatedAmount {
    if (subType == 'turn') {
      return (turnCount ?? 0) * rate;
    }
    // time-based: (rate / 60) * elapsedMinutes
    return (rate / 60.0) * elapsedMinutes;
  }

  /// Whether this session is currently running.
  bool get isActive => status == PsSessionStatus.active;

  PsSessionEntity copyWith({
    String? id,
    String? uid,
    String? customerName,
    String? phoneNumber,
    String? deviceId,
    String? roomId,
    String? operatorName,
    String? subType,
    double? rate,
    DateTime? startTime,
    DateTime? endTime,
    PsSessionStatus? status,
    double? totalAmount,
    double? paidAmount,
    double? remainingDebt,
    int? turnCount,
    String? ledgerNumber,
    DateTime? createdAt,
  }) {
    return PsSessionEntity(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      deviceId: deviceId ?? this.deviceId,
      roomId: roomId ?? this.roomId,
      operatorName: operatorName ?? this.operatorName,
      subType: subType ?? this.subType,
      rate: rate ?? this.rate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingDebt: remainingDebt ?? this.remainingDebt,
      turnCount: turnCount ?? this.turnCount,
      ledgerNumber: ledgerNumber ?? this.ledgerNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    uid,
    customerName,
    phoneNumber,
    deviceId,
    roomId,
    operatorName,
    subType,
    rate,
    startTime,
    endTime,
    status,
    totalAmount,
    paidAmount,
    remainingDebt,
    turnCount,
    ledgerNumber,
    createdAt,
  ];
}

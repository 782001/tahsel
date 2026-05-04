import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/monthly_collected_amount.dart';
import '../entities/payment_entity.dart';
import '../repositories/debt_repository.dart';

class GetMonthlyCollectedAmountsUseCase implements BaseUseCase<List<MonthlyCollectedAmount>, String> {
  final DebtRepository repository;

  GetMonthlyCollectedAmountsUseCase(this.repository);

  @override
  Future<Either<Failure, List<MonthlyCollectedAmount>>> call(String uid) async {
    final result = await repository.getAllUserPayments(uid);
    
    return result.fold(
      (failure) => Left(failure),
      (payments) async {
        if (payments.isEmpty) return const Right([]);
        
        // Use compute to offload heavy grouping and summation to an Isolate
        // This ensures the UI thread remains responsive even with large transaction lists
        final monthlyAmounts = await compute(_processPayments, payments);
        return Right(monthlyAmounts);
      },
    );
  }
}

/// Top-level function for Isolate processing
List<MonthlyCollectedAmount> _processPayments(List<PaymentEntity> payments) {
  // 1. Filter only actual collection transactions
  // We exclude debt creation (debtAdded) and adjustments to focus on money collected
  final validPayments = payments.where((p) => 
    p.type == PaymentType.full || 
    p.type == PaymentType.partial || 
    p.type == PaymentType.settlement
  ).toList();

  // 2. Group by Month and Year
  final Map<String, List<PaymentEntity>> grouping = {};
  for (var p in validPayments) {
    if (p.createdAt == null) continue;
    
    // Key format: "YYYY-MM"
    final key = "${p.createdAt!.year}-${p.createdAt!.month}";
    if (!grouping.containsKey(key)) {
      grouping[key] = [];
    }
    grouping[key]!.add(p);
  }

  // 3. Map to result entities
  final List<MonthlyCollectedAmount> result = grouping.entries.map((e) {
    final parts = e.key.split("-");
    final monthPayments = e.value;
    final total = monthPayments.fold(0.0, (sum, p) => sum + p.amountPaid);
    
    return MonthlyCollectedAmount(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      totalAmount: total,
      payments: monthPayments,
    );
  }).toList();

  // 4. Sort by date descending (latest month first)
  result.sort((a, b) {
    if (a.year != b.year) return b.year.compareTo(a.year);
    return b.month.compareTo(a.month);
  });

  return result;
}

import 'package:dartz/dartz.dart';
import '../entities/debt_entity.dart';
import '../entities/payment_entity.dart';

abstract class DebtRepository {
  Future<Either<dynamic, String>> addDebt(DebtEntity debt);
  Future<Either<dynamic, List<DebtEntity>>> getDebts(String uid);
  Future<Either<dynamic, void>> payDebt(DebtEntity debt, PaymentEntity payment);
  Future<Either<dynamic, void>> payTotalDebt(String uid, String customerName, double amount);
  Future<Either<dynamic, void>> markCustomerAsPaid(String uid, String customerName);
}

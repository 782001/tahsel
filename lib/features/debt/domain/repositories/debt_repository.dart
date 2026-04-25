import 'package:dartz/dartz.dart';
import '../entities/debt_entity.dart';
import '../entities/payment_entity.dart';
import '../../../../core/error/failures.dart';

abstract class DebtRepository {
  Future<Either<Failure, String>> addDebt(DebtEntity debt);
  Future<Either<Failure, List<DebtEntity>>> getDebts(String uid);
  Future<Either<Failure, void>> payDebt(DebtEntity debt, PaymentEntity payment);
  Future<Either<Failure, void>> payTotalDebt(String uid, String customerName, double amount);
  Future<Either<Failure, void>> markCustomerAsPaid(String uid, String customerName);
  Future<Either<Failure, void>> deleteCustomerDebts(String uid, String customerName);
  Stream<List<PaymentEntity>> getDebtTransactions(String debtId);
  Future<Either<Failure, List<PaymentEntity>>> getCustomerAllPayments(String uid, String customerName);
}

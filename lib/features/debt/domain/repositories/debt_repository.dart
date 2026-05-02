import 'package:dartz/dartz.dart';
import '../entities/debt_entity.dart';
import '../entities/payment_entity.dart';
import '../../../../core/error/failures.dart';

abstract class DebtRepository {
  Future<Either<Failure, String>> addDebt(DebtEntity debt);
  Future<Either<Failure, List<DebtEntity>>> getDebts(
    String uid, {
    bool forceRefresh = false,
  });
  Future<Either<Failure, void>> payDebt(DebtEntity debt, PaymentEntity payment);
  Future<Either<Failure, void>> payTotalDebt(
    String uid,
    String customerName,
    double amount,
  );
  Future<Either<Failure, void>> markCustomerAsPaid(
    String uid,
    String customerName,
  );
  Future<Either<Failure, void>> deleteCustomerDebts(
    String uid,
    String customerName,
  );
  Future<Either<Failure, void>> deleteDebtItem(String uid, String debtId);
  Future<Either<Failure, void>> updatePayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required double newAmount,
    String? note,
  });
  Future<Either<Failure, void>> deletePayment({
    required String uid,
    required String debtId,
    required String paymentId,
  });
  Stream<List<PaymentEntity>> getDebtTransactions(String debtId);
  Future<Either<Failure, List<PaymentEntity>>> getDebtTransactionsFuture(
    String debtId, {
    bool forceRefresh = false,
  });
  Future<Either<Failure, List<PaymentEntity>>> getCustomerAllPayments(
    String uid,
    String customerName,
  );
  Stream<List<DebtEntity>> getDebtsStream(String uid);
  Future<Either<Failure, DebtEntity?>> getDebtById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });
}

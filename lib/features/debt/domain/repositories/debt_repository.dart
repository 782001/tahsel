import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/usecases/pagination_params.dart';
import '../entities/debt_entity.dart';
import '../entities/payment_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/monthly_collected_amount.dart';

abstract class DebtRepository {
  Future<Either<Failure, String>> addDebt(DebtEntity debt);
  Future<Either<Failure, List<DebtEntity>>> getDebts(
    String uid, {
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<DebtEntity>>> getCustomerDebts(
    String uid,
    String customerName, {
    bool forceRefresh = false,
  });

  Future<Either<Failure, PaginatedResult<DebtEntity>>> getDebtsPaginated(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  });

  Future<Either<Failure, void>> payDebt(DebtEntity debt, PaymentEntity payment);
  Future<Either<Failure, void>> payTotalDebt(
    String uid,
    String customerName,
    double amount, {
    DateTime? paymentDate,
  });
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
  Stream<List<PaymentEntity>> getDebtTransactions(String uid, String debtId);
  Future<Either<Failure, List<PaymentEntity>>> getDebtTransactionsFuture(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });

  Future<Either<Failure, PaginatedResult<PaymentEntity>>>
  getDebtTransactionsPaginated(
    String uid,
    String debtId, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
  });

  Future<Either<Failure, List<PaymentEntity>>> getCustomerAllPayments(
    String uid,
    String customerName,
  );

  Future<Either<Failure, PaginatedResult<PaymentEntity>>>
  getCustomerAllPaymentsPaginated(
    String uid,
    String customerName, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
  });

  Future<Either<Failure, List<PaymentEntity>>> getAllUserPayments(String uid);
  Future<Either<Failure, List<MonthlyCollectedAmount>>>
  getMonthlyCollectedAmounts(String uid);

  Future<Either<Failure, PaginatedResult<PaymentEntity>>>
  getAllUserPaymentsPaginated(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDocument,
    int? month,
    int? year,
  });

  Stream<List<DebtEntity>> getDebtsStream(String uid);
  Future<Either<Failure, DebtEntity?>> getDebtById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });

  Future<Either<Failure, TotalDebtsResult>> getDebtSummary(String uid);
}

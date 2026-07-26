import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_summary_entity.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';

abstract class MyDebtRepository {
  // Summary (aggregate query - 1 read cost)
  Future<Either<Failure, MyDebtSummaryEntity>> getMyDebtSummary(String uid);

  // Person (Supplier/etc)
  Future<Either<Failure, List<MyDebtPersonEntity>>> getMyDebtPersons(
    String uid, {
    bool forceRefresh = false,
  });
  Future<Either<Failure, PaginatedResult<MyDebtPersonEntity>>>
  getMyDebtPersonsPaginated(
    String uid, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  });
  Future<Either<Failure, void>> saveMyDebtPerson(
    String uid,
    MyDebtPersonEntity person,
  );
  Future<Either<Failure, void>> updateMyDebtPersonPhone(
    String uid,
    String name,
    String phoneNumber,
  );
  Future<Either<Failure, void>> updateMyDebtPersonPreference(
    String uid,
    String name,
    String preference,
  );

  // Debt Items
  Future<Either<Failure, String>> addMyDebtItem(MyDebtItemEntity debt);
  Future<Either<Failure, List<MyDebtItemEntity>>> getMyDebtItems(
    String uid,
    String personName, {
    bool forceRefresh = false,
  });
  Future<Either<Failure, void>> deleteMyDebtItem(String uid, String debtId);
  Future<Either<Failure, void>> markMyDebtItemAsPaid(String uid, String debtId);

  // Payments
  Future<Either<Failure, void>> payMyDebtItem({
    required String uid,
    required String debtId,
    required double amount,
    String? note,
    DateTime? paymentDate,
  });
  Future<Either<Failure, void>> settleSupplierCredit({
    required String uid,
    required String debtId,
    required double creditAmount,
    String? note,
  });
  Future<Either<Failure, List<PaymentEntity>>> getMyDebtItemPayments(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });
  Future<Either<Failure, PaginatedResult<PaymentEntity>>>
  getMyDebtItemPaymentsPaginated(
    String uid,
    String debtId, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  });
  Future<Either<Failure, void>> distributeMyDebtPayment({
    required String uid,
    required String personName,
    required double amount,
    String? note,
    DateTime? paymentDate,
  });
  Future<Either<Failure, void>> updateMyDebtPayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required double newAmount,
    String? note,
  });
  Future<Either<Failure, void>> deleteMyDebtPayment({
    required String uid,
    required String debtId,
    required String paymentId,
  });

  // Reports
  Future<Either<Failure, List<MyDebtOperationEntity>>>
  getMyDebtPersonOperations(
    String uid,
    String personName, {
    bool forceRefresh = false,
  });

  // Offline Sync
  Future<Either<Failure, List<OfflineRecord>>> getPendingMyDebts();

  Future<Either<Failure, MyDebtItemEntity?>> getMyDebtItemById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });
}
